// jsdom harness that runs the real content.js against synthetic pages and a
// mocked chrome.* API, then asserts detection + filling behavior.
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const contentSource = fs.readFileSync(
  path.join(__dirname, '..', 'content.js'),
  'utf8',
);
const contractSource = fs.readFileSync(
  path.join(__dirname, '..', 'rpc-contract.js'),
  'utf8',
);
const domScannerSource = fs.readFileSync(
  path.join(__dirname, '..', 'dom-scanner.js'),
  'utf8',
);

let passed = 0;
let failed = 0;

function assert(cond, msg) {
  if (cond) {
    passed++;
    console.log(`  ok - ${msg}`);
  } else {
    failed++;
    console.error(`  FAIL - ${msg}`);
  }
}

function makeMockChrome(handlers) {
  const calls = [];
  const storageListeners = [];
  return {
    calls,
    runtime: {
      lastError: null,
      sendMessage: (msg, cb) => {
        calls.push(msg);
        const handler = handlers[msg.method];
        if (handler) {
          handler(msg.params, (data) => cb({ ok: true, data }));
        } else {
          cb({ ok: false, error: `no mock for ${msg.method}` });
        }
      },
      onMessage: {
        addListener: () => {},
      },
    },
    storage: {
      local: {
        get: async (key) => ({ autoFillSettings: { unique: true, totp: true } }),
      },
      onChanged: {
        addListener: (fn) => storageListeners.push(fn),
      },
    },
    _storageListeners: storageListeners,
  };
}

function boot(html, { url = 'https://github.com/login', handlers = {} } = {}) {
  const dom = new JSDOM(html, {
    url,
    runScripts: 'outside-only',
    pretendToBeVisual: true,
  });
  const { window } = dom;
  // Chrome has PointerEvent; jsdom does not, so give the harness the same
  // pointerdown-based close path the real browser exercises.
  if (typeof window.PointerEvent === 'undefined') {
    window.PointerEvent = window.MouseEvent;
  }

  // jsdom has no layout: give every element a sensible visible rect.
  window.Element.prototype.getBoundingClientRect = function () {
    return {
      x: 10,
      y: 10,
      width: 200,
      height: 30,
      top: 10,
      left: 10,
      right: 210,
      bottom: 40,
    };
  };
  Object.defineProperty(window.document.documentElement, 'clientWidth', {
    value: 1024,
    configurable: true,
  });
  Object.defineProperty(window.document.documentElement, 'clientHeight', {
    value: 768,
    configurable: true,
  });
  if (typeof window.InputEvent === 'undefined') {
    window.InputEvent = window.Event;
  }

  const chrome = makeMockChrome(handlers);
  window.chrome = chrome;
  window.eval(contractSource);
  window.eval(domScannerSource);
  window.eval(contentSource);
  if (window.document.readyState === 'loading') {
    // jsdom with runScripts: 'outside-only' never completes parsing on its
    // own; content.js waits for DOMContentLoaded, so fire it manually.
    window.document.dispatchEvent(new window.Event('DOMContentLoaded'));
  }
  return { window, chrome };
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const singleHostHandlers = {
  matchEntries: (params, cb) =>
    cb({
      matches: [
        {
          fileId: 'f1',
          entryUuid: 'u1',
          label: 'GitHub',
          username: 'octocat',
          quality: 'host',
          fileName: 'vault',
        },
      ],
    }),
  getCredential: (params, cb) =>
    cb({ username: 'octocat', password: 'gh-secret' }),
};

const totpHandlers = {
  matchEntries: (params, cb) =>
    cb({
      matches: [
        {
          fileId: 'f1',
          entryUuid: 'u1',
          label: 'GitHub',
          username: 'octocat',
          quality: 'host',
          fileName: 'vault',
        },
      ],
    }),
  getCredential: (params, cb) =>
    cb({ username: 'octocat', password: 'gh-secret' }),
  getTotp: (params, cb) =>
    cb({ code: '123456', period: 30, remainingSeconds: 20 }),
};

const multiMatchHandlers = {
  matchEntries: (params, cb) =>
    cb({
      matches: [
        {
          fileId: 'f1',
          entryUuid: 'u1',
          label: 'GitHub',
          username: 'octocat',
          quality: 'host',
          fileName: 'vault',
        },
        {
          fileId: 'f1',
          entryUuid: 'u2',
          label: 'GitHub (work)',
          username: 'octo@corp',
          quality: 'registrableDomain',
          fileName: 'vault',
        },
      ],
    }),
  getCredential: (params, cb) =>
    cb({ username: 'octo@corp', password: 'work-secret' }),
};

async function main() {
  console.log('Test 1: basic login form is auto-filled');
  {
    const { window, chrome } = boot(
      '<form><input id="u" type="text" name="username"><input id="p" type="password" name="password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    assert(
      window.document.getElementById('u').value === 'octocat',
      'username filled',
    );
    assert(
      window.document.getElementById('p').value === 'gh-secret',
      'password filled',
    );
    const match = chrome.calls.find((c) => c.method === 'matchEntries');
    assert(match, 'matchEntries called');
    assert(
      match && match.params.submitUrl === 'https://github.com/login',
      `submitUrl sent (got ${match && match.params.submitUrl})`,
    );
  }

  console.log('Test 2: search form is ignored');
  {
    const { window, chrome } = boot(
      '<form action="/search"><input type="text" name="q"><input type="password" name="password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    assert(
      !chrome.calls.some((c) => c.method === 'matchEntries'),
      'no match request for search form',
    );
    assert(
      window.document.querySelector('input[type="password"]').value === '',
      'search form password not filled',
    );
  }

  console.log('Test 3: username/password across different containers');
  {
    const { window, chrome } = boot(
      '<div><input id="u" type="email" autocomplete="username"></div>' +
        '<section><input id="p" type="password"></section>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    assert(
      window.document.getElementById('u').value === 'octocat',
      'detached username filled',
    );
    assert(
      window.document.getElementById('p').value === 'gh-secret',
      'detached password filled',
    );
  }

  console.log('Test 4: new-password (sign-up) fields are skipped');
  {
    const { window, chrome } = boot(
      '<form><input type="text" name="email"><input type="password" autocomplete="new-password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    assert(
      !chrome.calls.some((c) => c.method === 'matchEntries'),
      'sign-up form not treated as login',
    );
  }

  console.log('Test 5: shadow DOM login form is detected and filled');
  {
    const { window, chrome } = boot('<div id="host"></div>', {
      handlers: singleHostHandlers,
    });
    const host = window.document.getElementById('host');
    const root = host.attachShadow({ mode: 'open' });
    root.innerHTML =
      '<form><input type="text" name="user"><input type="password" name="pass"></form>';
    await wait(100);
    assert(
      root.querySelector('input[name="user"]').value === 'octocat',
      'shadow username filled',
    );
    assert(
      root.querySelector('input[name="pass"]').value === 'gh-secret',
      'shadow password filled',
    );
  }

  console.log('Test 6: multiple matches show the inline picker');
  {
    const { window } = boot(
      '<form><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: multiMatchHandlers },
    );
    await wait(100);
    assert(
      window.document.querySelector('#openvalut-inline-picker') !== null,
      'picker rendered',
    );
    assert(
      window.document.getElementById('p').value === '',
      'nothing filled before picker selection',
    );
    const row = window.document
      .querySelector('#openvalut-inline-picker')
      .shadowRoot.querySelector('.openvalut-picker-row');
    row.click();
    await wait(100);
    assert(
      window.document.getElementById('p').value === 'work-secret',
      'picker selection filled password',
    );
  }

  console.log('Test 6b: picker survives the click that opens it and rows click');
  {
    const { window } = boot(
      '<form><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: multiMatchHandlers },
    );
    await wait(100);
    const doc = window.document;
    const field = doc.getElementById('u');

    // Close the auto-shown picker, then replay a real mouse gesture: press on
    // the field, release/click it, and the picker must still be open (it used
    // to be dismissed by the same click that opened it).
    doc.body.dispatchEvent(
      new window.PointerEvent('pointerdown', { bubbles: true }),
    );
    await wait(20);
    assert(
      !doc.querySelector('#openvalut-inline-picker'),
      'outside press closes picker',
    );
    field.dispatchEvent(new window.MouseEvent('mousedown', { bubbles: true }));
    field.dispatchEvent(new window.MouseEvent('click', { bubbles: true }));
    await wait(50);
    assert(
      doc.querySelector('#openvalut-inline-picker') !== null,
      'picker stays open after the opening click',
    );

    // Move to an option and click: the press happens inside the picker, so it
    // must not dismiss; the click then fills the form.
    const row = doc
      .querySelector('#openvalut-inline-picker')
      .shadowRoot.querySelector('.openvalut-picker-row');
    row.dispatchEvent(new window.PointerEvent('pointerdown', { bubbles: true }));
    row.click();
    await wait(100);
    assert(
      doc.getElementById('p').value === 'work-secret',
      'picker row click fills password',
    );
    assert(
      !doc.querySelector('#openvalut-inline-picker'),
      'picker removed after selection',
    );
  }

  console.log('Test 6c: picker keyboard navigation (arrows + Enter)');
  {
    const { window } = boot(
      '<form><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: multiMatchHandlers },
    );
    await wait(100);
    const doc = window.document;
    const field = doc.getElementById('u');
    const picker = doc.querySelector('#openvalut-inline-picker');
    assert(picker !== null, 'picker shown');
    const key = (k) =>
      field.dispatchEvent(
        new window.KeyboardEvent('keydown', {
          key: k,
          bubbles: true,
          cancelable: true,
        }),
      );
    // Enter before any arrow navigation must not hijack the key.
    key('Enter');
    await wait(20);
    assert(
      doc.querySelector('#openvalut-inline-picker') !== null,
      'Enter ignored before arrow navigation',
    );
    // ArrowUp first wraps to the last row, ArrowDown wraps back to the
    // first — the same row the click test above fills as 'work-secret'.
    key('ArrowUp');
    key('ArrowDown');
    const active = picker.shadowRoot.querySelector(
      '.openvalut-picker-row.openvalut-picker-row-active',
    );
    assert(active !== null, 'arrow keys highlight a row');
    key('Enter');
    await wait(100);
    assert(
      doc.getElementById('p').value === 'work-secret',
      'Enter fills the highlighted row',
    );
    assert(
      !doc.querySelector('#openvalut-inline-picker'),
      'picker removed after Enter selection',
    );
  }

  console.log('Test 7: TOTP field is filled');
  {
    const { window } = boot(
      '<form><input type="text" name="user"><input type="password" name="pass">' +
        '<input id="otp" autocomplete="one-time-code"></form>',
      { handlers: totpHandlers },
    );
    await wait(100);
    assert(
      window.document.getElementById('otp').value === '123456',
      'TOTP code filled',
    );
  }

  console.log('Test 7b: TOTP field detected by numeric inputmode and maxlength');
  {
    const { window } = boot(
      '<form><input type="text" name="user"><input type="password" name="pass">' +
        '<input id="verify" inputmode="numeric" maxlength="6" placeholder="verification code"></form>',
      { handlers: totpHandlers },
    );
    await wait(100);
    assert(
      window.document.getElementById('verify').value === '123456',
      'heuristic TOTP code filled',
    );
  }

  console.log('Test 8: already-filled password is not refilled');
  {
    const { window } = boot(
      '<form><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    const before = window.document.getElementById('p').value;
    // Force a mutation so detection re-runs.
    window.document.getElementById('p').setAttribute('class', 'x');
    await wait(800);
    assert(
      window.document.getElementById('p').value === before,
      'password value unchanged after re-detection',
    );
  }

  console.log('Test 9: same-origin form action is used as submitUrl');
  {
    const { chrome } = boot(
      '<form action="/session"><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    const match = chrome.calls.find((c) => c.method === 'matchEntries');
    assert(
      match && match.params.submitUrl === 'https://github.com/session',
      `submitUrl from form action (got ${match && match.params.submitUrl})`,
    );
  }

  console.log('Test 10: cross-origin form action cannot expand credential scope');
  {
    const { chrome } = boot(
      '<form action="https://accounts.example.net/auth"><input id="u" type="text"><input id="p" type="password"></form>',
      { handlers: singleHostHandlers },
    );
    await wait(100);
    const match = chrome.calls.find((c) => c.method === 'matchEntries');
    assert(
      match && match.params.submitUrl === null,
      `cross-origin submitUrl removed (got ${match && match.params.submitUrl})`,
    );
  }

  console.log('Test 11: unrelated DOM mutations do not rescan credentials');
  {
    const { window, chrome } = boot(
      '<form><input type="text"><input type="password"></form><div id="status"></div>',
      { handlers: multiMatchHandlers },
    );
    await wait(100);
    const before = chrome.calls.filter((call) => call.method === 'matchEntries').length;
    window.document.getElementById('status').className = 'updated';
    window.document.getElementById('status').appendChild(
      window.document.createElement('span'),
    );
    await wait(650);
    const after = chrome.calls.filter((call) => call.method === 'matchEntries').length;
    assert(after === before, 'unrelated mutations do not trigger matchEntries');
  }

  console.log('\nResult:');
  console.log(`  passed: ${passed}`);
  console.log(`  failed: ${failed}`);
  process.exit(failed === 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
