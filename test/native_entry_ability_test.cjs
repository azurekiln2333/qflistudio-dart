// Exercise the actual native channel handler with OHOS services stubbed.
// This proves host behavior, separately from ArkTS compilation and device tests.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const root = path.resolve(__dirname, '..');
const ts = require(process.env.QFLI_TYPESCRIPT ||
  'D:/ProgramFiles/Huawei/DevEco Studio/tools/ohpm/node_modules/typescript');

function loadAbility() {
  const handlers = new Map();
  const calls = { external: [], events: [], shares: [], picker: [], plugins: [] };
  const context = {
    config: { colorMode: 1 },
    eventHub: { emit: (...args) => calls.events.push(args) },
    startAbility: (...args) => {
      calls.external.push(args);
      return Promise.resolve();
    },
  };
  let shareFailure;
  class FlutterAbility {
    constructor() { this.context = context; }
    configureFlutterEngine() {}
    onWindowStageCreate() {}
  }
  class MethodChannel {
    constructor(messenger, name) { this.name = name; }
    setMethodCallHandler(handler) { handlers.set(this.name, handler); }
  }
  const modules = {
    '@ohos/flutter_ohos': { FlutterAbility, MethodChannel },
    '@kit.ShareKit': {
      systemShare: {
        SharedData: class { constructor(record) { this.record = record; } },
        ShareController: class {
          constructor(data) { this.data = data; }
          show(ability, options) {
            calls.shares.push([ability, this.data.record, options]);
            return shareFailure ? Promise.reject(shareFailure) : Promise.resolve();
          }
        },
      },
    },
    '@kit.AbilityKit': {
      ConfigurationConstant: { ColorMode: { COLOR_MODE_DARK: 1 } },
    },
    '../plugins/GeneratedPluginRegistrant': {
      GeneratedPluginRegistrant: { registerWith: (engine) => calls.plugins.push(engine) },
    },
    './PickerBridge': {
      isPickerMethod: (method) =>
        ['pickDocument', 'saveDocument', 'pickPhotos', 'readUri', 'writeUri'].includes(method),
      handlePickerCall: (ability, call, result) => {
        calls.picker.push([ability, call.method]);
        result.success('local-picker');
      },
    },
  };
  const source = fs.readFileSync(path.join(root,
    'ohos/entry/src/main/ets/entryability/EntryAbility.ets'), 'utf8');
  const compiled = ts.transpileModule(source, {
    compilerOptions: { target: ts.ScriptTarget.ES2020, module: ts.ModuleKind.CommonJS },
    reportDiagnostics: true,
  });
  assert.deepEqual(compiled.diagnostics, []);
  const module = { exports: {} };
  vm.runInNewContext(compiled.outputText, {
    module,
    exports: module.exports,
    require: (name) => {
      assert.ok(Object.hasOwn(modules, name), `Unexpected system import: ${name}`);
      return modules[name];
    },
  }, { filename: 'EntryAbility.js' });
  const ability = new module.exports.default();
  const engine = { dartExecutor: { getBinaryMessenger: () => ({}) } };
  ability.configureFlutterEngine(engine);
  assert.deepEqual([...handlers.keys()], ['qflistudio/platform']);
  async function invoke(method, args = {}) {
    const results = [];
    handlers.get('qflistudio/platform').onMethodCall({
      method,
      argument: (key) => args[key],
    }, {
      success: (value) => results.push({ success: value }),
      error: (code, message, details) => results.push({ code, message, details }),
      notImplemented: () => results.push({ notImplemented: true }),
    });
    await Promise.resolve();
    await Promise.resolve();
    assert.equal(results.length, 1, `${method} must answer exactly once`);
    return results[0];
  }
  return { ability, context, engine, calls, invoke,
    failShare: (error) => { shareFailure = error; } };
}

test('direct URL and agreement calls fail offline without launching an ability', async () => {
  const { invoke, calls } = loadAbility();
  for (const method of ['openUrl', 'openAgreement']) {
    for (const url of ['https://example.com', 'http://127.0.0.1:8080',
      'file:///data/local', 'custom:external', '', undefined, 17, {}]) {
      const result = await invoke(method, { url });
      assert.equal(result.code, 'OFFLINE_ONLY');
      assert.ok(result.message.length > 0);
    }
  }
  assert.deepEqual(calls.external, []);
  assert.deepEqual(await invoke('unknown'), { notImplemented: true });
});

test('local share, file picker, plugin registration and native window remain wired', async () => {
  const { ability, context, engine, calls, invoke, failShare } = loadAbility();
  assert.deepEqual(calls.plugins, [engine]);
  assert.deepEqual(await invoke('shareText', { title: '本地', text: 'Dart 😀' }), { success: null });
  assert.equal(calls.shares[0][0], context);
  assert.equal(calls.shares[0][1].content, 'Dart 😀');
  assert.equal(calls.shares[0][1].title, '本地');
  failShare({ code: 11, message: 'cancelled' });
  assert.equal((await invoke('shareText', { text: 'local' })).code, 'SHARE_FAILED');
  for (const method of ['pickDocument', 'saveDocument', 'pickPhotos', 'readUri', 'writeUri']) {
    assert.deepEqual(await invoke(method), { success: 'local-picker' });
  }
  assert.equal(calls.picker.length, 5);
  const colors = [];
  const stage = { getMainWindowSync: () => ({ setWindowBackgroundColor: (color) => colors.push(color) }) };
  ability.onWindowStageCreate(stage);
  context.config.colorMode = 0;
  ability.onWindowStageCreate(stage);
  assert.deepEqual(colors, ['#FF111418', '#FFF8F9FF']);
  assert.deepEqual(calls.external, []);
});
