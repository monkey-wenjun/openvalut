'use strict';

(function (root) {
  if (root.OpenValutDom) {
    return;
  }

  function getShadowRoot(element) {
    try {
      return element.shadowRoot || null;
    } catch (_) {
      return null;
    }
  }

  function collectInputs(searchRoot, output = []) {
    if (!searchRoot) {
      return output;
    }
    if (
      searchRoot.nodeType === root.Node.ELEMENT_NODE &&
      searchRoot.matches('input')
    ) {
      output.push(searchRoot);
    }
    const walker = searchRoot.ownerDocument.createTreeWalker(
      searchRoot,
      root.NodeFilter.SHOW_ELEMENT,
    );
    let element = walker.nextNode();
    while (element) {
      if (element.matches('input')) {
        output.push(element);
      }
      const shadow = getShadowRoot(element);
      if (shadow) {
        collectInputs(shadow, output);
      }
      element = walker.nextNode();
    }
    return output;
  }

  function containsCredentialFields(node) {
    if (!node || node.nodeType !== root.Node.ELEMENT_NODE) {
      return false;
    }
    if (node.matches('input, form')) {
      return true;
    }
    return node.querySelector('input, form') !== null;
  }

  function mutationNeedsDetection(records) {
    return records.some((record) => {
      if (record.type === 'attributes') {
        return containsCredentialFields(record.target);
      }
      return [...record.addedNodes, ...record.removedNodes].some(
        containsCredentialFields,
      );
    });
  }

  root.OpenValutDom = Object.freeze({
    collectInputs,
    mutationNeedsDetection,
  });
})(globalThis);
