'use strict';

// Content script that runs at document_start to inject the main-world passkey
// bridge before any page script captures navigator.credentials.create/get.

if (!window.__openvalutPasskeyBridgeInjected) {
  const pageBridgeMethods = globalThis.OpenValutRpc?.pageBridgeMethods;
  const ALLOWED_PASSKEY_METHODS = new Set(
    Array.isArray(pageBridgeMethods)
      ? pageBridgeMethods
      : ['createPasskey', 'getPasskey'],
  );
  window.__openvalutPasskeyBridgeInjected = true;

  const script = document.createElement('script');
  script.src = chrome.runtime.getURL('inject-passkey.js');
  script.onload = () => {
    script.remove();
    console.log('OpenValut: passkey bridge injected at document_start');
  };
  script.onerror = (e) => {
    console.warn('OpenValut: failed to inject passkey bridge', e);
  };
  (document.head || document.documentElement).appendChild(script);

  function sendMessage(method, params, retry = true) {
    return new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({ method, params }, (response) => {
        if (chrome.runtime.lastError) {
          const err = chrome.runtime.lastError.message || '';
          if (retry && err.includes('Could not establish connection')) {
            console.debug('OpenValut passkey: retrying', method, 'after connection error');
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

  window.addEventListener('message', async (event) => {
    if (
      event.source !== window ||
      event.data?.source !== 'openvalut-injected-script'
    ) {
      return;
    }
    const { id, method, payload } = event.data;
    if (
      typeof id !== 'string' ||
      !ALLOWED_PASSKEY_METHODS.has(method) ||
      !payload ||
      typeof payload !== 'object' ||
      Array.isArray(payload)
    ) {
      return;
    }
    try {
      const data = await sendMessage(method, payload);
      window.postMessage(
        {
          source: 'openvalut-content-script',
          id,
          result: data,
        },
        '*',
      );
    } catch (e) {
      window.postMessage(
        {
          source: 'openvalut-content-script',
          id,
          error: e.message || 'Unknown error',
          errorName: e.name || 'NotAllowedError',
          errorCode: e.code,
        },
        '*',
      );
    }
  });
}
