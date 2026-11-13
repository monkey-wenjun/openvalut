# OpenValut Chrome extension tests

Two levels of verification, both runnable on a Linux machine:

## 1. Logic tests (jsdom)

Run the real `content.js` against synthetic pages and a mocked `chrome.*` API:
basic login fill, search-form exclusion, cross-container combos, sign-up
field skipping, shadow DOM, multi-match picker, TOTP, refill protection and
submitUrl propagation.

```bash
cd chrome_extension/test
npm install   # installs jsdom
node logic_test.js
```

## 2. End-to-end (real Chrome + native host + real KDBX)

`e2e.js` drives a real browser through the whole chain: page → content
script → service worker → native messaging → Dart host → KDBX → fill.

It needs:

- A Chrome build that accepts `--load-extension` (official Google Chrome
  ignores it; use Chrome for Testing or Chromium).
- The native host binary built and the host manifest registered for the
  fixed extension id `hnjmpepmjglmnfifjhomiadmbdpdfkik` (see
  the deb's native-messaging host registration).
- A local `test.kdbx` at `/tmp/e2e.kdbx` (password `test-password`, one
  GitHub entry) plus a matching vault with two entries at `/tmp/e2e2.kdbx`.

Start Chrome for Testing:

```bash
/path/to/chrome --headless=new --no-sandbox --disable-gpu \
  --user-data-dir=/tmp/openvalut-cft-profile \
  --load-extension=/path/to/openvalut/chrome_extension \
  --remote-debugging-port=9226 about:blank
```

Then:

```bash
cd chrome_extension/test
node e2e.js
```

The browser looks for the native host manifest in the profile's
`NativeMessagingHosts/` directory, so copy
`design.codeux.openvalut.json` there as well when using a custom
`--user-data-dir`.
