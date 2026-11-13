document.addEventListener('DOMContentLoaded', async () => {
  const statusEl = document.getElementById('status');
  const autoFillUniqueInput = document.getElementById('auto-fill-unique');
  const autoFillTotpInput = document.getElementById('auto-fill-totp');
  const saveBtn = document.getElementById('save-btn');

  const AUTO_FILL_KEY = 'autoFillSettings';

  function showStatus(text, type = 'info') {
    statusEl.textContent = text;
    statusEl.className = `status ${type}`;
  }

  function clearStatus() {
    statusEl.className = 'status';
    statusEl.textContent = '';
  }

  async function loadSettings() {
    try {
      const result = await chrome.storage.local.get([AUTO_FILL_KEY]);
      const autoFill = result[AUTO_FILL_KEY] || {};
      autoFillUniqueInput.checked = autoFill.unique !== false;
      autoFillTotpInput.checked = autoFill.totp !== false;
    } catch (e) {
      showStatus('加载设置失败：' + e.message, 'error');
    }
  }

  saveBtn.addEventListener('click', async () => {
    clearStatus();
    try {
      await chrome.storage.local.set({
        [AUTO_FILL_KEY]: {
          unique: autoFillUniqueInput.checked,
          totp: autoFillTotpInput.checked,
        },
      });
      showStatus('设置已保存', 'success');
    } catch (e) {
      showStatus('保存失败：' + e.message, 'error');
    }
  });

  await loadSettings();
});
