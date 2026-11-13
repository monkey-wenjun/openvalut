'use strict';

// Injected into the page's main JavaScript world so it can override
// navigator.credentials.create/get before GitHub stores references to them.
// It communicates with the OpenValut content script via window.postMessage.

(function () {
  if (window.__openvalutPasskeyBridgeInstalled) {
    return;
  }
  window.__openvalutPasskeyBridgeInstalled = true;

  // Diagnostic marker: `document.documentElement.dataset.openvalutPasskey`
  // (or the page console) confirms this bridge actually loaded in the page.
  try {
    if (document.documentElement) {
      document.documentElement.setAttribute(
        'data-openvalut-passkey',
        'installed',
      );
    }
  } catch (_) {}

  // Sites (e.g. GitHub) feature-detect a platform authenticator BEFORE calling
  // navigator.credentials.create(); when it reports false they route straight
  // to their cross-device QR flow and never invoke create(), so our override
  // and save-confirmation never run. Advertise ourselves as a capable platform
  // authenticator so GitHub calls create() and the passkey is saved into the
  // vault instead of showing the QR code.
  const setPlatformFlag = (name, value) => {
    try {
      PublicKeyCredential[name] = () => Promise.resolve(value);
    } catch (e) {
      console.warn('OpenValut: unable to override PublicKeyCredential.' + name, e);
    }
  };
  setPlatformFlag('isUserVerifyingPlatformAuthenticatorAvailable', true);
  setPlatformFlag('isConditionalMediationAvailable', false);
  if (typeof PublicKeyCredential.isExternalCtap2Supported === 'function') {
    setPlatformFlag('isExternalCtap2Supported', false);
  }

  const originalCreate = navigator.credentials.create.bind(
    navigator.credentials,
  );
  const originalGet = navigator.credentials.get.bind(navigator.credentials);

  function base64UrlToArrayBuffer(value) {
    const padded = value + ('='.repeat((4 - (value.length % 4)) % 4));
    const binary = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  function arrayBufferToBase64Url(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  }

  function makeCredentialResponse(attestation) {
    const rawId = base64UrlToArrayBuffer(attestation.rawId);
    const response = {
      clientDataJSON: base64UrlToArrayBuffer(
        attestation.response.clientDataJSON,
      ),
      attestationObject: base64UrlToArrayBuffer(
        attestation.response.attestationObject,
      ),
      getClientExtensionResults: () => ({}),
      getAuthenticatorData: () =>
        base64UrlToArrayBuffer(attestation.response.attestationObject).slice(
          0,
          37,
        ),
      getPublicKey: () => null,
      getPublicKeyAlgorithm: () => -7,
      transports: attestation.response.transports || ['internal'],
    };
    return {
      id: attestation.id,
      rawId,
      response,
      type: 'public-key',
      authenticatorAttachment: attestation.authenticatorAttachment,
      getClientExtensionResults: () => ({}),
    };
  }

  function makeAssertionResponse(assertion) {
    const rawId = base64UrlToArrayBuffer(assertion.rawId);
    const response = {
      clientDataJSON: base64UrlToArrayBuffer(
        assertion.response.clientDataJSON,
      ),
      authenticatorData: base64UrlToArrayBuffer(
        assertion.response.authenticatorData,
      ),
      signature: base64UrlToArrayBuffer(assertion.response.signature),
      userHandle: assertion.response.userHandle
        ? base64UrlToArrayBuffer(assertion.response.userHandle)
        : null,
      getClientExtensionResults: () => ({}),
    };
    return {
      id: assertion.id,
      rawId,
      response,
      type: 'public-key',
      authenticatorAttachment: assertion.authenticatorAttachment,
      getClientExtensionResults: () => ({}),
    };
  }

  function askContentScript(method, payload) {
    return new Promise((resolve, reject) => {
      const id =
        'openvalut-' +
        Math.random().toString(36).slice(2) +
        '-' +
        Date.now();
      const handler = (event) => {
        if (
          event.source !== window ||
          event.data?.source !== 'openvalut-content-script' ||
          event.data?.id !== id
        ) {
          return;
        }
        window.removeEventListener('message', handler);
        if (event.data.error) {
          const err = new DOMException(
            event.data.error,
            event.data.errorName || 'NotAllowedError',
          );
          if (event.data.errorCode) {
            err.code = event.data.errorCode;
          }
          reject(err);
        } else {
          resolve(event.data.result);
        }
      };
      window.addEventListener('message', handler);
      window.postMessage(
        {
          source: 'openvalut-injected-script',
          id,
          method,
          payload,
        },
        '*',
      );
    });
  }

  function isArrayBuffer(value) {
    return value instanceof ArrayBuffer || value instanceof Uint8Array;
  }

  function arrayBufferToBase64Url(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary)
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
  }

  function normalizePublicKeyOptions(publicKey) {
    const copy = JSON.parse(JSON.stringify(publicKey, (key, value) => {
      if (isArrayBuffer(value)) {
        return arrayBufferToBase64Url(value);
      }
      return value;
    }));
    // JSON.stringify does not handle ArrayBuffer/Uint8Array by default, so we
    // need a manual pass for the fields WebAuthn uses.
    if (publicKey.challenge && isArrayBuffer(publicKey.challenge)) {
      copy.challenge = arrayBufferToBase64Url(publicKey.challenge);
    }
    if (publicKey.user && publicKey.user.id && isArrayBuffer(publicKey.user.id)) {
      copy.user.id = arrayBufferToBase64Url(publicKey.user.id);
    }
    if (Array.isArray(publicKey.excludeCredentials)) {
      copy.excludeCredentials = publicKey.excludeCredentials.map((desc) => ({
        ...desc,
        id: isArrayBuffer(desc.id) ? arrayBufferToBase64Url(desc.id) : desc.id,
      }));
    }
    if (Array.isArray(publicKey.allowCredentials)) {
      copy.allowCredentials = publicKey.allowCredentials.map((desc) => ({
        ...desc,
        id: isArrayBuffer(desc.id) ? arrayBufferToBase64Url(desc.id) : desc.id,
      }));
    }
    return copy;
  }

  async function openvalutCreate(options) {
    if (!options || !options.publicKey) {
      return originalCreate(options);
    }
    const publicKey = normalizePublicKeyOptions(options.publicKey);
    const rpName =
      publicKey.rp && publicKey.rp.name ? publicKey.rp.name : publicKey.rp.id;
    const userName =
      publicKey.user && publicKey.user.name ? publicKey.user.name : '';
    const confirmed = confirm(
      'OpenValut\n是否将 ' +
        rpName +
        ' 的 passkey 保存到密码库？\n账号：' +
        userName,
    );
    if (!confirmed) {
      throw new DOMException(
        'User cancelled passkey registration',
        'NotAllowedError',
      );
    }
    try {
      const result = await askContentScript('createPasskey', {
        options: publicKey,
      });
      console.log('OpenValut: created passkey for', publicKey.rp.id);
      return makeCredentialResponse(result.attestation);
    } catch (e) {
      console.log(
        'OpenValut: unable to create passkey in vault, falling back to system authenticator:',
        e.message || e,
      );
      return originalCreate(options);
    }
  }

  async function openvalutGet(options) {
    if (!options || !options.publicKey) {
      return originalGet(options);
    }
    // Conditional UI (autofill dropdown) is handled by the browser's native
    // authenticator; our software authenticator cannot participate there yet.
    if (options.mediation === 'conditional') {
      return originalGet(options);
    }
    const publicKey = normalizePublicKeyOptions(options.publicKey);
    try {
      const result = await askContentScript('getPasskey', {
        options: publicKey,
      });
      console.log('OpenValut: got passkey assertion for', publicKey.rpId);
      return makeAssertionResponse(result.assertion);
    } catch (e) {
      const msg = e.message || String(e);
      console.warn('OpenValut: getPasskey failed:', msg);
      // If the host could not be reached or no vault is unlocked, fall back to
      // the system authenticator. If we simply did not find a matching passkey
      // in the vault (NOT_FOUND), do the same instead of failing the page: the
      // credential likely lives in a system/cloud authenticator that we should
      // not block. "no matching passkey" is kept as a message fallback in case
      // the error code is unavailable.
      if (
        e.code === 'NOT_FOUND' ||
        msg.toLowerCase().includes('no matching passkey') ||
        msg.includes('Could not establish connection') ||
        msg.includes('Native host') ||
        msg.includes('No vaults') ||
        msg.includes('unlocked')
      ) {
        console.log('OpenValut: falling back to system authenticator');
        return originalGet(options);
      }
      throw e;
    }
  }

  navigator.credentials.create = openvalutCreate;
  navigator.credentials.get = openvalutGet;

  console.log('OpenValut: injected passkey bridge installed');
})();
