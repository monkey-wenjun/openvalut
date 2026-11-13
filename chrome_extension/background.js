importScripts('rpc-contract.js');

const HOST_NAME = 'design.codeux.openvalut';
const RPC = OpenValutRpc.methods;

let nativePort = null;
let isHostReachable = false;
const pendingRequests = new Map();
let nextRequestId = 1;
const REQUEST_TIMEOUT_MS = 8000;
const CONTENT_SCRIPT_METHODS = new Set(OpenValutRpc.contentScriptMethods);
const EXTENSION_PAGE_METHODS = new Set(OpenValutRpc.extensionPageMethods);

function resetNativePort() {
  if (nativePort) {
    try {
      nativePort.disconnect();
    } catch (_) {}
  }
  nativePort = null;
  isHostReachable = false;
}

function connectNativeHost() {
  if (nativePort) {
    return nativePort;
  }
  try {
    nativePort = chrome.runtime.connectNative(HOST_NAME);
    // Note: isHostReachable is only confirmed once a ping succeeds.

    nativePort.onMessage.addListener((message) => {
      const requestId = message.requestId;
      if (!requestId) {
        console.debug('Native host message without requestId:', message);
        return;
      }
      const handler = pendingRequests.get(requestId);
      if (!handler) {
        console.debug('No pending handler for', requestId);
        return;
      }
      if (handler.timeoutId) {
        clearTimeout(handler.timeoutId);
      }
      pendingRequests.delete(requestId);
      if (message.ok) {
        handler.resolve(message.data);
      } else {
        const err = new Error(message.error || 'Host error');
        if (message.code) {
          err.code = message.code;
        }
        handler.reject(err);
      }
    });

    nativePort.onDisconnect.addListener(() => {
      const error = chrome.runtime.lastError;
      if (error) {
        console.warn('Native host disconnected:', error.message);
      }
      // Reject every pending request.
      for (const [id, handler] of pendingRequests) {
        if (handler.timeoutId) {
          clearTimeout(handler.timeoutId);
        }
        handler.reject(
          new Error(error?.message || 'Native host disconnected')
        );
      }
      pendingRequests.clear();
      nativePort = null;
      isHostReachable = false;
    });
  } catch (e) {
    resetNativePort();
    console.error('Failed to connect native host:', e);
  }
  return nativePort;
}

function sendRequestInternal(method, params = {}) {
  return new Promise((resolve, reject) => {
    const port = connectNativeHost();
    if (!port) {
      reject(new Error('Native host not available. Is the host installed?'));
      return;
    }

    const requestId = `req_${nextRequestId++}`;
    const timeoutId = setTimeout(() => {
      pendingRequests.delete(requestId);
      reject(new Error('Native host request timed out'));
    }, REQUEST_TIMEOUT_MS);
    pendingRequests.set(requestId, { resolve, reject, timeoutId });
    port.postMessage({ requestId, method, params });
  });
}

async function sendRequest(method, params = {}, allowRetry = true) {
  try {
    return await sendRequestInternal(method, params);
  } catch (e) {
    if (allowRetry && nativePort) {
      // The port may be stale (service worker was killed and the native
      // process lingered). Force a reconnect and try once more.
      console.debug('OpenValut: retrying native request after disconnect');
      resetNativePort();
      return await sendRequestInternal(method, params);
    }
    throw e;
  }
}

async function ensureHost() {
  try {
    await sendRequest(RPC.ping, {}, false);
    isHostReachable = true;
    return true;
  } catch (e) {
    isHostReachable = false;
    return false;
  }
}

// Eagerly connect on startup so the native host is ready before the user
// focuses a login field. This fixes the issue where the inline picker only
// appeared after opening the popup first.
connectNativeHost();
ensureHost().catch((e) => console.debug('OpenValut: initial host ping failed', e));

// Lock the vault when the screen locks or the system goes idle-locked.
chrome.idle.onStateChanged.addListener((state) => {
  if (state === 'locked') {
    sendRequest(RPC.lock).catch((e) => console.warn('Lock failed:', e));
  }
});

// The service worker may be terminated at any time; onSuspend is best-effort.
chrome.runtime.onSuspend.addListener(() => {
  sendRequest(RPC.lock).catch(() => {});
});

function isOwnExtensionPage(sender) {
  try {
    const url = new URL(sender.url || '');
    return url.protocol === 'chrome-extension:' && url.host === chrome.runtime.id;
  } catch (_) {
    return false;
  }
}

function sameOriginUrl(candidate, trustedUrl) {
  if (!candidate) {
    return undefined;
  }
  try {
    const value = new URL(candidate, trustedUrl);
    return value.origin === new URL(trustedUrl).origin ? value.href : undefined;
  } catch (_) {
    return undefined;
  }
}

function validatedRequest(request, sender) {
  if (!request || typeof request.method !== 'string') {
    throw new Error('Invalid extension request');
  }
  const fromContentScript = Boolean(sender.tab);
  const allowed = fromContentScript
    ? CONTENT_SCRIPT_METHODS
    : EXTENSION_PAGE_METHODS;
  if (!allowed.has(request.method)) {
    throw new Error(`Method not allowed from this context: ${request.method}`);
  }
  if (!fromContentScript && !isOwnExtensionPage(sender)) {
    throw new Error('Untrusted extension message sender');
  }

  const params =
    request.params && typeof request.params === 'object'
      ? { ...request.params }
      : {};
  if (!fromContentScript) {
    return { method: request.method, params };
  }

  const frameUrl = sender.url;
  if (!frameUrl || !/^https?:\/\//i.test(frameUrl)) {
    throw new Error('Unsupported content-script origin');
  }
  delete params.topUrl;
  if (request.method === RPC.matchEntries) {
    params.url = frameUrl;
    params.submitUrl = sameOriginUrl(params.submitUrl, frameUrl);
  } else if (
    request.method === RPC.checkEntryExists ||
    request.method === RPC.createEntry
  ) {
    params.url = frameUrl;
  } else if (request.method === RPC.updateEntry && params.url) {
    params.url = frameUrl;
  } else if (
    request.method === RPC.createPasskey ||
    request.method === RPC.getPasskey
  ) {
    params.pageUrl = frameUrl;
  }
  return { method: request.method, params };
}

// Content script and popup messages.
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  (async () => {
    try {
      const validated = validatedRequest(request, sender);
      const data = await sendRequest(validated.method, validated.params);
      sendResponse({ ok: true, data });
    } catch (e) {
      sendResponse({ ok: false, error: e.message });
    }
  })();
  return true; // keep channel open for async response
});
