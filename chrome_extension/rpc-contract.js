'use strict';

(function (root) {
  if (root.OpenValutRpc) {
    return;
  }
  const methods = Object.freeze({
    checkEntryExists: 'checkEntryExists',
    closeVault: 'closeVault',
    createEntry: 'createEntry',
    createPasskey: 'createPasskey',
    deleteEntry: 'deleteEntry',
    generatePassword: 'generatePassword',
    getCredential: 'getCredential',
    getPasskey: 'getPasskey',
    getTotp: 'getTotp',
    listPasskeys: 'listPasskeys',
    listVaults: 'listVaults',
    lock: 'lock',
    matchEntries: 'matchEntries',
    openAppVault: 'openAppVault',
    ping: 'ping',
    updateEntry: 'updateEntry',
  });

  root.OpenValutRpc = Object.freeze({
    methods,
    contentScriptMethods: Object.freeze([
      methods.checkEntryExists,
      methods.createEntry,
      methods.createPasskey,
      methods.getCredential,
      methods.getPasskey,
      methods.getTotp,
      methods.listVaults,
      methods.matchEntries,
      methods.openAppVault,
      methods.updateEntry,
    ]),
    extensionPageMethods: Object.freeze([
      methods.checkEntryExists,
      methods.createEntry,
      methods.deleteEntry,
      methods.generatePassword,
      methods.getCredential,
      methods.getTotp,
      methods.listVaults,
      methods.lock,
      methods.matchEntries,
      methods.openAppVault,
      methods.updateEntry,
    ]),
    pageBridgeMethods: Object.freeze([
      methods.createPasskey,
      methods.getPasskey,
    ]),
  });
})(globalThis);
