document.addEventListener('DOMContentLoaded', async () => {
  const statusEl = document.getElementById('status');
  const unlockSection = document.getElementById('unlock-section');
  const generatorSection = document.getElementById('generator-section');
  const matchesSection = document.getElementById('matches-section');
  const unlockHint = document.getElementById('unlock-hint');
  const unlockBtn = document.getElementById('unlock-btn');
  const lockBtn = document.getElementById('lock-btn');
  const matchesList = document.getElementById('matches-list');

  // Generator controls
  const genLength = document.getElementById('gen-length');
  const genLengthValue = document.getElementById('gen-length-value');
  const genUpper = document.getElementById('gen-upper');
  const genDigits = document.getElementById('gen-digits');
  const genSpecial = document.getElementById('gen-special');
  const genPassword = document.getElementById('gen-password');
  const genCopyBtn = document.getElementById('gen-copy-btn');
  const genRegenBtn = document.getElementById('gen-regen-btn');
  const genFillBtn = document.getElementById('gen-fill-btn');
  const genCreateBtn = document.getElementById('gen-create-btn');
  const genStrength = document.getElementById('gen-strength');
  const strengthBar = document.getElementById('strength-bar');
  const strengthLabel = document.getElementById('strength-label');

  let currentVaults = [];
  let currentTabUrl = '';
  let currentTabId = null;

  function showStatus(text, type = 'info') {
    statusEl.textContent = text;
    statusEl.className = `status ${type}`;
  }

  // Catch anything that would otherwise leave the popup blank.
  window.addEventListener('error', (event) => {
    showStatus(`JS Error: ${event.message}`, 'error');
  });
  window.addEventListener('unhandledrejection', (event) => {
    showStatus(`Error: ${event.reason?.message || event.reason}`, 'error');
  });

  function clearStatus() {
    statusEl.className = 'status';
    statusEl.textContent = '';
  }

  /// Shows a non-native confirmation dialog inside the popup.
  function showConfirmDialog({ title = '确认', message, confirmText = '确定', cancelText = '取消', danger = false }) {
    return new Promise((resolve) => {
      const overlay = document.createElement('div');
      overlay.className = 'confirm-overlay';

      const box = document.createElement('div');
      box.className = 'confirm-box';

      const heading = document.createElement('div');
      heading.className = 'confirm-title';
      heading.textContent = title;

      const body = document.createElement('div');
      body.className = 'confirm-message';
      body.textContent = message;

      const actions = document.createElement('div');
      actions.className = 'confirm-actions';

      const cancelBtn = document.createElement('button');
      cancelBtn.className = 'secondary';
      cancelBtn.textContent = cancelText;
      cancelBtn.addEventListener('click', () => {
        overlay.remove();
        resolve(false);
      });

      const confirmBtn = document.createElement('button');
      confirmBtn.className = danger ? 'danger' : 'primary';
      confirmBtn.textContent = confirmText;
      confirmBtn.addEventListener('click', () => {
        overlay.remove();
        resolve(true);
      });

      actions.appendChild(cancelBtn);
      actions.appendChild(confirmBtn);
      box.appendChild(heading);
      box.appendChild(body);
      box.appendChild(actions);
      overlay.appendChild(box);
      document.body.appendChild(overlay);
    });
  }

  function sendToHost(method, params = {}) {
    return new Promise((resolve, reject) => {
      chrome.runtime.sendMessage({ method, params }, (response) => {
        if (chrome.runtime.lastError) {
          reject(new Error(chrome.runtime.lastError.message));
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

  async function refreshMatches() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (!tab || !tab.url || tab.url.startsWith('chrome://')) {
        showStatus('当前页面无法填充', 'error');
        return;
      }
      currentTabUrl = tab.url;
      currentTabId = tab.id;
      const data = await sendToHost('matchEntries', { url: tab.url, limit: 20 });
      const matches = (data && data.matches) || [];
      renderMatches(matches);
      matchesSection.classList.remove('hidden');
      unlockSection.classList.add('hidden');
      unlockBtn.classList.add('hidden');
    } catch (e) {
      showStatus(e.message, 'error');
      matchesSection.classList.add('hidden');
      unlockSection.classList.remove('hidden');
      unlockBtn.classList.remove('hidden');
      unlockHint.textContent = '请先在桌面 OpenValut 打开并解锁密码库，再刷新本页面。';
    }
  }

  async function openDesktopApp() {
    try {
      unlockBtn.disabled = true;
      unlockHint.textContent = '正在唤起桌面 OpenValut…';
      const result = await sendToHost('openAppVault');
      if (result && result.opened) {
        unlockSection.classList.add('hidden');
        unlockBtn.classList.add('hidden');
        generatorSection.classList.remove('hidden');
        clearStatus();
        await refreshMatches();
        await regeneratePassword();
      } else if (result && result.focused) {
        unlockHint.textContent = result && result.reason
          ? result.reason
          : 'OpenValut 已在运行，已切换到桌面窗口，请解锁密码库后返回刷新本页面。';
      } else if (result && result.launched) {
        unlockHint.textContent = '已打开 OpenValut，请在桌面端解锁密码库后返回刷新本页面。';
      } else {
        unlockHint.textContent = result && result.reason
          ? result.reason
          : '未能唤起桌面 OpenValut，请手动打开应用并解锁密码库。';
      }
    } catch (e) {
      showStatus(e.message, 'error');
      unlockHint.textContent = '无法连接桌面 OpenValut，请确认 Native Host 已安装。';
    } finally {
      unlockBtn.disabled = false;
    }
  }

  unlockBtn.addEventListener('click', openDesktopApp);

  function renderMatches(matches) {
    matchesList.innerHTML = '';
    if (matches.length === 0) {
      const li = document.createElement('li');
      li.className = 'match-empty';
      li.textContent = '当前页面没有匹配条目';
      matchesList.appendChild(li);
      return;
    }
    for (const match of matches) {
      const li = document.createElement('li');
      li.className = 'match-item';
      li.dataset.fileId = match.fileId;
      li.dataset.entryUuid = match.entryUuid;

      const info = document.createElement('div');
      info.className = 'match-info';
      const title = document.createElement('div');
      title.className = 'match-title';
      title.textContent = match.label || match.username || '(无标题)';
      const subtitle = document.createElement('div');
      subtitle.className = 'match-subtitle';
      subtitle.textContent = `${match.username || ''} · ${match.fileName}`;
      info.appendChild(title);
      info.appendChild(subtitle);

      const actions = document.createElement('div');
      actions.className = 'match-actions';

      const fillBtn = document.createElement('button');
      fillBtn.className = 'primary';
      fillBtn.textContent = '填充';
      fillBtn.addEventListener('click', () => fillCredential(match));

      const menuBtn = document.createElement('button');
      menuBtn.className = 'menu-btn';
      menuBtn.textContent = '⋮';
      menuBtn.title = '更多操作';
      menuBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        showMatchDropdown(actions, match, li);
      });

      actions.appendChild(fillBtn);
      actions.appendChild(menuBtn);

      li.appendChild(info);
      li.appendChild(actions);
      matchesList.appendChild(li);
    }
  }

  async function fillCredential(match) {
    try {
      const credential = await sendToHost('getCredential', {
        fileId: match.fileId,
        entryUuid: match.entryUuid,
      });
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      await chrome.scripting.executeScript({
        target: { tabId: tab.id, allFrames: true },
        func: (username, password) => {
          const setValue = async (field, value) => {
            if (!field || field.readOnly) return;
            field.focus();
            await new Promise((resolve) => setTimeout(resolve, 0));
            field.dispatchEvent(new FocusEvent('focus', { bubbles: false }));
            field.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
            field.dispatchEvent(
              new KeyboardEvent('keydown', {
                bubbles: true,
                cancelable: false,
                key: value,
              })
            );
            field.dispatchEvent(
              new InputEvent('beforeinput', {
                bubbles: true,
                cancelable: false,
                inputType: 'insertText',
                data: value,
              })
            );
            field.dispatchEvent(
              new KeyboardEvent('keypress', {
                bubbles: true,
                cancelable: false,
                key: value,
              })
            );
            field.value = value;
            field.dispatchEvent(
              new Event('input', { bubbles: true, cancelable: false })
            );
            field.dispatchEvent(
              new KeyboardEvent('keyup', {
                bubbles: true,
                cancelable: false,
                key: value,
              })
            );
            field.dispatchEvent(
              new Event('change', { bubbles: true, cancelable: false })
            );
            const legacy = (name) => {
              const event = field.ownerDocument.createEvent('Event');
              event.initEvent(name, true, false);
              field.dispatchEvent(event);
            };
            legacy('input');
            legacy('change');
          };

          const passwordFields = Array.from(
            document.querySelectorAll('input[type="password"]')
          ).filter((el) => el.offsetParent !== null && !el.disabled);
          const passwordField = passwordFields[0];
          if (!passwordField) return;

          // Prefer a username field in the same <form> as the password;
          // fall back to any visible text/email input before it in DOM order.
          let usernameField = null;
          const scope = passwordField.closest('form') || document;
          const candidates = Array.from(
            scope.querySelectorAll(
              'input[type="email"], input[type="text"][autocomplete="username"], ' +
                'input[type="text"][autocomplete="email"], input[name*="user" i], ' +
                'input[name*="email" i], input[id*="user" i], input[id*="email" i], ' +
                'input[autocomplete="username"], input[autocomplete="email"]'
            )
          );
          usernameField =
            candidates.find(
              (el) => el.offsetParent !== null && !el.disabled && el !== passwordField
            ) || null;
          if (!usernameField) {
            const inputs = Array.from(scope.querySelectorAll('input'));
            const index = inputs.indexOf(passwordField);
            for (let i = index - 1; i >= 0; i--) {
              const type = inputs[i].type;
              if (
                (type === 'text' || type === 'email' || type === 'tel') &&
                !inputs[i].disabled
              ) {
                usernameField = inputs[i];
                break;
              }
            }
          }

          (async () => {
            if (usernameField && username) await setValue(usernameField, username);
            if (password) await setValue(passwordField, password);
          })();
        },
        args: [credential.username, credential.password],
      });
      // After filling credentials, ask the content script to fill TOTP if the
      // page has a TOTP/2FA input field.
      try {
        await chrome.tabs.sendMessage(tab.id, {
          action: 'fillTotp',
          fileId: match.fileId,
          entryUuid: match.entryUuid,
        });
      } catch (_) {
        // No content script listener or no TOTP field; ignore.
      }
      window.close();
    } catch (e) {
      showStatus(e.message, 'error');
    }
  }

  lockBtn.addEventListener('click', async () => {
    try {
      await sendToHost('lock');
      matchesSection.classList.add('hidden');
      generatorSection.classList.add('hidden');
      unlockSection.classList.remove('hidden');
      matchesList.innerHTML = '';
    } catch (e) {
      showStatus(e.message, 'error');
    }
  });

  // Password generator
  function evaluatePasswordStrength(password) {
    if (!password || password.length < 8) {
      return { score: 0, label: '太短', acceptable: false };
    }
    let score = 0;
    const hasLower = /[a-z]/.test(password);
    const hasUpper = /[A-Z]/.test(password);
    const hasDigit = /\d/.test(password);
    const hasSpecial = /[^A-Za-z0-9]/.test(password);
    const charTypes = [hasLower, hasUpper, hasDigit, hasSpecial].filter(Boolean).length;

    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;
    score += charTypes - 1;

    const acceptable = password.length >= 12 && charTypes >= 3;
    if (score <= 1) return { score: 1, label: '弱', acceptable };
    if (score <= 3) return { score: 2, label: '一般', acceptable };
    if (score <= 5) return { score: 3, label: '强', acceptable };
    return { score: 4, label: '非常强', acceptable };
  }

  function updateStrengthIndicator(password) {
    const { score, label, acceptable } = evaluatePasswordStrength(password);
    if (!password) {
      genStrength.classList.add('hidden');
      return;
    }
    genStrength.classList.remove('hidden');
    const percent = (score / 4) * 100;
    strengthBar.style.width = `${percent}%`;
    strengthBar.className = 'strength-bar';
    if (score <= 1) strengthBar.classList.add('weak');
    else if (score <= 2) strengthBar.classList.add('fair');
    else if (score <= 3) strengthBar.classList.add('good');
    else strengthBar.classList.add('strong');
    strengthLabel.textContent = acceptable ? label : `${label}（建议至少12位且包含3种字符类型）`;
    strengthLabel.className = acceptable ? '' : 'warning';
  }

  async function regeneratePassword() {
    try {
      const params = {
        length: parseInt(genLength.value, 10),
        includeUppercase: genUpper.checked,
        includeDigits: genDigits.checked,
        includeSpecial: genSpecial.checked,
      };
      const result = await sendToHost('generatePassword', params);
      genPassword.value = result.password || '';
      updateStrengthIndicator(genPassword.value);
    } catch (e) {
      showStatus(e.message, 'error');
    }
  }

  genLength.addEventListener('input', () => {
    genLengthValue.textContent = genLength.value;
  });
  genLength.addEventListener('change', regeneratePassword);
  genUpper.addEventListener('change', regeneratePassword);
  genDigits.addEventListener('change', regeneratePassword);
  genSpecial.addEventListener('change', regeneratePassword);

  genRegenBtn.addEventListener('click', () => {
    clearStatus();
    regeneratePassword();
  });

  genCopyBtn.addEventListener('click', async () => {
    if (!genPassword.value) return;
    try {
      await navigator.clipboard.writeText(genPassword.value);
      showStatus('密码已复制', 'info');
    } catch (e) {
      showStatus('复制失败', 'error');
    }
  });

  async function fillPasswordOnTab(password) {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (!tab || !tab.id) return;
    await chrome.scripting.executeScript({
      target: { tabId: tab.id, allFrames: true },
      func: (password) => {
        const setValue = async (field, value) => {
          if (!field || field.readOnly) return;
          field.focus();
          await new Promise((resolve) => setTimeout(resolve, 0));
          field.dispatchEvent(new FocusEvent('focus', { bubbles: false }));
          field.dispatchEvent(new FocusEvent('focusin', { bubbles: true }));
          field.dispatchEvent(
            new KeyboardEvent('keydown', { bubbles: true, cancelable: false, key: value })
          );
          field.dispatchEvent(
            new InputEvent('beforeinput', {
              bubbles: true,
              cancelable: false,
              inputType: 'insertText',
              data: value,
            })
          );
          field.dispatchEvent(
            new KeyboardEvent('keypress', { bubbles: true, cancelable: false, key: value })
          );
          field.value = value;
          field.dispatchEvent(new Event('input', { bubbles: true, cancelable: false }));
          field.dispatchEvent(
            new KeyboardEvent('keyup', { bubbles: true, cancelable: false, key: value })
          );
          field.dispatchEvent(new Event('change', { bubbles: true, cancelable: false }));
        };
        const passwordField = Array.from(
          document.querySelectorAll('input[type="password"]')
        ).find((el) => el.offsetParent !== null && !el.disabled);
        if (passwordField && password) {
          setValue(passwordField, password);
        }
      },
      args: [password],
    });
  }

  genFillBtn.addEventListener('click', async () => {
    if (!genPassword.value) {
      showStatus('请先生成密码', 'error');
      return;
    }
    try {
      await fillPasswordOnTab(genPassword.value);
      window.close();
    } catch (e) {
      showStatus(e.message, 'error');
    }
  });

  function getSiteTitleFromUrl(url) {
    try {
      const urlObj = new URL(url);
      return urlObj.hostname.replace(/^www\./, '');
    } catch (e) {
      return '';
    }
  }

  async function detectUsernameForCreate() {
    try {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (!tab || !tab.id) return '';
      const results = await chrome.scripting.executeScript({
        target: { tabId: tab.id, allFrames: true },
        func: () => {
          const passwordField = Array.from(
            document.querySelectorAll('input[type="password"]')
          ).find((el) => el.offsetParent !== null && !el.disabled);
          if (!passwordField) return '';
          const scope = passwordField.closest('form') || document;
          const candidates = Array.from(
            scope.querySelectorAll(
              'input[type="email"], input[type="text"][autocomplete="username"], ' +
                'input[autocomplete="username"], input[name*="user" i], input[name*="email" i], ' +
                'input[id*="user" i], input[id*="email" i]'
            )
          );
          const visible = candidates.find(
            (el) => el.offsetParent !== null && !el.disabled && el !== passwordField
          );
          return visible ? visible.value || '' : '';
        },
      });
      for (const result of results || []) {
        if (result.result) return result.result;
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  genCreateBtn.addEventListener('click', async () => {
    clearStatus();
    if (!genPassword.value) {
      showStatus('请先生成密码', 'error');
      return;
    }
    if (currentVaults.length === 0) {
      showStatus('没有已解锁的密码库', 'error');
      return;
    }
    const password = genPassword.value;
    const strength = evaluatePasswordStrength(password);
    if (!strength.acceptable) {
      const proceed = await showConfirmDialog({
        title: '密码强度不足',
        message: `当前密码强度为“${strength.label}”。建议长度至少 12 位且包含大写、小写、数字、特殊字符中的至少 3 种。确定仍要保存吗？`,
        confirmText: '仍要保存',
        cancelText: '取消',
        danger: true,
      });
      if (!proceed) {
        return;
      }
    }

    try {
      const fileId = currentVaults[0].id;
      const url = currentTabUrl;
      const title = getSiteTitleFromUrl(url);
      const username = await detectUsernameForCreate();

      // Avoid creating duplicate entries for the same site. If a matching entry
      // already exists, let the user choose whether to update it or create new.
      const existingData = await sendToHost('matchEntries', { url, limit: 10 });
      const existing = (existingData && existingData.matches) || [];
      const sameSite = existing.filter(
        (m) => m.quality === 'host' || m.quality === 'domain',
      );

      if (sameSite.length > 0) {
        const first = sameSite[0];
        const firstLabel = first.label || first.username || '(无标题)';
        const updateExisting = await showConfirmDialog({
          title: '检测到重复条目',
          message: `已存在 ${sameSite.length} 条该网站条目（例如：${firstLabel}）。点击“更新”覆盖该条目，点击“新建”则创建一条新条目。`,
          confirmText: '更新',
          cancelText: '新建',
        });
        if (updateExisting) {
          await sendToHost('updateEntry', {
            fileId: first.fileId,
            entryUuid: first.entryUuid,
            title,
            username,
            password,
            url,
          });
          showStatus('条目已更新', 'info');
          await refreshMatches();
          return;
        }
      }

      await sendToHost('createEntry', {
        fileId,
        title,
        username,
        password,
        url,
      });
      showStatus('条目已保存', 'info');
      await refreshMatches();
    } catch (e) {
      showStatus(e.message, 'error');
    }
  });

  function showMatchDropdown(anchor, match, li) {
    // Remove any existing dropdown.
    const existing = document.querySelector('.dropdown-menu');
    if (existing) {
      existing.remove();
      if (existing.dataset.matchUuid === match.entryUuid) {
        return;
      }
    }

    const menu = document.createElement('div');
    menu.className = 'dropdown-menu';
    menu.dataset.matchUuid = match.entryUuid;

    const editItem = document.createElement('button');
    editItem.className = 'dropdown-item';
    editItem.textContent = '编辑';
    editItem.addEventListener('click', () => {
      menu.remove();
      startEditEntry(li, match);
    });
    menu.appendChild(editItem);

    const deleteItem = document.createElement('button');
    deleteItem.className = 'dropdown-item danger';
    deleteItem.textContent = '删除';
    deleteItem.addEventListener('click', async () => {
      menu.remove();
      const confirmed = await showConfirmDialog({
        title: '删除条目',
        message: `确定要删除 "${match.label || match.username || '(无标题)'}" 吗？此操作不可恢复。`,
        confirmText: '删除',
        cancelText: '取消',
        danger: true,
      });
      if (!confirmed) {
        return;
      }
      try {
        await sendToHost('deleteEntry', {
          fileId: match.fileId,
          entryUuid: match.entryUuid,
        });
        showStatus('条目已删除', 'info');
        await refreshMatches();
      } catch (e) {
        showStatus(e.message, 'error');
      }
    });
    menu.appendChild(deleteItem);

    anchor.appendChild(menu);

    const closeOnClickOutside = (event) => {
      if (!menu.contains(event.target) && event.target !== anchor.querySelector('.menu-btn')) {
        menu.remove();
        document.removeEventListener('click', closeOnClickOutside);
      }
    };
    setTimeout(() => {
      document.addEventListener('click', closeOnClickOutside);
    }, 0);
  }

  // Inline entry editing
  async function startEditEntry(li, match) {
    clearStatus();
    try {
      const credential = await sendToHost('getCredential', {
        fileId: match.fileId,
        entryUuid: match.entryUuid,
      });

      li.classList.add('edit-form');
      li.innerHTML = '';

      const fields = [
        { id: 'edit-title', label: '标题', value: credential.title || match.label || '', type: 'text' },
        { id: 'edit-username', label: '用户名', value: credential.username || '', type: 'text' },
        { id: 'edit-password', label: '密码', value: credential.password || '', type: 'password' },
        { id: 'edit-url', label: 'URL', value: credential.url || match.url || currentTabUrl || '', type: 'text' },
        { id: 'edit-notes', label: '备注', value: credential.notes || '', type: 'textarea' },
      ];

      for (const field of fields) {
        const wrapper = document.createElement('div');
        wrapper.className = 'edit-field';
        const label = document.createElement('label');
        label.textContent = field.label;
        label.htmlFor = field.id;
        let control;
        if (field.type === 'textarea') {
          control = document.createElement('textarea');
          control.id = field.id;
          control.rows = 3;
          control.value = field.value;
        } else {
          control = document.createElement('input');
          control.type = field.type;
          control.id = field.id;
          control.value = field.value;
        }
        wrapper.appendChild(label);
        wrapper.appendChild(control);
        li.appendChild(wrapper);
      }

      const actions = document.createElement('div');
      actions.className = 'edit-actions';

      const saveBtn = document.createElement('button');
      saveBtn.className = 'primary';
      saveBtn.textContent = '保存';
      saveBtn.addEventListener('click', async () => {
        try {
          await sendToHost('updateEntry', {
            fileId: match.fileId,
            entryUuid: match.entryUuid,
            title: document.getElementById('edit-title').value,
            username: document.getElementById('edit-username').value,
            password: document.getElementById('edit-password').value,
            url: document.getElementById('edit-url').value,
            notes: document.getElementById('edit-notes').value,
          });
          showStatus('条目已更新', 'info');
          await refreshMatches();
        } catch (e) {
          showStatus(e.message, 'error');
        }
      });

      const cancelBtn = document.createElement('button');
      cancelBtn.className = 'secondary';
      cancelBtn.textContent = '取消';
      cancelBtn.addEventListener('click', () => refreshMatches());

      actions.appendChild(saveBtn);
      actions.appendChild(cancelBtn);
      li.appendChild(actions);
    } catch (e) {
      showStatus(e.message, 'error');
    }
  }

  // On open, pull the vaults the desktop app has already unlocked and show
  // matches for the current page. No master password or cloud config here:
  // the desktop app is the only thing that unlocks vaults.
  try {
    showStatus('连接桌面 OpenValut…', 'info');
    const openResult = await sendToHost('openAppVault');
    const vaults = await sendToHost('listVaults');
    currentVaults = (vaults && vaults.vaults) || [];
    clearStatus();
    if (currentVaults.length > 0) {
      unlockSection.classList.add('hidden');
      unlockBtn.classList.add('hidden');
      generatorSection.classList.remove('hidden');
      await refreshMatches();
      await regeneratePassword();
    } else if (openResult && openResult.launched) {
      unlockSection.classList.remove('hidden');
      unlockBtn.classList.remove('hidden');
      unlockHint.textContent = '已打开 OpenValut，请在桌面端解锁密码库后返回刷新本页面。';
    } else {
      unlockSection.classList.remove('hidden');
      unlockBtn.classList.remove('hidden');
      unlockHint.textContent = '请先在桌面 OpenValut 打开并解锁密码库，再刷新本页面。';
    }
  } catch (e) {
    showStatus(
      '无法连接桌面 OpenValut。请确认已安装 Native Host 且桌面端已解锁密码库。',
      'error',
    );
    unlockSection.classList.remove('hidden');
    unlockBtn.classList.remove('hidden');
    unlockHint.textContent = '无法连接桌面 OpenValut。';
  }
});
