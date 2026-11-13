// End-to-end test: real Chrome extension + real native host + real KDBX.
// 1. Navigate a page to the local login form (wakes the extension SW via the
//    content script).
// 2. Open the vault inside the extension service worker.
// 3. Reload the login page and assert the fields were auto-filled by the
//    native host round trip.
const EXT_ID = 'hnjmpepmjglmnfifjhomiadmbdpdfkik';
const PORT = 9226;
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

async function findTarget(type, urlPart) {
  for (let i = 0; i < 20; i++) {
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
  // Navigate the blank page to the login form; the content script messages
  // the background, which wakes the MV3 service worker.
  const pageTarget = await findTarget('page', '');
  if (pageTarget.url.startsWith('chrome://')) {
    // Pick any normal page target instead of an internal chrome:// one.
    const targets = await getTargets();
    const normal = targets.find(
      (t) => t.type === 'page' && !t.url.startsWith('chrome://'),
    );
    if (!normal) throw new Error('no navigable page target');
    pageTarget.webSocketDebuggerUrl = normal.webSocketDebuggerUrl;
    pageTarget.url = normal.url;
  }
  const page = new Cdp(await connect(pageTarget.webSocketDebuggerUrl));
  await page.send('Page.enable');
  await page.send('Page.navigate', { url: LOGIN_URL });
  await new Promise((r) => setTimeout(r, 1500));

  const swTarget = await findTarget('service_worker', EXT_ID);
  console.log('service worker found:', swTarget.url);
  const sw = new Cdp(await connect(swTarget.webSocketDebuggerUrl));

  // Open the vault through the real native host.
  const open = await sw.send('Runtime.evaluate', {
    expression: `sendRequest('openVault', { path: ${JSON.stringify(
      VAULT_PATH,
    )}, password: ${JSON.stringify(VAULT_PASSWORD)} })`,
    awaitPromise: true,
    returnByValue: true,
  });
  console.log('openVault result:', JSON.stringify(open.result.value));
  if (!open.result.value || open.result.value.entryCount !== 1) {
    throw new Error('vault did not open');
  }

  // Reload the page so a fresh content script run does the auto-fill.
  await page.send('Page.navigate', { url: LOGIN_URL });
  await new Promise((r) => setTimeout(r, 2500));

  const state = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({user: document.getElementById("username").value, ' +
      'pass: document.getElementById("password").value, ' +
      'reactLike: window.__reactLikeValue ? window.__reactLikeValue() : null})',
    returnByValue: true,
  });
  console.log('page state:', state.result.value);

  const parsed = JSON.parse(state.result.value);
  let failed = 0;
  if (parsed.user === 'octocat') console.log('  ok - username auto-filled');
  else {
    console.error('  FAIL - username', parsed.user);
    failed++;
  }
  if (parsed.pass === 'gh-secret') console.log('  ok - password auto-filled');
  else {
    console.error('  FAIL - password', parsed.pass);
    failed++;
  }
  if (parsed.reactLike === 'gh-secret') {
    console.log('  ok - React-style input listener saw the value');
  } else {
    console.error('  FAIL - React-like listener value', parsed.reactLike);
    failed++;
  }

  // --- Scenario 2: page URL does not match, form submit URL does ----------
  console.log('\nScenario 2: submitUrl matching');
  await page.send('Page.navigate', { url: 'http://localhost:8931/other.html' });
  await new Promise((r) => setTimeout(r, 2000));
  const s2 = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({user: document.getElementById("username").value, ' +
      'pass: document.getElementById("password").value})',
    returnByValue: true,
  });
  const p2 = JSON.parse(s2.result.value);
  if (p2.user === 'octocat' && p2.pass === 'gh-secret') {
    console.log('  ok - filled via form action URL');
  } else {
    console.error('  FAIL - submitUrl scenario', p2);
    failed++;
  }

  // --- Scenario 3: no matching entry leaves the form alone ---------------
  console.log('\nScenario 3: no match stays empty');
  await page.send('Page.navigate', { url: 'http://localhost:8931/nomatch.html' });
  await new Promise((r) => setTimeout(r, 2000));
  const s3 = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({user: document.getElementById("username").value, ' +
      'pass: document.getElementById("password").value})',
    returnByValue: true,
  });
  const p3 = JSON.parse(s3.result.value);
  if (p3.user === '' && p3.pass === '') {
    console.log('  ok - no match, form untouched');
  } else {
    console.error('  FAIL - no-match scenario', p3);
    failed++;
  }

  // --- Scenario 4: multiple matches show the inline picker ---------------
  console.log('\nScenario 4: multi-match inline picker');
  await sw.send('Runtime.evaluate', {
    expression: `sendRequest('openVault', { path: '/tmp/e2e2.kdbx', ` +
      `password: 'test-password' })`,
    awaitPromise: true,
    returnByValue: true,
  });
  await page.send('Page.navigate', { url: LOGIN_URL });
  await new Promise((r) => setTimeout(r, 2000));
  const s4 = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({picker: !!document.querySelector("#openvalut-inline-picker"), ' +
      'rows: Array.from(document.querySelector("#openvalut-inline-picker").shadowRoot.querySelectorAll(".openvalut-picker-row")).map(d=>d.textContent), ' +
      'pass: document.getElementById("password").value})',
    returnByValue: true,
  });
  const p4 = JSON.parse(s4.result.value);
  if (p4.picker && p4.rows.length >= 4 && p4.pass === '') {
    console.log('  ok - picker shown, nothing filled yet');
    console.log('      rows:', p4.rows.join(' | '));
  } else {
    console.error('  FAIL - picker scenario', p4);
    failed++;
  }
  // Pick the last row ("GitHub Work") and expect a fill.
  const clickRes = await page.send('Runtime.evaluate', {
    expression:
      'document.querySelector("#openvalut-inline-picker").shadowRoot.querySelectorAll(".openvalut-picker-row")[3].click()',
  });
  await new Promise((r) => setTimeout(r, 1200));
  const s4b = await page.send('Runtime.evaluate', {
    expression:
      'JSON.stringify({user: document.getElementById("username").value, ' +
      'pass: document.getElementById("password").value})',
    returnByValue: true,
  });
  const p4b = JSON.parse(s4b.result.value);
  if (p4b.user === 'octo@corp' && p4b.pass === 'work-secret') {
    console.log('  ok - picker selection filled the form');
  } else {
    console.error('  FAIL - picker selection', p4b);
    failed++;
  }

  page.close();
  sw.close();
  console.log(failed === 0 ? '\nALL E2E PASSED' : `\nE2E FAILED (${failed})`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error('E2E error:', e.message);
  process.exit(1);
});
