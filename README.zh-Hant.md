# qfli_dart

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

本倉庫是一個獨立的 Flutter 應用。
產品名是 QFLIDartWing。
它把 Dart 編輯器、工具頁、終端和課程裝進一個應用。
應用離線工作。
它不打開外部網頁。
Android 主清單不申請聯網權限。
除錯清單和效能清單申請聯網權限。
OHOS 清單只申請讀取剪貼板權限。
編輯器、終端和文件樹來自同級包 qfli_studio_core。

## 運行後端

Android 和桌面用官方 Dart SDK。
Android 打包官方 SDK 的 arm64-v8a 與 x86_64 版本。
OHOS 的 HAP 不帶官方 SDK。
OHOS 用內置的便攜解釋器。
便攜解釋器是 vendor/tom_d4rt。
版本是 1.229.0+qfli.1。
它保留上游 MIT 許可證。
dart_eval 0.8.5 只保留給舊的 EVC 編譯動作。
便攜解釋器不是完整的 Dart VM。
它支持一部分語言和庫。
它拒絕聯網、原生進程、標準輸入和符號鏈接遍歷。
它只讀預加載的項目源碼。
它允許項目和臨時目錄的文件讀寫。

## 課程內容

已發布資產含 120 課和 120 個配對示例。
課程分 14 章，編號 001 到 120。
每課有講解、目標、代碼、輸出和練習。
另有 180 組草稿，編號 121 到 300。
草稿放在 16 個章節文件裡。
草稿尚未進入發布資產。
發布聚合與資產保持 120/120。
原有 OHOS 驗收是草稿提升的必經門檻。
草稿只在主機上驗證過。
主機驗證含官方 SDK 運行和便攜運行。
編號 181 到 238 的 58 項練習已在主機複跑。
官方 SDK 和便攜運行均通過。
草稿沒有 OHOS 裝置證據。

## 證據邊界

主機 SDK 運行、主機便攜運行、OHOS 打包和真機運行是四道獨立門檻。
主機測試通過，不代表裝置運行通過。
Windows AOT 結果只證明主機。
它不證明 OHOS。
目前沒有 Dart 的 OHOS 裝置驗收。
共享 x64 模擬器已存在。
Dart 尚未獲得 OHOS 裝置時段。
Dart 未安裝 OHOS 應用。
Dart 未啟動 OHOS 應用。
Dart 未停止 OHOS 應用。
Android 原生 SDK 在 API 37 x86_64 模擬器上通過九項驗證。
該驗證使用 16 KiB 頁。
ARM64 應用運行仍需真機。
發布 HAP 和 APP 時指定 arm64-v8a。
另有一份 x86_64 審計 HAP。
它由 `tool/ohos/build_dart_audit.ps1` 生成。
它只供主機打包檢查。
它不是發布包。
它不算裝置證據。
原生離線守衛只在主機通道測試中驗證。
現有審計包早於原生離線守衛。
沒有 HDC 目標時，裝置證據為空。

## 支持範圍與限制

工具頁提供格式化、語法診斷、運行、編譯和源碼結構。
格式化用 dart_style。
工具頁和終端 `dart analyze` 都只做語法診斷。
語法診斷只做掃描與解析。
它不做類型、lint 或依賴分析。
乾淨結果不代表類型正確。
缺少輸入時它返回不可用原因。
它不返回虛假的乾淨結果。
OHOS 便攜目標沒有官方 SDK。
終端 `dart compile kernel` 返回不可用原因。
編譯在 Android 和桌面產出 Kernel `.dill`。
舊的 EVC 動作產出 dart_eval 字節碼。
終端支持 dart run、format、analyze 和 compile kernel。
終端拒絕 pub get 和全局安裝。
應用沒有斷點調試。
它沒有單步和變量查看 API。
打印日誌不等於斷點調試。
應用不支持聯網和端口功能。
不支持的能力會明確失敗。

## 同級倉庫與依賴

本倉庫依賴同級包 qfli_studio_core。
先把它檢出到本倉庫旁邊。

```text
checkout-parent/
  qfli_studio_core/
  qfli_dart/
```

然後在本倉庫運行 flutter pub get。
編輯器補丁來自 ../qfli_studio_core/vendor/re_editor。
pubspec.yaml 用路徑覆蓋指向它。

## 開發與測試

生成內容資產。

```powershell
dart run tool/build_dart_content.dart
```

用官方 SDK 驗證全部課程。

```powershell
dart run tool/verify_dart_content.dart
```

驗證引擎說明是否齊全。

```powershell
dart run tool/audit_compat.dart
```

用便攜解釋器驗證全部課程。

```powershell
dart run tool/verify_portable_content.dart --report portable-report.json
```

跑靜態分析和測試。

```powershell
flutter analyze --no-pub
flutter test --no-pub
```

跑原生離線通道測試。
它覆蓋離線拒絕和本地能力兩組。

```powershell
node --max-old-space-size=128 --test test/native_entry_ability_test.cjs
```

自查中文文檔。

```powershell
python scripts/ste-lint-zh.py README.md README.zh-Hant.md
```

## 構建

雲端構建和下載見 [GitHub 構建說明](GITHUB_BUILD.zh-CN.md)。

Android 構建前先鋪 SDK。
替換兩個 SDK 目錄。

```powershell
./native/dart-sdk/android/stage.ps1 -Abi arm64-v8a -Sdk '<SDK_ARM64_DIR>'
./native/dart-sdk/android/stage.ps1 -Abi x86_64 -Sdk '<SDK_X64_DIR>'
```

構建 arm64 APK。

```powershell
flutter build apk --release --target-platform android-arm64 --no-pub
```

Android release 目前用調試密鑰簽名。
發布前請配置商店簽名密鑰。

構建 OHOS HAP。

```powershell
flutter build hap --release --target-platform ohos-arm64 --no-pub
```

構建 OHOS APP。

```powershell
flutter build app --release --target-platform ohos-arm64 --no-pub
```

簽名 HAP 在 `build/ohos/hap/entry-default-signed.hap`。
簽名 APP 在 `build/ohos/app/ohos-default-signed.app`。
沒有簽名材料時加 `--no-codesign`。

## 簽名與隱私

私鑰、證書和口令只留在本機。
不要把它們提交到倉庫。
在本機設定 OHOS 發布簽名。
將本機發布簽名設定命名為 `releaseKey`。
從 `ohos/AppScope/app.json5` 讀取 bundle 名。
簽名設定必須授權該 bundle。
證書必須與簽名者一致。
打包、簽名和真機運行分開驗收。
文件名帶 signed 不代表商店簽名。
用 hap-sign-tool 驗證簽名和 profile。

```powershell
tool/ohos/verify_dart_hap.ps1 -HapPath <hap>
```

## 待辦證據

GitHub 已生成未簽名 OHOS HAP 和 APP。
這兩類產物已通過包結構檢查。
OHOS 發布簽名與真機驗收仍待完成。
180 組草稿的提升仍開放。
全量 300 組內容驗證仍開放。
共享核心的最終修訂仍待評審。

## 許可證

本倉庫程式碼採用 GNU GPL v3.0 許可證。
單獨聲明許可證的內容沿用原許可證。
許可證全文見 [LICENSE](LICENSE)。

## 第三方許可證

內置 tom_d4rt 用 MIT。
許可證保留在 `vendor/tom_d4rt/LICENSE`。
