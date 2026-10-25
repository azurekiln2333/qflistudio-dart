"""Lightweight fixture tests for inspect_dart_hap.py.

Every fixture is an in-memory HAP zip and a tiny fake product tree, so these run
without Flutter, DevEco, the SDK, a device or the real 39 MB artifact.

Run: python tool/ohos/test_inspect_dart_hap.py
"""
import importlib.util
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("inspect_dart_hap", HERE / "inspect_dart_hap.py")
inspect_module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(inspect_module)
inspect_hap = inspect_module.inspect_hap


def elf_header(machine: int) -> bytes:
    return (b"\x7fELF\x02\x01\x01\x00" + b"\x00" * 8
            + struct.pack("<H", 3) + struct.pack("<H", machine) + b"\x00" * 44)


def content_asset(kind: str, count: int, language: str = "dart") -> bytes:
    entries = []
    for index in range(count):
        entry = {
            "id": f"{kind.rstrip('s')}-{index:03d}",
            "language": language,
            "type": language,
            "level": "beginner",
        }
        if kind == "tutorials":
            entry["lessons"] = [{"id": f"{entry['id']}-lesson", "title": "t"}]
        else:
            entry["code"] = "void main() {}\n"
        entries.append(entry)
    document = {"schemaVersion": 1, "kind": kind, "updatedAt": "2026-10-22", "entries": entries}
    return json.dumps(document, ensure_ascii=False, indent=2).encode("utf-8")


class InspectorFixture(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="qfli_inspect_fixture_")
        cls.project = Path(cls.temp.name) / "product"
        (cls.project / "ohos/AppScope").mkdir(parents=True)
        (cls.project / "ohos/entry/src/main").mkdir(parents=True)
        (cls.project / "assets/content").mkdir(parents=True)
        (cls.project / "ohos/AppScope/app.json5").write_text(
            "{\n  'app': {\n    'bundleName': 'com.azurekiln.qfli.dart',\n"
            "    'vendor': 'QFLI',\n    'versionCode': 1000000,\n  },\n}\n", encoding="utf-8")
        (cls.project / "ohos/entry/src/main/module.json5").write_text(
            "{\n  'module': {\n    'name': 'entry',\n    'mainElement': 'EntryAbility',\n"
            "    'deviceTypes': ['phone', '2in1', 'tablet'],\n"
            "    'requestPermissions': [\n      {\n"
            "        'name': 'ohos.permission.READ_PASTEBOARD',\n      },\n    ],\n  },\n}\n",
            encoding="utf-8")
        (cls.project / "pubspec.yaml").write_text(
            "name: qfli_dart\nversion: 1.0.0+1\n", encoding="utf-8")
        cls.tutorials = content_asset("tutorials", 3)
        cls.examples = content_asset("examples", 3)
        (cls.project / "assets/content/dart_tutorials.json").write_bytes(cls.tutorials)
        (cls.project / "assets/content/dart_examples.json").write_bytes(cls.examples)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def make_hap(self, *, abi="x86_64", machine=62, libs=None, app=None, module=None,
                 tutorials=None, examples=None, extra_names=None) -> Path:
        base_app = {
            "bundleName": "com.azurekiln.qfli.dart", "versionName": "1.0.0", "versionCode": 1,
            "vendor": "QFLI", "debug": False, "buildMode": "release",
        }
        base_module = {
            "name": "entry", "mainElement": "EntryAbility",
            "deviceTypes": ["phone", "2in1", "tablet"],
            "requestPermissions": [{"name": "ohos.permission.READ_PASTEBOARD"}],
        }
        base_module.update(module or {})
        base_app.update(app or {})
        native = libs if libs is not None else {
            f"libs/{abi}/libapp.so": elf_header(machine),
            f"libs/{abi}/libflutter.so": elf_header(machine),
        }
        handle = tempfile.NamedTemporaryFile(suffix=".hap", delete=False)
        handle.close()
        path = Path(handle.name)
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("module.json", json.dumps({"app": base_app, "module": base_module}))
            archive.writestr("pack.info", json.dumps({"summary": {"app": {
                "bundleName": base_app["bundleName"],
                "version": {"code": base_app["versionCode"], "name": base_app["versionName"]},
            }}}))
            for name, payload in native.items():
                archive.writestr(name, payload)
            archive.writestr(
                "resources/rawfile/flutter_assets/assets/content/dart_tutorials.json",
                self.tutorials if tutorials is None else tutorials)
            archive.writestr(
                "resources/rawfile/flutter_assets/assets/content/dart_examples.json",
                self.examples if examples is None else examples)
            if extra_names:
                for name, payload in extra_names.items():
                    archive.writestr(name, payload)
        self.addCleanup(path.unlink, missing_ok=True)
        return path

    def inspect(self, hap, **kwargs):
        options = {"abi": "x86_64", "topics": 3, "require_release": True}
        options.update(kwargs)
        return inspect_hap(hap, self.project, options.pop("abi"), **options)

    # --- positive ---------------------------------------------------------
    def test_valid_x86_64_audit_hap_passes(self):
        result = self.inspect(self.make_hap())
        self.assertTrue(result["ok"], result["failures"])
        self.assertEqual(result["sha256"], result["sha256AfterInspection"])
        self.assertTrue(result["immutableVerified"])
        self.assertTrue(result["releaseModeVerified"])
        self.assertEqual([entry["topics"] for entry in result["assets"]], [3, 3])
        self.assertFalse(result["signatureVerified"])
        self.assertFalse(result["deviceVerified"])

    def test_valid_arm64_hap_passes(self):
        result = self.inspect(self.make_hap(abi="arm64-v8a", machine=183), abi="arm64-v8a")
        self.assertTrue(result["ok"], result["failures"])

    # --- ABI / ELF --------------------------------------------------------
    def test_wrong_elf_machine_fails(self):
        hap = self.make_hap(libs={"libs/x86_64/libapp.so": elf_header(183),
                                  "libs/x86_64/libflutter.so": elf_header(62)})
        result = self.inspect(hap)
        self.assertFalse(result["ok"])
        self.assertTrue(any("Wrong ELF architecture" in f for f in result["failures"]))

    def test_cross_abi_payload_fails(self):
        hap = self.make_hap(extra_names={"libs/arm64-v8a/libextra.so": elf_header(183)})
        result = self.inspect(hap)
        self.assertFalse(result["ok"])
        self.assertTrue(any("Unexpected ABI payload" in f for f in result["failures"]))
        self.assertTrue(any("multiple ABIs" in f for f in result["failures"]))

    def test_missing_application_library_fails(self):
        hap = self.make_hap(libs={"libs/x86_64/libflutter.so": elf_header(62)})
        result = self.inspect(hap)
        self.assertFalse(result["ok"])
        self.assertTrue(any("Missing required native library" in f for f in result["failures"]))

    def test_native_library_outside_libs_fails(self):
        hap = self.make_hap(extra_names={"resources/librogue.so": elf_header(62)})
        result = self.inspect(hap)
        self.assertFalse(result["ok"])
        self.assertTrue(any("outside libs/" in f for f in result["failures"]))

    def test_non_elf_payload_fails(self):
        hap = self.make_hap(libs={"libs/x86_64/libapp.so": b"not an elf",
                                  "libs/x86_64/libflutter.so": elf_header(62)})
        result = self.inspect(hap)
        self.assertFalse(result["ok"])
        self.assertTrue(any("Not an ELF" in f for f in result["failures"]))

    # --- identity ---------------------------------------------------------
    def test_bundle_mismatch_fails(self):
        result = self.inspect(self.make_hap(app={"bundleName": "com.example.other"}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("differs from" in f and "bundle" in f.lower() for f in result["failures"]))

    def test_version_name_mismatch_fails(self):
        result = self.inspect(self.make_hap(app={"versionName": "9.9.9"}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("versionName" in f for f in result["failures"]))

    def test_version_code_mismatch_fails(self):
        result = self.inspect(self.make_hap(app={"versionCode": 42}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("versionCode" in f for f in result["failures"]))

    def test_vendor_mismatch_fails(self):
        result = self.inspect(self.make_hap(app={"vendor": "Someone"}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("vendor" in f for f in result["failures"]))

    def test_debug_build_fails_release_gate(self):
        result = self.inspect(self.make_hap(app={"debug": True}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("app.debug" in f for f in result["failures"]))

    def test_profile_build_mode_fails_release_gate(self):
        result = self.inspect(self.make_hap(app={"buildMode": "debug"}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("buildMode" in f for f in result["failures"]))

    def test_debug_build_allowed_when_release_not_required(self):
        result = self.inspect(self.make_hap(app={"debug": True, "buildMode": "debug"}),
                              require_release=False)
        self.assertTrue(result["ok"], result["failures"])
        self.assertFalse(result["releaseModeVerified"])

    def test_module_identity_mismatch_fails(self):
        result = self.inspect(self.make_hap(module={"mainElement": "OtherAbility"}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("mainElement" in f for f in result["failures"]))

    def test_device_type_mismatch_fails(self):
        result = self.inspect(self.make_hap(module={"deviceTypes": ["phone"]}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("deviceTypes" in f for f in result["failures"]))

    # --- permissions ------------------------------------------------------
    def test_internet_permission_fails(self):
        result = self.inspect(self.make_hap(module={"requestPermissions": [
            {"name": "ohos.permission.READ_PASTEBOARD"},
            {"name": "ohos.permission.INTERNET"},
        ]}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("network or sensitive" in f for f in result["failures"]))

    def test_unexpected_sensitive_permission_fails(self):
        result = self.inspect(self.make_hap(module={"requestPermissions": [
            {"name": "ohos.permission.READ_PASTEBOARD"},
            {"name": "ohos.permission.CAMERA"},
        ]}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("network or sensitive" in f for f in result["failures"]))

    def test_missing_declared_permission_fails(self):
        result = self.inspect(self.make_hap(module={"requestPermissions": []}))
        self.assertFalse(result["ok"])
        self.assertTrue(any("differ from declared" in f for f in result["failures"]))

    # --- assets / denominator --------------------------------------------
    def test_tampered_asset_bytes_fail(self):
        tampered = self.tutorials.replace(b"beginner", b"advanced")
        result = self.inspect(self.make_hap(tutorials=tampered))
        self.assertFalse(result["ok"])
        self.assertTrue(any("differs from the authored" in f for f in result["failures"]))

    def test_short_packaged_denominator_fails(self):
        result = self.inspect(self.make_hap(tutorials=content_asset("tutorials", 2)))
        self.assertFalse(result["ok"])
        self.assertTrue(any("denominator" in f for f in result["failures"]))

    def test_requested_topics_mismatch_fails(self):
        result = self.inspect(self.make_hap(), topics=4)
        self.assertFalse(result["ok"])
        self.assertTrue(any("requested count" in f for f in result["failures"]))

    def test_non_dart_language_fails(self):
        result = self.inspect(self.make_hap(tutorials=content_asset("tutorials", 3, language="python")))
        self.assertFalse(result["ok"])
        self.assertTrue(any("language set" in f for f in result["failures"]))

    def test_tutorial_without_lessons_fails(self):
        broken = json.loads(self.tutorials)
        broken["entries"][1]["lessons"] = []
        result = self.inspect(self.make_hap(
            tutorials=json.dumps(broken, ensure_ascii=False).encode("utf-8")))
        self.assertFalse(result["ok"])
        self.assertTrue(any("without lessons" in f for f in result["failures"]))

    def test_duplicate_ids_fail(self):
        broken = json.loads(self.examples)
        broken["entries"][1]["id"] = broken["entries"][0]["id"]
        result = self.inspect(self.make_hap(
            examples=json.dumps(broken, ensure_ascii=False).encode("utf-8")))
        self.assertFalse(result["ok"])
        self.assertTrue(any("reuses an id" in f for f in result["failures"]))

    # --- immutability / pinning ------------------------------------------
    def test_identity_source_fingerprints_are_pinned(self):
        from hashlib import sha256
        result = self.inspect(self.make_hap())
        self.assertTrue(result["ok"], result["failures"])
        sources = result["fingerprints"]["identitySources"]
        self.assertEqual(sorted(sources), sorted(inspect_module.IDENTITY_SOURCES))
        for relative, digest in sources.items():
            expected = sha256((self.project / relative).read_bytes()).hexdigest()
            self.assertEqual(digest, expected, relative)

    def test_native_guard_is_never_claimed(self):
        result = self.inspect(self.make_hap())
        self.assertFalse(result["nativeGuardVerified"])
        self.assertFalse(result["gates"]["nativeGuardVerified"])
        self.assertTrue(any("native" in item.lower() for item in result["gates"]["pending"]))

    def test_pinned_hash_match_is_recorded(self):
        from hashlib import sha256
        hap = self.make_hap()
        digest = sha256(hap.read_bytes()).hexdigest()
        result = self.inspect(hap, expect_sha256=digest)
        self.assertTrue(result["ok"], result["failures"])
        self.assertEqual(result["expectedSha256"], digest)

    def test_pinned_hash_mismatch_fails(self):
        result = self.inspect(self.make_hap(), expect_sha256="00" * 32)
        self.assertFalse(result["ok"])
        self.assertTrue(any("pinned value" in f for f in result["failures"]))

    # --- failure still writes evidence -----------------------------------
    def test_main_writes_report_on_failure(self):
        import io
        from contextlib import redirect_stderr, redirect_stdout
        hap = self.make_hap(app={"debug": True})
        report = Path(tempfile.NamedTemporaryFile(suffix=".json", delete=False).name)
        self.addCleanup(report.unlink, missing_ok=True)
        argv = sys.argv
        try:
            sys.argv = ["inspect_dart_hap.py", str(hap), "--abi", "x86_64",
                        "--project", str(self.project), "--report", str(report)]
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                code = inspect_module.main()
        finally:
            sys.argv = argv
        self.assertEqual(code, 1)
        self.assertTrue(report.is_file())
        result = json.loads(report.read_text(encoding="utf-8"))
        self.assertFalse(result["ok"])
        self.assertFalse(result["releaseModeVerified"])
        self.assertFalse(result["gates"]["releaseModeVerified"])


    def test_corrupt_archive_still_writes_failure_report(self):
        import io
        from contextlib import redirect_stderr, redirect_stdout
        hap = self.make_hap()
        hap.write_bytes(b"not a ZIP archive")
        report = hap.with_suffix(".report.json")
        self.addCleanup(report.unlink, missing_ok=True)
        argv = sys.argv
        try:
            sys.argv = ["inspect_dart_hap.py", str(hap), "--abi", "x86_64",
                        "--project", str(self.project), "--report", str(report)]
            with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
                code = inspect_module.main()
        finally:
            sys.argv = argv
        self.assertEqual(code, 1)
        result = json.loads(report.read_text(encoding="utf-8"))
        self.assertFalse(result["ok"])
        self.assertFalse(result["releaseModeVerified"])
        self.assertFalse(result["nativeGuardVerified"])
        self.assertTrue(any("BadZipFile" in item for item in result["failures"]))


if __name__ == "__main__":
    unittest.main(verbosity=2)