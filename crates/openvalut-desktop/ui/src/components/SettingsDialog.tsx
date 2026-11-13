import { useEffect, useState } from "react";
import { api, type CloseAction, type RememberedSummary, type Settings } from "../api";

const REMEMBER_CHOICES: { days: number; label: string }[] = [
  { days: 0, label: "关闭" },
  { days: 7, label: "7 天" },
  { days: 14, label: "14 天" },
  { days: 30, label: "30 天" },
];

const CLOSE_CHOICES: { value: CloseAction; label: string }[] = [
  { value: "hide", label: "隐藏到托盘" },
  { value: "minimize", label: "最小化到任务栏" },
  { value: "exit", label: "退出应用" },
];

// 0 is the backend's own value (monitor scale divided by GDK_SCALE, so 80% on a
// 1.6 panel exporting GDK_SCALE=2). It has to be selectable: a dialog listing
// only literals pins a number the first time anyone saves, and the computed
// correction can then never be restored except by editing the settings file.
const ZOOM_CHOICES = [0, 80, 90, 100, 110, 125];

const zoomLabel = (percent: number) => (percent === 0 ? "自动" : `${percent}%`);

function clean(e: unknown) {
  return String(e).replace(/^Error: /, "");
}

export default function SettingsDialog({ onClose }: { onClose: () => void }) {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [remembered, setRemembered] = useState<RememberedSummary[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const loadRemembered = async () => {
    setRemembered(await api.rememberedStatus().catch(() => [] as RememberedSummary[]));
  };

  useEffect(() => {
    void (async () => {
      try {
        setSettings(await api.settingsGet());
      } catch (e) {
        setError(clean(e));
      }
      await loadRemembered();
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  const patch = (changes: Partial<Settings>) => {
    if (!settings) return;
    setSettings({ ...settings, ...changes });
  };

  const save = async () => {
    if (!settings) return;
    setBusy(true);
    setError(null);
    try {
      // The Rust side applies the login item and drops every remembered
      // credential when the period goes back to 0, so both need re-reading.
      await api.settingsSet(settings);
      await loadRemembered();
      onClose();
    } catch (e) {
      setError(clean(e));
    } finally {
      setBusy(false);
    }
  };

  const forget = async (row?: RememberedSummary) => {
    setError(null);
    try {
      if (row) await api.rememberedForget(row.kind, row.id);
      else await api.rememberedForget();
      await loadRemembered();
    } catch (e) {
      setError(clean(e));
    }
  };

  return (
    <div className="overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()} style={{ width: 440 }}>
        <h2>设置</h2>
        {error && <div className="error-banner">{error}</div>}
        {!settings ? (
          <div className="empty-hint">读取设置…</div>
        ) : (
          <>
            <div className="pref-group">
              <div className="pref-title">记住主密码</div>
              <div className="pref-hint">
                本次开机内打开密码库无需再次输入主密码，改用 PIN 验证；重启后必须重新输入主密码
              </div>
              <div className="pref-choices">
                {REMEMBER_CHOICES.map((choice) => (
                  <label className="pref-choice" key={choice.days}>
                    <input
                      type="radio"
                      name="remember-days"
                      checked={settings.remember_unlock_days === choice.days}
                      onChange={() => patch({ remember_unlock_days: choice.days })}
                    />
                    {choice.label}
                  </label>
                ))}
              </div>
              {settings.remember_unlock_days > 0 && (
                <div className="pref-hint">
                  保存后每个密码库还要用主密码解锁一次，凭据才会存进系统钥匙串；
                  {remembered.length > 0
                    ? `当前已记住 ${remembered.length} 个，本次开机内可用 PIN 解锁。`
                    : "当前还没有已记住的密码库，请先用主密码解锁一次。"}
                  关闭或重启电脑后，所有密码库都会重新要求输入主密码。
                </div>
              )}
            </div>

            <div className="pref-group">
              <label className="pref-choice">
                <input
                  type="checkbox"
                  checked={settings.autostart}
                  onChange={(e) => patch({ autostart: e.target.checked })}
                />
                开机自动启动
              </label>
              <div className="pref-hint">登录系统后自动启动 OpenValut 并隐藏到托盘</div>
            </div>

            <div className="pref-group">
              <div className="pref-title">关闭窗口时</div>
              <div className="pref-choices column">
                {CLOSE_CHOICES.map((choice) => (
                  <label className="pref-choice" key={choice.value}>
                    <input
                      type="radio"
                      name="close-action"
                      checked={settings.close_action === choice.value}
                      onChange={() => patch({ close_action: choice.value })}
                    />
                    {choice.label}
                  </label>
                ))}
              </div>
            </div>

            <div className="pref-group">
              <div className="pref-title">界面缩放</div>
              <div className="pref-hint">
                自动按系统缩放算出比例。系统缩放是小数（如 150%、1.6 倍）时界面会比其他应用偏大，
                这里也可以手动压回去
              </div>
              <div className="pref-choices">
                {ZOOM_CHOICES.map((percent) => (
                  <label className="pref-choice" key={percent}>
                    <input
                      type="radio"
                      name="ui-zoom"
                      checked={settings.ui_zoom === percent}
                      onChange={() => patch({ ui_zoom: percent })}
                    />
                    {zoomLabel(percent)}
                  </label>
                ))}
              </div>
            </div>

            <div className="pref-group">
              <div className="pref-title">已记住</div>
              {remembered.length === 0 ? (
                <div className="pref-hint">解锁一次密码库后就会出现在这里</div>
              ) : (
                <>
                  {remembered.map((row) => (
                    <div className="remembered-row" key={`${row.kind}:${row.id}`}>
                      <div className="remembered-name">{row.name}</div>
                      <div className="remembered-id">{row.id}</div>
                      <span className="remembered-days">剩余 {row.remaining_days} 天</span>
                      <button className="link-btn" onClick={() => void forget(row)}>
                        清除
                      </button>
                    </div>
                  ))}
                  <button className="link-btn" onClick={() => void forget()}>
                    清除全部
                  </button>
                </>
              )}
            </div>
          </>
        )}
        <div className="footer">
          <button className="btn" onClick={onClose}>
            取消
          </button>
          <button className="btn primary" disabled={busy || !settings} onClick={() => void save()}>
            保存
          </button>
        </div>
      </div>
    </div>
  );
}
