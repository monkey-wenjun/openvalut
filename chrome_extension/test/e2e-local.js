// End-to-end test of the LOCAL FILE unlock flow through the real extension
// UI: options page (configure path) -> popup (master password -> openVault)
// -> login page auto-fill.
const EXT_ID = 'hnjmpepmjglmnfifjhomiadmbdpdfkik';
const PORT = 9227;
const LOGIN_URL = 'http://localhost:8931/login.html';
const VAULT_PATH = '/tmp/e2e.kdbx';
const VAULT_PASSWORD = 'test-password';

async function getTargets() {
  const res = await fetch(`http://localhost:${PORT}/json/list`);
  return res.json();
}

function connect(wsUrl) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    ws.onopen = () => resolve(ws);
    ws.onerror = (e) => reject(new Error(`ws error: ${e.message}`));
  });
}

class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      }
    };
  }
  send(method, params = {}) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }
  close() {
    this.ws.close();
  }
}

async function findTarget(type, urlPart, tries = 20) {
  for (let i = 0; i < tries; i++) {
    const targets = await getTargets();
    const found = targets.find(
      (t) => t.type === type && (!urlPart || t.url.includes(urlPart)),
    );
    if (found) return found;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`target not found: ${type} ${urlPart}`);
}

async function main() {
  let failed = 0;
  const ok = (cond, msg) => {
    if (cond) console.log('  ok -', msg);
    else {
      console.error('  FAIL -', msg);
      failed++;
    }
  };

  const pageTarget = await findTarget('page', '');
  const page = new Cdp(await connect(pageTarget.webSocketDebuggerUrl));
  await page.send('Page.enable');
  await page.send('Runtime.enable');

  // 1. Configure the local vault in the options page.
  await page.send('Page.navigate', {
    url: `chrome-extension://${EXT_ID}/options.html`,
  });
  await new Promise((r) => setTimeout(r, 1000));
  await page.send('Runtime.evaluate', {
    expression: `document.getElementById('source-local').click()`,
  });
  await new Promise((r) => setTimeout(r, 200));
  await page.send('Runtime.evaluate', {
    expression: `document.getElementById('local-path').value = ${JSON.stringify(
      VAULT_PATH,
    )}`,
  });
  await page.send('Runtime.evaluate', {
    expression: `document.getElementById('save-btn').click()`,
  });
  await new Promise((r) => setTimeout(r, 800));
  const savedStatus = await page.send('Runtime.evaluate', {
    expression: `document.getElementById('status').textContent`,
    returnByValue: true,
  });
  ok(
    savedStatus.result.value.includes('设置已保存'),
    `options saved (${savedStatus.result.value})`,
  );

  // 2. Open the popup and unlock with the master password.
  await page.send('Page.navigate', {
    url: `chrome-extension://${EXT_ID}/popup.html`,
  });
  await new Promise((r) => setTimeout(r, 800));
  const btnLabel = await page.send('Runtime.evaluate', {
    expression: `document.getElementById('unlock-btn').textContent`,
    returnByValue: true,
  });
  ok(
    btnLabel.result.value.includes('本地'),
    `popup shows local unlock button (${btnLabel.result.value})`,
  );
  await page.send('Runtime.evaluate', {
    expression: `document.getElementById('master-password').value = ${JSON.stringify(
      VAULT_PASSWORD,
    )}`,
  });
  await page.send('Runtime.evaluate', {
    expression: `document.getElementById('unlock-btn').click()`,
  });
  await new Promise((r) => setTimeout(r, 2500));

  // 3. Confirm the vault is open and the login page auto-fills.
  const swTarget = await findTarget('service_worker', EXT_ID);
  const sw = new Cdp(await connect(swTarget.webSocketDebuggerUrl));
  const list = await sw.send('Runtime.evaluate', {
    expression: `sendRequest('listVaults')`,
    awaitPromise: true,
    returnByValue: true,
  });
  const vaults = list.result.value.vaults || [];
  ok(
    vaults.length === 1 && vaults[0].path === VAULT_PATH,
    `vault open via local path (${JSON.stringify(vaults)})`,
  );

  await page.send('Page.navigate', { url: LOGIN_URL });
  await new Promise((r) => setTimeout(r, 2500));
  const state = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({user: document.getElementById("username").value, ' +
      'pass: document.getElementById("password").value})',
    returnByValue: true,
  });
  const parsed = JSON.parse(state.result.value);
  ok(
    parsed.user === 'octocat' && parsed.pass === 'gh-secret',
    `login page auto-filled (${state.result.value})`,
  );

  page.close();
  sw.close();
  console.log(failed === 0 ? '\nLOCAL UNLOCK E2E PASSED' : `\nFAILED (${failed})`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('E2E error:', e.message);
  process.exit(1);
});
