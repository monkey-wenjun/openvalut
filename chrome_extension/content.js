'use strict';

(function () {
  // Guard against duplicate injection when the extension is reloaded or when
  // multiple versions are active at the same time.
  if (window.__openvalutContentScriptLoaded) {
    console.debug('OpenValut content script already loaded; skipping duplicate.');
    return;
  }
  window.__openvalutContentScriptLoaded = true;

  // =====================================================================
  // OpenValut content script — login form detection and filling.
//
// The approach is ported from KeePassXC Browser (keepassxc-browser):
//  - visibility checks go beyond offsetParent: position, size, opacity,
//    topmost-element and search-form/field filtering
//  - inputs are collected including open shadow roots
//  - username/password combinations are paired across the whole page in
//    DOM order, not only inside <form> elements
//  - filling dispatches the full event sequence React-style frameworks
//    need (focus/focusin/keydown/beforeinput/keypress/value/input/keyup/
//    change + legacy events), which plain value assignment breaks
// =====================================================================

const MIN_INPUT_FIELD_WIDTH_PX = 8;
const MIN_OPACITY = 0.7;
const MAX_OPACITY = 1;
const MAX_INPUTS = 100;

const OTP_ALLOWED_TYPES = new Set(['number', 'password', 'tel', 'text']);
const OTP_IGNORED_TYPES = new Set(['email', 'username']);
// Matches words like "promo code", "decode", "author", "comment" that are
// not one-time codes.
const OTP_IGNORE =
  /(bank|bar|coupon|post(al)?|user|zip|promo).*code|(en|de)code(d|r)*|comment|author|error/i;
const OTP_FIELDS = [
  '2fa',
  '2fpin',
  'auth',
  'challenge',
  'code',
  'idvpin',
  'mfa',
  'one_time_password',
  'one-time password',
  'otc-confirmation-input',
  'otp',
  'otppw',
  'token',
  'twofa',
  'two-factor',
  'twofactor',
  'verification_pin',
  'mfacode',
];
const OTP_PARENTS = ['.mfa-verify'];

const SETTINGS_KEY = 'autoFillSettings';
const DEFAULT_SETTINGS = { unique: true, totp: true };

let settings = { ...DEFAULT_SETTINGS };
let combos = [];
let recheckTimer = null;
let initialized = false;
const { collectInputs, mutationNeedsDetection } = OpenValutDom;

// Password fields we have already filled. A field is removed again when the
// user edits it, so a manual change is never fought by a refill, but a
// re-rendered login form is not filled twice either.
const filledPasswords = new WeakSet();

// ---------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------

async function loadSettings() {
  try {
    const result = await chrome.storage.local.get(SETTINGS_KEY);
    settings = { ...DEFAULT_SETTINGS, ...(result[SETTINGS_KEY] || {}) };
  } catch (e) {
    console.warn('OpenValut: failed to load settings:', e);
  }
}

// ---------------------------------------------------------------------
// Visibility and input collection
// ---------------------------------------------------------------------

function isVisible(elem) {
  const rect = elem.getBoundingClientRect();
  if (
    rect.x < 0 ||
    rect.y < 0 ||
    rect.width < MIN_INPUT_FIELD_WIDTH_PX ||
    rect.height < MIN_INPUT_FIELD_WIDTH_PX ||
    rect.x >
      Math.max(
        document.body.scrollWidth,
        document.body.offsetWidth,
        document.documentElement.clientWidth,
      ) ||
    rect.y >
      Math.max(
        document.body.scrollHeight,
        document.body.offsetHeight,
        document.documentElement.clientHeight,
      )
  ) {
    return false;
  }

  if (!isTopElement(elem, rect)) {
    return false;
  }

  const style = getComputedStyle(elem);
  if (
    style.visibility === 'hidden' ||
    style.visibility === 'collapse'
  ) {
    return false;
  }
  const opacity = style.opacity;
  if (
    opacity !== '' &&
    !Number.isNaN(Number(opacity)) &&
    (Number(opacity) < MIN_OPACITY || Number(opacity) > MAX_OPACITY)
  ) {
    return false;
  }
  if (
    parseInt(style.width, 10) <= MIN_INPUT_FIELD_WIDTH_PX ||
    parseInt(style.height, 10) <= MIN_INPUT_FIELD_WIDTH_PX
  ) {
    return false;
  }

  // A parent with low inline opacity hides the field even when the field's
  // own computed opacity is fine.
  for (let parent = elem.parentElement; parent; parent = parent.parentElement) {
    const parentOpacity = parent.style.opacity;
    if (
      parentOpacity !== '' &&
      !Number.isNaN(Number(parentOpacity)) &&
      (Number(parentOpacity) < MIN_OPACITY ||
        Number(parentOpacity) > MAX_OPACITY)
    ) {
      return false;
    }
  }
  return true;
}

// Returns false when something else is rendered on top of the field. Labels
// wrapping the input are allowed (the label is the topmost element then).
function isTopElement(elem, rect) {
  const root = elem.getRootNode ? elem.getRootNode() : document;
  const centerY = rect.top + rect.height / 2;
  const points = [
    rect.left + rect.width / 4,
    rect.left + rect.width / 2,
    rect.left + rect.width / 1.33,
  ];
  for (const x of points) {
    let top = null;
    try {
      top = root.elementFromPoint(x, centerY);
    } catch (_) {
      // Cross-root elementFromPoint can throw; treat as visible.
    }
    if (!top || top === elem) {
      continue;
    }
    const labelCovers =
      elem.labels &&
      Array.from(elem.labels).some((label) => label.contains(top));
    if (!labelCovers) {
      return false;
    }
  }
  return true;
}

function isSearchForm(form) {
  const action = (form.getAttribute('action') || '').toLowerCase();
  if (action.includes('search') && !action.includes('research')) {
    return true;
  }
  const id = (form.getAttribute('id') || '').toLowerCase();
  const className = form.className || '';
  if (
    (typeof className === 'string' && className.includes('search')) ||
    (id.includes('search') && !id.includes('research'))
  ) {
    return true;
  }
  return false;
}

function isSearchField(target) {
  for (const attr of target.attributes) {
    const value = attr.value;
    if (value && (value.toLowerCase().includes('search') || value === 'q')) {
      return true;
    }
  }
  if (target.form && isSearchForm(target.form)) {
    return true;
  }
  if (target.closest("[role~='search']")) {
    return true;
  }
  return false;
}

// Sign-up forms mark their password with autocomplete="new-password"; filling
// them with an existing credential would be wrong, so they are ignored.
function isAutocompleteAppropriate(field) {
  return (field.getAttribute('autocomplete') || '').toLowerCase() !== 'new-password';
}

function detectInputs() {
  const all = collectInputs(document.body, []);
  const visible = all.filter(
    (el) =>
      !el.disabled &&
      el.getAttribute('type') !== 'hidden' &&
      USERNAME_OR_PASSWORD_TYPES.has(el.getAttribute('type')) &&
      isVisible(el) &&
      !isSearchField(el) &&
      isAutocompleteAppropriate(el),
  );
  return visible.slice(0, MAX_INPUTS);
}

const USERNAME_OR_PASSWORD_TYPES = new Set([
  'text',
  'email',
  'password',
  'tel',
  'number',
  'username',
  null,
]);

// ---------------------------------------------------------------------
// TOTP field detection
// ---------------------------------------------------------------------

function isTotpField(field) {
  const autocomplete = (field.getAttribute('autocomplete') || '').toLowerCase();
  if (autocomplete === 'one-time-code') {
    return true;
  }
  const type = (field.getAttribute('type') || 'text').toLowerCase();
  if (!OTP_ALLOWED_TYPES.has(type)) {
    return false;
  }
  const id = (field.id || '').toLowerCase();
  const name = (field.name || '').toLowerCase();
  const placeholder = (field.getAttribute('placeholder') || '').toLowerCase();
  const ariaLabel = (field.getAttribute('aria-label') || '').toLowerCase();
  const inputmode = (field.getAttribute('inputmode') || '').toLowerCase();
  const maxLength = parseInt(field.getAttribute('maxlength') || '0', 10);
  const text = `${id} ${name} ${placeholder} ${ariaLabel}`;

  const include = (f) => text.includes(f);
  const positive =
    OTP_FIELDS.some(include) || OTP_PARENTS.some((s) => field.closest(s));
  const negative =
    [...OTP_IGNORED_TYPES].some(include) || OTP_IGNORE.test(text);

  if (positive && !negative) {
    return true;
  }

  // Heuristic: a short numeric input with no other obvious purpose is very
  // likely a TOTP/2FA field, even when the site does not use standard names.
  // We require inputmode="numeric" (or tel/number) and a maxlength between
  // 4 and 8 to avoid matching search/pin-unrelated fields.
  const numericInputmode =
    inputmode === 'numeric' || inputmode === 'tel' || type === 'number';
  const shortCode = maxLength >= 4 && maxLength <= 8;
  const looksLikeCode = /\b(code|token|pin|verification|verify|authenticator|security|passcode|验证码|动态码|校验码)\b/i.test(text);
  if (numericInputmode && shortCode && looksLikeCode && !negative) {
    return true;
  }

  return false;
}

// Segmented TOTP: several adjacent single-character numeric fields (many
// banks / authenticator pages render one box per digit).
function handleSegmentedTotp(inputs, combinations) {
  if (combinations.some((c) => c.totpInputs)) {
    return;
  }
  const candidates = inputs.filter(
    (field) =>
      !['hidden', 'password', 'submit'].includes(field.getAttribute('type')) &&
      field.offsetWidth < 100,
  );
  const isSegmented = (list, ignoreCount) =>
    ((ignoreCount && list.length >= 4) || list.length === 6) &&
    list.every(
      (field) =>
        (field.type === 'tel') ||
        ((field.type === 'text' || field.type === 'number') &&
          (field.maxLength === 1 || field.maxLength === -1)) ||
        ((field.inputMode === 'numeric' || field.inputMode === '') &&
          (field.pattern || '').includes('0-9')),
    );
  if (isSegmented(candidates) || (inputs.length === 6 && isSegmented(inputs, true))) {
    combinations.push({
      username: null,
      password: null,
      passwordInputs: [],
      form: null,
      totp: null,
      totpInputs: candidates.slice(0, 6),
    });
  }
}

// ---------------------------------------------------------------------
// Username/password combination detection
// ---------------------------------------------------------------------

function getAllCombinations(inputs) {
  const combinations = [];
  let usernameField = null;

  for (const input of inputs) {
    const type = (input.getAttribute('type') || 'text').toLowerCase();
    if (type === 'password') {
      const combination = {
        username: !usernameField || usernameField.size < 1 ? null : usernameField,
        password: input,
        passwordInputs: [input],
        form: input.form,
        totp: null,
        totpInputs: null,
      };
      combinations.push(getExistingCombination(combination));
      usernameField = null;
    } else if (isTotpField(input)) {
      combinations.push({
        username: null,
        password: null,
        passwordInputs: [],
        form: null,
        totp: input,
        totpInputs: null,
      });
    } else {
      usernameField = input;
    }
  }

  // A lone username field with an explicit autocomplete hint is still a login
  // form (passwordless logins / username-first flows).
  const autocomplete = usernameField
    ? (usernameField.getAttribute('autocomplete') || '').toLowerCase()
    : '';
  if (
    combinations.length === 0 &&
    usernameField &&
    (autocomplete.includes('username') || autocomplete.includes('email'))
  ) {
    combinations.push({
      username: usernameField,
      password: null,
      passwordInputs: [],
      form: usernameField.form,
      totp: null,
      totpInputs: null,
    });
  }

  handleSegmentedTotp(inputs, combinations);
  return combinations;
}

// Merges a newly found combination into an existing one for the same form so
// a form with username and password in separate containers stays one combo.
function getExistingCombination(combination) {
  const existing = combos.find((c) => c.form === combination.form && c.form);
  if (existing) {
    existing.username ??= combination.username;
    existing.password ??= combination.password;
    if (existing.passwordInputs.length === 0) {
      existing.passwordInputs = combination.passwordInputs;
    } else if (combination.password) {
      existing.password = combination.password;
    }
    return existing;
  }
  return combination;
}

// ---------------------------------------------------------------------
// Filling
// ---------------------------------------------------------------------

// The event sequence React, Angular and friends listen for. The async gap
// lets focus handlers run before the value lands (keepassxc issue #2215).
async function setValueWithChange(field, value) {
  if (!field || (field.readOnly && !value)) {
    return;
  }
  if (field.readOnly) {
    return;
  }
  field.focus();
  await new Promise((resolve) => setTimeout(resolve, 0));

  field.dispatchEvent(new FocusEvent('focus', { bubbles: false }));
  field.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
  field.dispatchEvent(
    new KeyboardEvent('keydown', { bubbles: true, cancelable: false, key: value }),
  );
  field.dispatchEvent(
    new InputEvent('beforeinput', {
      bubbles: true,
      cancelable: false,
      inputType: 'insertText',
      data: value,
    }),
  );
  field.dispatchEvent(
    new KeyboardEvent('keypress', { bubbles: true, cancelable: false, key: value }),
  );
  field.value = value;
  field.dispatchEvent(new Event('input', { bubbles: true, cancelable: false }));
  field.dispatchEvent(
    new KeyboardEvent('keyup', { bubbles: true, cancelable: false, key: value }),
  );
  field.dispatchEvent(new Event('change', { bubbles: true, cancelable: false }));

  // Legacy initEvent events; some sites only react to those.
  const legacy = (eventName) => {
    const event = field.ownerDocument.createEvent('Event');
    event.initEvent(eventName, true, false);
    field.dispatchEvent(event);
  };
  legacy('input');
  legacy('change');
}

function markFilled(passwordField, value) {
  filledPasswords.add(passwordField);
  const onEdit = () => {
    if (passwordField.value !== value) {
      filledPasswords.delete(passwordField);
      passwordField.removeEventListener('input', onEdit);
      passwordField.removeEventListener('change', onEdit);
    }
  };
  passwordField.addEventListener('input', onEdit);
  passwordField.addEventListener('change', onEdit);
}

async function fillCombo(combo, credential) {
  if (combo.username && credential.username) {
    await setValueWithChange(combo.username, credential.username);
  }
  if (combo.password && credential.password) {
    await setValueWithChange(combo.password, credential.password);
    markFilled(combo.password, credential.password);
  }
}

async function fillTotpCombo(combo, code) {
  if (combo.totpInputs && combo.totpInputs.length > 0) {
    for (let i = 0; i < combo.totpInputs.length && i < code.length; i++) {
      await setValueWithChange(combo.totpInputs[i], code[i]);
    }
  } else if (combo.totp) {
    await setValueWithChange(combo.totp, code);
  }
}

function comboFromActiveElement() {
  const active = document.activeElement;
  if (!active) {
    return null;
  }
  return (
    combos.find(
      (c) =>
        c.username === active ||
        c.password === active ||
        (c.passwordInputs && c.passwordInputs.includes(active)) ||
        c.totp === active,
    ) || null
  );
}

// ---------------------------------------------------------------------
// Messaging
// ---------------------------------------------------------------------

function sendMessage(method, params, retry = true) {
  return new Promise((resolve, reject) => {
    chrome.runtime.sendMessage({ method, params }, (response) => {
      if (chrome.runtime.lastError) {
        const err = chrome.runtime.lastError.message || '';
        // "Could not establish connection" usually means the service worker
        // is still waking up or the native host has not connected yet. Retry
        // once after a short delay.
        if (retry && err.includes('Could not establish connection')) {
          console.debug('OpenValut: retrying message', method, 'after connection error');
          setTimeout(() => {
            sendMessage(method, params, false).then(resolve).catch(reject);
          }, 400);
          return;
        }
        reject(new Error(err));
        return;
      }
      if (response && response.ok) {
        resolve(response.data);
      } else {
        reject(new Error((response && response.error) || 'Unknown error'));
      }
    });
  });
}

// Popup asks us to fill a TOTP code after it has filled username/password.
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action !== 'fillTotp') {
    return false;
  }
  (async () => {
    try {
      const data = await sendMessage('getTotp', {
        fileId: request.fileId,
        entryUuid: request.entryUuid,
      });
      const filled = await fillVisibleTotpFields(data.code);
      sendResponse({ ok: true, filled });
    } catch (e) {
      sendResponse({ ok: false, error: e.message });
    }
  })();
  return true; // keep channel open for async response
});

async function fillVisibleTotpFields(code) {
  const inputs = collectInputs(document.body, []);
  const totpCombos = [];
  for (const input of inputs) {
    if (isTotpField(input) && isVisible(input) && !input.disabled) {
      totpCombos.push({
        username: null,
        password: null,
        passwordInputs: [],
        form: null,
        totp: input,
        totpInputs: null,
      });
    }
  }
  // Segmented TOTP fields (6 single-digit boxes).
  handleSegmentedTotp(inputs, totpCombos);
  if (totpCombos.length === 0) {
    return false;
  }
  for (const combo of totpCombos) {
    await fillTotpCombo(combo, code);
  }
  return true;
}

function getSubmitUrl(combo) {
  if (combo.form && typeof combo.form.action === 'string' && combo.form.action) {
    try {
      const action = new URL(combo.form.action, location.href);
      return action.origin === location.origin ? action.href : null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ---------------------------------------------------------------------
// Report and fill
// ---------------------------------------------------------------------

const focusAttached = new WeakSet();
let inlinePickerCleanup = null;

function isVaultLockedError(e) {
  const msg = (e && e.message) || '';
  return msg.includes('No vaults are unlocked') || msg.includes('unlocked');
}

async function fetchMatchesForCombo(combo, limit = 10) {
  // Only the frame's own origin may select credentials. A cross-origin form
  // action or parent URL is controlled by page content and must not expand the
  // credential scope.
  const url = location.href;
  const submitUrl = getSubmitUrl(combo);
  try {
    const data = await sendMessage('matchEntries', { url, submitUrl, limit });
    return { matches: (data && data.matches) || [], locked: false };
  } catch (e) {
    if (isVaultLockedError(e)) {
      console.debug('OpenValut: vault is locked');
      return { matches: [], locked: true };
    }
    console.warn('OpenValut match failed:', e);
    return { matches: [], locked: false };
  }
}

function attachFocusPicker(combo) {
  const fields = [combo.username, combo.password].filter(Boolean);
  for (const field of fields) {
    if (focusAttached.has(field)) {
      continue;
    }
    focusAttached.add(field);
    const show = async (eventName) => {
      console.debug('OpenValut: field', eventName, field.id || field.name || field.type);
      // Do not reopen while the user is interacting with the existing picker.
      if (document.querySelector('#openvalut-inline-picker')) {
        console.debug('OpenValut: picker already open, ignoring');
        return;
      }
      try {
        const result = await fetchMatchesForCombo(combo);
        // focus/click can both fire for one gesture; another invocation may
        // already have opened the picker while this fetch was in flight.
        if (document.querySelector('#openvalut-inline-picker')) {
          return;
        }
        console.debug('OpenValut: matches for focused field', result.matches.length, 'locked:', result.locked);
        if (result.locked) {
          showInlinePicker(combo, [], { locked: true });
        } else if (result.matches.length > 0) {
          showInlinePicker(combo, result.matches);
        }
      } catch (e) {
        console.warn('OpenValut: failed to show inline picker:', e);
      }
    };
    // Use capture so custom / shadow-DOM inputs cannot swallow the event.
    field.addEventListener('focus', () => show('focus'), true);
    field.addEventListener('click', () => show('click'), true);
  }
}

async function reportLoginForms() {
  combos = getAllCombinations(detectInputs());
  const fillable = combos.filter((c) => c.username || c.password);
  console.debug('OpenValut: detected', combos.length, 'combos,', fillable.length, 'fillable');
  const unfilled = fillable.filter(
    (c) => !(c.password && filledPasswords.has(c.password)),
  );
  if (unfilled.length === 0) {
    console.debug('OpenValut: no unfilled login forms');
    return;
  }

  for (const combo of unfilled) {
    attachFocusPicker(combo);
  }

  let result;
  try {
    result = await fetchMatchesForCombo(unfilled[0]);
    console.debug('OpenValut: initial matches', result.matches.length, 'locked:', result.locked);
    if (result.locked) {
      return;
    }
    if (result.matches.length === 0) {
      return;
    }
  } catch (e) {
    console.warn('OpenValut: initial match fetch failed:', e);
    return;
  }

  const matches = result.matches;
  if (matches.length === 1 && matches[0].quality === 'host' && settings.unique) {
    try {
      const credential = await sendMessage('getCredential', {
        fileId: matches[0].fileId,
        entryUuid: matches[0].entryUuid,
      });
      const target = comboFromActiveElement() || unfilled[0];
      await fillCombo(target, credential);
    } catch (e) {
      console.warn('OpenValut credential fill failed:', e);
    }
  } else {
    showInlinePicker(unfilled[0], matches);
  }
}

// TOTP auto-fill happens at most once per field: overwriting the code again
// and again (the mutation observer re-runs detection on every DOM change, and
// React sites replace the input on input events) made GitHub auto-submit a
// stream of fresh codes and trip its "too many codes submitted" rate limit.
const totpFillTimestamps = new WeakMap(); // field -> epoch ms

function isTotpAlreadyFilled(field) {
  if ((field.value || '').length > 0) {
    // A non-empty code is left alone: never overwrite what the user (or the
    // site) already put in the field.
    return true;
  }
  const at = totpFillTimestamps.get(field);
  // Cooldown: if the site clears the field right after we filled it (failed
  // submit / re-render), do not instantly refill and re-trigger the loop.
  return at != null && Date.now() - at < 10000;
}

function totpComboFields(combo) {
  return combo.totpInputs && combo.totpInputs.length > 0
    ? combo.totpInputs
    : [combo.totp];
}

async function reportTotpFields() {
  if (settings.totp === false) {
    return;
  }
  const totpCombos = combos.filter((c) => c.totp || (c.totpInputs && c.totpInputs.length));
  const targets = totpCombos.filter((c) =>
    totpComboFields(c).some((f) => !isTotpAlreadyFilled(f)),
  );
  if (targets.length === 0) {
    return;
  }
  const matchUrl = window.self !== window.top && document.referrer
    ? document.referrer
    : location.href;
  try {
    const data = await sendMessage('matchEntries', { url: matchUrl, limit: 5 });
    const matches = (data && data.matches) || [];
    for (const match of matches) {
      try {
        const totp = await sendMessage('getTotp', {
          fileId: match.fileId,
          entryUuid: match.entryUuid,
        });
        for (const combo of targets) {
          await fillTotpCombo(combo, totp.code);
          for (const field of totpComboFields(combo)) {
            totpFillTimestamps.set(field, Date.now());
          }
        }
        return;
      } catch (e) {
        // Try the next match.
      }
    }
  } catch (e) {
    console.warn('OpenValut TOTP fill failed:', e);
  }
}

function runDetection() {
  if (document.visibilityState === 'hidden') {
    return;
  }
  reportLoginForms();
  reportTotpFields();
  detectAndAttachSaveListeners();
}

// ---------------------------------------------------------------------
// Inline picker for multiple matches
// ---------------------------------------------------------------------

const OPENVALUT_LOCK_SVG =
  '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" ' +
  'stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
  'stroke-linejoin="round" aria-hidden="true">' +
  '<rect x="4" y="11" width="16" height="10" rx="2"/>' +
  '<path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>';

// Picker styles are injected into the shadow root as a copy of the rules
// that used to live in content.css — content-script CSS cannot reach inside
// the shadow tree. Theme variables and font-family stay on the host element
// (content.css) and inherit through the shadow boundary.
const PICKER_CSS = `
  .openvalut-picker-box {
    box-sizing: border-box;
    min-width: 200px;
    padding: 6px;
    background: var(--p-bg);
    border: 1px solid var(--p-border);
    border-radius: 10px;
    box-shadow: var(--p-shadow);
    color: var(--p-text);
    font-size: 13px;
    line-height: 1.4;
  }
  .openvalut-picker-title {
    padding: 4px 8px 6px;
    margin-bottom: 4px;
    border-bottom: 1px solid var(--p-border);
    font-size: 12px;
    font-weight: 700;
    letter-spacing: 0.02em;
    color: var(--p-muted);
    text-transform: uppercase;
  }
  .openvalut-picker-row {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 34px;
    padding: 6px 10px;
    overflow: hidden;
    border-radius: 7px;
    color: var(--p-text);
    white-space: nowrap;
    cursor: pointer;
    transition: background-color 120ms ease;
  }
  .openvalut-picker-row:hover,
  .openvalut-picker-row:focus-visible,
  .openvalut-picker-row.openvalut-picker-row-active {
    background: var(--p-hover);
    outline: none;
  }
  .openvalut-picker-row + .openvalut-picker-row {
    margin-top: 2px;
  }
  .openvalut-picker-lock {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    color: var(--p-primary);
  }
  @media (prefers-reduced-motion: reduce) {
    .openvalut-picker-row {
      transition-duration: 0.01ms !important;
    }
  }
`;

function showInlinePicker(combo, matches, options = {}) {
  // Replace any picker that is still open, disposing its document listeners.
  if (inlinePickerCleanup) {
    inlinePickerCleanup();
  }
  const existing = document.querySelector('#openvalut-inline-picker');
  if (existing) {
    existing.remove();
  }
  const anchor = combo.password || combo.username;
  if (!anchor) {
    return;
  }
  // The picker body lives in a shadow root so site stylesheets (global
  // resets, !important overflow rules, hidden scrollbars — all common on
  // login pages) cannot break its scrolling or layout. The host div stays in
  // the light DOM so the existing open-picker checks and cleanup queries
  // keep working.
  const wrapper = document.createElement('div');
  wrapper.id = 'openvalut-inline-picker';
  const inIframe = window.self !== window.top;
  // Use fixed positioning inside iframes so the picker is not clipped by the
  // iframe's own overflow/hidden bounds or small dimensions.
  wrapper.style.position = inIframe ? 'fixed' : 'absolute';
  wrapper.style.zIndex = '2147483647';
  wrapper.style.boxSizing = 'border-box';
  wrapper.style.overflowY = 'auto';
  wrapper.style.overscrollBehavior = 'contain';

  const shadow = wrapper.attachShadow({ mode: 'open' });
  const style = document.createElement('style');
  style.textContent = PICKER_CSS;
  shadow.appendChild(style);
  const box = document.createElement('div');
  box.className = 'openvalut-picker-box';
  shadow.appendChild(box);

  const title = document.createElement('div');
  title.textContent = 'OpenValut';
  title.className = 'openvalut-picker-title';
  box.appendChild(title);

  const rows = [];
  let activeRow = -1;
  function setActiveRow(index) {
    if (rows.length === 0) {
      return;
    }
    activeRow = (index + rows.length) % rows.length;
    rows.forEach((row, i) =>
      row.classList.toggle('openvalut-picker-row-active', i === activeRow),
    );
    const row = rows[activeRow];
    if (typeof row.scrollIntoView === 'function') {
      try {
        row.scrollIntoView({ block: 'nearest' });
      } catch (e) {
        // Some engines (and jsdom) lack scrolling; highlighting still works.
      }
    }
  }
  function addRow(row) {
    row.addEventListener('pointerenter', () => setActiveRow(rows.indexOf(row)));
    rows.push(row);
    box.appendChild(row);
  }

  if (options.locked) {
    const row = document.createElement('div');
    row.className = 'openvalut-picker-row';
    row.innerHTML =
      '<span class="openvalut-picker-lock" aria-hidden="true">' +
      OPENVALUT_LOCK_SVG +
      '</span><span>密码库已锁定，点击解锁</span>';
    row.title = '点击打开 OpenValut 应用解锁密码库';
    row.setAttribute('role', 'button');
    row.tabIndex = 0;
    row.addEventListener('click', async () => {
      try {
        const result = await sendMessage('openAppVault');
        if (result && result.opened) {
          showToast('OpenValut 已解锁，请重新点击输入框选择条目');
        } else if (result && result.focused) {
          showToast(
            (result && result.reason) ||
              'OpenValut 已在运行，已切换到桌面窗口，请解锁密码库',
          );
        } else if (result && result.launched) {
          showToast('已打开 OpenValut，请在桌面端解锁密码库');
        } else {
          showToast(
            (result && result.reason) ||
              '未能唤起 OpenValut，请手动打开应用并解锁',
          );
        }
      } catch (e) {
        console.warn('OpenValut: failed to open app vault:', e);
        showToast('无法连接桌面 OpenValut');
      }
      dismiss();
    });
    row.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        row.click();
      }
    });
    addRow(row);
  } else {
    for (const match of matches) {
      const row = document.createElement('div');
      row.className = 'openvalut-picker-row';
      row.textContent = match.label || match.username || '(no title)';
      row.title = `${match.username || ''} — ${match.fileName}`;
      row.addEventListener('click', async () => {
        try {
          const credential = await sendMessage('getCredential', {
            fileId: match.fileId,
            entryUuid: match.entryUuid,
          });
          await fillCombo(combo, credential);
          dismiss();
        } catch (e) {
          console.warn('Failed to fill credential:', e);
        }
      });
      addRow(row);
    }
  }

  const rect = anchor.getBoundingClientRect();
  const pickerWidth = 240;
  const margin = 8;
  const maxListHeight = 260;
  wrapper.style.width = `${pickerWidth}px`;

  // Measure the real height off-screen first: guessing it (the old code
  // estimated 220px while CSS allowed 260px) made the clamping math land the
  // picker on top of the input field.
  wrapper.style.left = '-10000px';
  wrapper.style.top = '0';
  wrapper.style.visibility = 'hidden';
  document.body.appendChild(wrapper);

  let placeAbove = false;
  if (inIframe) {
    // Inside an iframe the picker cannot escape the iframe's box, so cap its
    // height to the space actually available on one side of the field and
    // keep it clear of the field itself.
    const spaceBelow = window.innerHeight - rect.bottom - margin;
    const spaceAbove = rect.top - margin;
    placeAbove = spaceBelow < 120 && spaceAbove > spaceBelow;
    const space = placeAbove ? spaceAbove : spaceBelow;
    wrapper.style.maxHeight = `${Math.max(Math.min(maxListHeight, space), 60)}px`;
  } else {
    wrapper.style.maxHeight = `${maxListHeight}px`;
  }
  const pickerHeight = wrapper.offsetHeight;

  let left;
  let top;
  if (inIframe) {
    // Fixed positioning inside the iframe: coordinates are viewport-relative.
    left = rect.left;
    if (left + pickerWidth > window.innerWidth - margin) {
      left = window.innerWidth - pickerWidth - margin;
    }
    top = placeAbove ? rect.top - pickerHeight - margin : rect.bottom + margin;
    if (top < margin) {
      top = margin;
    }
    if (left < margin) {
      left = margin;
    }
  } else {
    left = window.scrollX + rect.right + margin;
    if (left + pickerWidth > window.scrollX + window.innerWidth) {
      left = window.scrollX + rect.left - pickerWidth - margin;
    }
    top = window.scrollY + rect.top;
    const maxTop = window.scrollY + window.innerHeight - pickerHeight - margin;
    if (top > maxTop) {
      top = maxTop;
    }
    if (top < window.scrollY + margin) {
      top = window.scrollY + margin;
    }
    if (left < window.scrollX + margin) {
      left = window.scrollX + margin;
    }
  }
  wrapper.style.left = `${left}px`;
  wrapper.style.top = `${top}px`;
  wrapper.style.visibility = '';
  console.debug('OpenValut: inline picker appended');

  // Keyboard navigation: sites may cancel wheel/touch scrolling globally, so
  // ↑/↓ + Enter must work as well. Enter only takes over the key once the
  // user has moved through the list with the arrows.
  function onPickerKeydown(event) {
    if (rows.length === 0) {
      return;
    }
    const target = event.target;
    const comboFields = [combo.username, combo.password];
    if (!comboFields.includes(target) && !wrapper.contains(target)) {
      return;
    }
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      event.stopPropagation();
      setActiveRow(activeRow < 0 ? 0 : activeRow + 1);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      event.stopPropagation();
      setActiveRow(activeRow < 0 ? rows.length - 1 : activeRow - 1);
    } else if (event.key === 'Enter' && activeRow >= 0) {
      event.preventDefault();
      event.stopPropagation();
      rows[activeRow].click();
    }
  }
  document.addEventListener('keydown', onPickerKeydown, true);

  // Close on a later outside press or on Escape — but never on the same click
  // that opened the picker. Opening happens on click/focus, so the matching
  // pointerdown has already fired by the time this listener exists; clicking
  // a row lands inside the wrapper and keeps the picker open until the row's
  // own click handler runs.
  let closed = false;
  function dismiss() {
    if (closed) {
      return;
    }
    closed = true;
    inlinePickerCleanup = null;
    wrapper.remove();
    document.removeEventListener(downEvent, closeOnOutsideDown, true);
    document.removeEventListener('keydown', closeOnEscape, true);
    document.removeEventListener('keydown', onPickerKeydown, true);
  }
  function closeOnOutsideDown(event) {
    if (!wrapper.contains(event.target)) {
      dismiss();
    }
  }
  function closeOnEscape(event) {
    if (event.key === 'Escape') {
      dismiss();
    }
  }
  const downEvent = window.PointerEvent ? 'pointerdown' : 'mousedown';
  document.addEventListener(downEvent, closeOnOutsideDown, true);
  document.addEventListener('keydown', closeOnEscape, true);
  inlinePickerCleanup = dismiss;
}

// ---------------------------------------------------------------------
// Save prompt for signup / password-change forms
// ---------------------------------------------------------------------

const savePromptsShown = new Map();
const saveListenerForms = new WeakSet();
const SAVE_BANNER_ID = 'openvalut-save-banner';

function getDomain() {
  return location.hostname;
}

function getCurrentUrl() {
  return location.href;
}

function getVisibleInputsInScope(scope) {
  return collectInputs(scope || document.body, []).filter(
    (el) =>
      !el.disabled &&
      el.getAttribute('type') !== 'hidden' &&
      isVisible(el),
  );
}

function getFormPasswordInputs(form) {
  return getVisibleInputsInScope(form).filter(
    (el) => (el.getAttribute('type') || '').toLowerCase() === 'password',
  );
}

function fieldAutocomplete(field) {
  return (field.getAttribute('autocomplete') || '').toLowerCase();
}

function isNewPasswordField(field) {
  return fieldAutocomplete(field) === 'new-password';
}

function isCurrentPasswordField(field) {
  return fieldAutocomplete(field) === 'current-password';
}

function isConfirmPasswordField(field) {
  const name = (field.name || '').toLowerCase();
  const id = (field.id || '').toLowerCase();
  const placeholder = (field.getAttribute('placeholder') || '').toLowerCase();
  const auto = fieldAutocomplete(field);
  return (
    auto.includes('confirm') ||
    name.includes('confirm') ||
    name.includes('repeat') ||
    name.includes('retype') ||
    name.includes('again') ||
    name.includes('verify') ||
    name.includes('verification') ||
    id.includes('confirm') ||
    id.includes('repeat') ||
    placeholder.includes('confirm') ||
    placeholder.includes('repeat')
  );
}

function classifySaveForm(passwordFields) {
  if (!passwordFields || passwordFields.length === 0) {
    return null;
  }
  const hasNew = passwordFields.some(isNewPasswordField);
  const hasCurrent = passwordFields.some(isCurrentPasswordField);
  if (hasCurrent && hasNew) {
    return 'passwordChange';
  }
  if (hasNew) {
    return 'signup';
  }
  if (passwordFields.length >= 2) {
    const confirmCount = passwordFields.filter(isConfirmPasswordField).length;
    const nonConfirm = passwordFields.filter((f) => !isConfirmPasswordField(f)).length;
    if (confirmCount > 0 && nonConfirm > 0) {
      return 'signup';
    }
  }
  return null;
}

function findUsernameField(form) {
  const inputs = getVisibleInputsInScope(form);
  const textLike = inputs.filter((el) => {
    const type = (el.getAttribute('type') || 'text').toLowerCase();
    return (
      ['text', 'email', 'tel', 'username'].includes(type) &&
      !isSearchField(el)
    );
  });
  const byAutocomplete = textLike.find((el) => {
    const auto = fieldAutocomplete(el);
    return (
      auto === 'username' ||
      auto === 'email' ||
      auto.includes('username') ||
      auto.includes('email')
    );
  });
  if (byAutocomplete) {
    return byAutocomplete;
  }
  const password = inputs.find(
    (el) => (el.getAttribute('type') || '').toLowerCase() === 'password',
  );
  if (!password) {
    return null;
  }
  const idx = inputs.indexOf(password);
  for (let i = idx - 1; i >= 0; i--) {
    const el = inputs[i];
    if (textLike.includes(el)) {
      return el;
    }
  }
  return null;
}

function getSignupPassword(form) {
  const pws = getFormPasswordInputs(form);
  const preferred = pws.find(
    (f) => isNewPasswordField(f) && !isConfirmPasswordField(f),
  );
  if (preferred) {
    return preferred;
  }
  return pws.find((f) => !isConfirmPasswordField(f)) || pws[0];
}

function getNewPasswordForChange(form) {
  const pws = getFormPasswordInputs(form);
  return (
    pws.find((f) => isNewPasswordField(f) && !isConfirmPasswordField(f)) ||
    pws.find((f) => !isCurrentPasswordField(f) && !isConfirmPasswordField(f)) ||
    null
  );
}

function buildSavePromptKey(domain, username) {
  return `${domain}|${username || ''}`;
}

function removeExistingSaveBanner() {
  const existing = document.getElementById(SAVE_BANNER_ID);
  if (existing) {
    existing.remove();
  }
}

function notifyShouldSave(type, info) {
  const method =
    type === 'signup' ? 'shouldSaveCredential' : 'shouldUpdateCredential';
  sendMessage(method, {
    url: info.url,
    username: info.username,
    domain: getDomain(),
  }).catch((e) => {
    console.debug('OpenValut should-save notification failed:', e);
  });
}

async function saveCredentialToHost({ type, username, password, url }) {
  await sendMessage('openAppVault').catch(() => {});
  const title = (document.title || getDomain()).trim();

  // Save into an existing entry for this URL whenever one exists (same
  // username preferred, otherwise the first match), so repeated logins do not
  // pile up duplicate entries. A new entry is only created when nothing
  // matches. This also updates the stored password when a login password
  // changes on the site.
  const data = await sendMessage('matchEntries', { url, limit: 10 });
  const matches = (data && data.matches) || [];
  const normalized = (v) => (v || '').toLowerCase();
  const match =
    matches.find((m) => normalized(m.username) === normalized(username)) ||
    matches.find((m) => m.entryUuid && m.fileId) ||
    null;
  if (match) {
    await sendMessage('updateEntry', {
      fileId: match.fileId,
      entryUuid: match.entryUuid,
      title,
      username,
      password,
      url,
    });
    return;
  }

  const vaults = await sendMessage('listVaults');
  const vault = vaults && vaults.vaults && vaults.vaults[0];
  if (!vault) {
    throw new Error('没有已解锁的密码库');
  }
  await sendMessage('createEntry', {
    fileId: vault.path,
    title,
    username,
    password,
    url,
  });
}

function showToast(message, durationMs = 3000) {
  const existing = document.getElementById('openvalut-toast');
  if (existing) {
    existing.remove();
  }

  const toast = document.createElement('div');
  toast.id = 'openvalut-toast';
  toast.setAttribute('role', 'status');
  toast.textContent = message;
  document.body.appendChild(toast);

  setTimeout(() => {
    toast.classList.add('openvalut-toast-hide');
    setTimeout(() => toast.remove(), 300);
  }, durationMs);
}

function showSaveBanner({ type, username, password, url }) {
  const domain = getDomain();
  const key = buildSavePromptKey(domain, username);
  if (savePromptsShown.has(key)) {
    return;
  }
  savePromptsShown.set(key, true);
  removeExistingSaveBanner();

  const banner = document.createElement('div');
  banner.id = SAVE_BANNER_ID;
  banner.setAttribute('role', 'dialog');
  banner.setAttribute('aria-label', '保存到 OpenValut');

  const title = document.createElement('div');
  title.className = 'openvalut-save-title';
  title.textContent = '是否保存到 OpenValut？';

  const meta = document.createElement('div');
  meta.className = 'openvalut-save-meta';
  meta.textContent = `${domain}${username ? ' · ' + username : ''}`;

  const actions = document.createElement('div');
  actions.className = 'openvalut-save-actions';

  const saveBtn = document.createElement('button');
  saveBtn.className = 'openvalut-btn openvalut-btn-primary';
  saveBtn.textContent = '保存';

  const ignoreBtn = document.createElement('button');
  ignoreBtn.className = 'openvalut-btn openvalut-btn-secondary';
  ignoreBtn.textContent = '忽略';

  actions.appendChild(ignoreBtn);
  actions.appendChild(saveBtn);
  banner.appendChild(title);
  banner.appendChild(meta);
  banner.appendChild(actions);
  document.body.appendChild(banner);

  ignoreBtn.addEventListener('click', () => removeExistingSaveBanner());
  saveBtn.addEventListener('click', async () => {
    saveBtn.disabled = true;
    saveBtn.textContent = '保存中…';
    try {
      await saveCredentialToHost({ type, username, password, url });
      removeExistingSaveBanner();
    } catch (e) {
      console.warn('OpenValut save failed:', e);
      saveBtn.disabled = false;
      saveBtn.textContent = '保存';
      let errorEl = banner.querySelector('.openvalut-save-error');
      if (!errorEl) {
        errorEl = document.createElement('div');
        errorEl.className = 'openvalut-save-error';
        banner.appendChild(errorEl);
      }
      errorEl.textContent = '保存失败：' + e.message;
    }
  });
}

async function handleFormSubmit(event) {
  const form = event.target;
  if (!form || !saveListenerForms.has(form)) {
    return;
  }
  const passwordFields = getFormPasswordInputs(form);
  const type = classifySaveForm(passwordFields);
  if (!type) {
    return;
  }
  const username = (findUsernameField(form)?.value || '').trim();
  let password = '';
  if (type === 'passwordChange') {
    const newField = getNewPasswordForChange(form);
    password = newField ? newField.value : '';
  } else {
    password = getSignupPassword(form).value;
  }
  if (!password) {
    return;
  }
  const url = getCurrentUrl();

  // Ask the host whether this credential is already in an unlocked vault.
  // Only prompt to save when there is no matching entry.
  try {
    const result = await sendMessage('checkEntryExists', { url, username });
    if (result && result.exists) {
      console.debug('OpenValut: credential already exists, skipping save prompt');
      return;
    }
  } catch (e) {
    // If the vault is locked or the host is unreachable we cannot determine
    // existence; fall through and let the user decide whether to save.
    console.debug('OpenValut: checkEntryExists failed, showing save prompt anyway:', e);
  }

  notifyShouldSave(type, { username, password, url });
  showSaveBanner({ type, username, password, url });
}

function detectAndAttachSaveListeners() {
  if (!document.body) {
    return;
  }
  for (const form of document.querySelectorAll('form')) {
    if (saveListenerForms.has(form)) {
      continue;
    }
    const passwordFields = getFormPasswordInputs(form);
    if (passwordFields.length === 0) {
      continue;
    }
    const type = classifySaveForm(passwordFields);
    if (!type) {
      continue;
    }
    saveListenerForms.add(form);
    form.addEventListener('submit', handleFormSubmit, true);
  }
}

// ---------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------

function main() {
  if (initialized) {
    return;
  }
  initialized = true;
  // Marker for debugging: lets users/test scripts verify the content script
  // reached this frame (top-level or iframe). Content scripts run in an
  // isolated JS world, so a bare `window.x = true` is not visible to the
  // page console; use a DOM attribute instead (avoids CSP inline-script bans).
  window.__openvalutContentScriptInjected = true;
  if (document.documentElement) {
    document.documentElement.dataset.openvalutContentScript = 'loaded';
  }
  console.log('OpenValut: content script loaded');
  loadSettings().then(runDetection);

  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && changes[SETTINGS_KEY]) {
      settings = { ...DEFAULT_SETTINGS, ...(changes[SETTINGS_KEY].newValue || {}) };
      runDetection();
    }
  });

  // Re-check when the DOM changes, in case the page renders the form late or
  // swaps it (SPA navigation, modal login dialogs).
  const observer = new MutationObserver((records) => {
    if (
      document.visibilityState === 'hidden' ||
      !mutationNeedsDetection(records)
    ) {
      return;
    }
    clearTimeout(recheckTimer);
    recheckTimer = setTimeout(runDetection, 500);
  });
  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['style', 'class'],
  });
}

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', main);
  } else {
    main();
  }
})();
