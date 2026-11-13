const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { JSDOM } = require('jsdom');

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    passed++;
    console.log(`  ok - ${message}`);
  } else {
    failed++;
    console.error(`  FAIL - ${message}`);
  }
}

function testBackgroundValidation() {
  const contractSource = fs.readFileSync(
    path.join(__dirname, '..', 'rpc-contract.js'),
    'utf8',
  );
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'background.js'),
    'utf8',
  );
  const port = {
    disconnect() {},
    postMessage() {},
    onMessage: { addListener() {} },
    onDisconnect: { addListener() {} },
  };
  const context = vm.createContext({
    URL,
    console,
    setTimeout,
    clearTimeout,
    importScripts() {},
    chrome: {
      runtime: {
        id: 'extension-id',
        lastError: null,
        connectNative: () => port,
        onSuspend: { addListener() {} },
        onMessage: { addListener() {} },
      },
      idle: { onStateChanged: { addListener() {} } },
    },
  });
  vm.runInContext(contractSource, context);
  vm.runInContext(source, context);

  const validated = vm.runInContext(
    `validatedRequest(
      {
        method: 'matchEntries',
        params: {
          url: 'https://victim.example/',
          submitUrl: 'https://victim.example/login',
          topUrl: 'https://victim.example/'
        }
      },
      { tab: { id: 1 }, url: 'https://evil.example/login', frameId: 2 }
    )`,
    context,
  );
  assert(
    validated.params.url === 'https://evil.example/login',
    'content request URL is replaced with the trusted sender URL',
  );
  assert(
    validated.params.submitUrl === undefined &&
      validated.params.topUrl === undefined,
    'cross-origin and top-frame match hints are removed',
  );

  const passkey = vm.runInContext(
    `validatedRequest(
      { method: 'getPasskey', params: { pageUrl: 'https://victim.example/' } },
      { tab: { id: 1 }, url: 'https://evil.example/login', frameId: 0 }
    )`,
    context,
  );
  assert(
    passkey.params.pageUrl === 'https://evil.example/login',
    'passkey page URL is bound to the trusted sender URL',
  );

  let rejected = false;
  try {
    vm.runInContext(
      `validatedRequest(
        { method: 'deleteEntry', params: {} },
        { tab: { id: 1 }, url: 'https://evil.example/' }
      )`,
      context,
    );
  } catch (_) {
    rejected = true;
  }
  assert(rejected, 'content scripts cannot call popup-only destructive methods');
}

async function testPageBridgeAllowlist() {
  const contractSource = fs.readFileSync(
    path.join(__dirname, '..', 'rpc-contract.js'),
    'utf8',
  );
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'passkey-inject.js'),
    'utf8',
  );
  const dom = new JSDOM('<html><head></head><body></body></html>', {
    url: 'https://example.com/',
    runScripts: 'outside-only',
  });
  const calls = [];
  dom.window.chrome = {
    runtime: {
      lastError: null,
      getURL: (value) => `chrome-extension://extension-id/${value}`,
      sendMessage: (message, callback) => {
        calls.push(message);
        callback({ ok: true, data: {} });
      },
    },
  };
  dom.window.eval(contractSource);
  dom.window.eval(source);

  dom.window.dispatchEvent(
    new dom.window.MessageEvent('message', {
      source: dom.window,
      data: {
        source: 'openvalut-injected-script',
        id: 'attack',
        method: 'deleteEntry',
        payload: { fileId: 'victim', entryUuid: 'victim' },
      },
    }),
  );
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert(calls.length === 0, 'page bridge rejects arbitrary Native Host methods');

  dom.window.dispatchEvent(
    new dom.window.MessageEvent('message', {
      source: dom.window,
      data: {
        source: 'openvalut-injected-script',
        id: 'passkey',
        method: 'getPasskey',
        payload: { options: {} },
      },
    }),
  );
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert(
    calls.length === 1 && calls[0].method === 'getPasskey',
    'page bridge permits the WebAuthn method allowlist',
  );

  const fallbackDom = new JSDOM('<html><head></head><body></body></html>', {
    url: 'https://example.com/',
    runScripts: 'outside-only',
  });
  const fallbackCalls = [];
  fallbackDom.window.chrome = {
    runtime: {
      lastError: null,
      getURL: (value) => `chrome-extension://extension-id/${value}`,
      sendMessage: (message, callback) => {
        fallbackCalls.push(message);
        callback({ ok: true, data: {} });
      },
    },
  };
  fallbackDom.window.eval(source);
  fallbackDom.window.dispatchEvent(
    new fallbackDom.window.MessageEvent('message', {
      source: fallbackDom.window,
      data: {
        source: 'openvalut-injected-script',
        id: 'fallback-passkey',
        method: 'getPasskey',
        payload: { options: {} },
      },
    }),
  );
  fallbackDom.window.dispatchEvent(
    new fallbackDom.window.MessageEvent('message', {
      source: fallbackDom.window,
      data: {
        source: 'openvalut-injected-script',
        id: 'fallback-attack',
        method: 'deleteEntry',
        payload: {},
      },
    }),
  );
  await new Promise((resolve) => setTimeout(resolve, 0));
  assert(
    fallbackCalls.length === 1 &&
      fallbackCalls[0].method === 'getPasskey',
    'page bridge keeps a restrictive fallback when the contract is unavailable',
  );
}

async function main() {
  testBackgroundValidation();
  await testPageBridgeAllowlist();
  console.log(`\nSecurity result: ${passed} passed, ${failed} failed`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
