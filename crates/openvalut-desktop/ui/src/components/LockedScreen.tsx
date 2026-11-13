import { useEffect, useState } from "react";
import { useVault, toggleTheme } from "../store";
import { api, type RememberedSummary } from "../api";
import Icon from "./Icon";
import CloudLogin from "./CloudLogin";

type Target = { kind: "local" | "cloud"; path: string; name: string };
type Stage = "select" | "credentials" | "create" | "cloud";

const START_PAGE_KEY = "ov.showVaultStartPage";

function baseName(path: string) {
  return path.split(/[\\/]/).filter(Boolean).pop() ?? path;
}

function isWrongPasswordError(msg: string) {
  return /解锁失败|不正确|解密失败/.test(msg);
}

export default function LockedScreen() {
  const refresh = useVault((s) => s.refresh);
  const openSettings = useVault((s) => s.openSettings);

  const [recentFiles, setRecentFiles] = useState<{ path: string; name: string }[]>([]);
  const [cloudVaults, setCloudVaults] = useState<{ id: string; name: string }[]>([]);
  const [cloudEmail, setCloudEmail] = useState<string | null>(null);
  const [stage, setStage] = useState<Stage>("select");
  const [target, setTarget] = useState<Target | null>(null);
  const [password, setPassword] = useState("");
  const [keyfilePath, setKeyfilePath] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setLocalError] = useState<string | null>(null);
  const [invalidPassword, setInvalidPassword] = useState(false);
  const [rememberedRows, setRememberedRows] = useState<RememberedSummary[]>([]);
  const [removeDialogFor, setRemoveDialogFor] = useState<Target | null>(null);
  const [showStartPage, setShowStartPage] = useState(
    () => localStorage.getItem(START_PAGE_KEY) !== "0",
  );

  const loadRecents = async () => {
    const list = await api.recentsList();
    setRecentFiles(list);
    return list;
  };

  const loadCloudVaults = async () => {
    const status = await api.cloudAccountStatus();
    if (!status.configured) return [] as { id: string; name: string }[];
    setCloudEmail(status.email);
    const vaults = await api.cloudVaults();
    setCloudVaults(vaults);
    return vaults;
  };

  const loadRemembered = async () => {
    const rows = await api.rememberedStatus().catch(() => [] as RememberedSummary[]);
    setRememberedRows(rows);
  };

  useEffect(() => {
    void (async () => {
      const [recents, vaults] = await Promise.all([
        loadRecents().catch(() => [] as { path: string; name: string }[]),
        loadCloudVaults().catch((e: unknown) => {
          setLocalError(typeof e === "string" ? e : String(e));
          return [] as { id: string; name: string }[];
        }),
        loadRemembered(),
      ]);
      if (!showStartPage) {
        const firstCloud = vaults[0];
        if (firstCloud) {
          goCredentials({ kind: "cloud", path: firstCloud.id, name: firstCloud.name });
        } else if (recents[0]) {
          goCredentials({ kind: "local", path: recents[0].path, name: recents[0].name });
        }
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!removeDialogFor) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setRemoveDialogFor(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [removeDialogFor]);

  const goCredentials = (t: Target) => {
    setTarget(t);
    setPassword("");
    setKeyfilePath(null);
    setInvalidPassword(false);
    setLocalError(null);
    setStage("credentials");
  };

  const unlock = async () => {
    if (!target || !password) {
      setLocalError(target ? "请输入主密码" : "请选择密码库");
      return;
    }
    setBusy(true);
    setLocalError(null);
    setInvalidPassword(false);
    try {
      if (target.kind === "cloud") {
        await api.cloudOpen(password, target.path || undefined);
      } else {
        await api.vaultOpen(target.path, password, keyfilePath ?? undefined);
      }
      setPassword("");
      await refresh();
    } catch (e) {
      const msg = String(e).replace(/^Error: /, "");
      if (isWrongPasswordError(msg)) {
        setInvalidPassword(true);
      } else {
        setLocalError(msg);
      }
    } finally {
      setBusy(false);
    }
  };

  // Remembered entries can expire or be dropped (wrong file, switched cloud
  // account) while this screen is open, so a failure re-reads the list.
  const unlockWithPin = async () => {
    if (!target) return;
    setBusy(true);
    setLocalError(null);
    try {
      await api.rememberedUnlock(target.kind, target.path);
      setPassword("");
      await refresh();
    } catch (e) {
      setLocalError(String(e).replace(/^Error: /, ""));
      await loadRemembered();
    } finally {
      setBusy(false);
    }
  };

  const createVault = async (name: string, path: string, master: string) => {
    setBusy(true);
    setLocalError(null);
    try {
      await api.vaultCreate(path, name, master, keyfilePath ?? undefined);
      setPassword("");
      await refresh();
    } catch (e) {
      setLocalError(String(e).replace(/^Error: /, ""));
    } finally {
      setBusy(false);
    }
  };

  const removeRecent = async (t: Target) => {
    setRemoveDialogFor(null);
    if (t.kind === "local") {
      await api.recentsRemove(t.path);
      await loadRecents();
    }
  };

  const openLocal = async () => {
    const path = await api.dialogPickKdbx();
    if (path) goCredentials({ kind: "local", path, name: baseName(path) });
  };

  const openCloud = async () => {
    if (cloudVaults.length > 0) {
      const v = cloudVaults[0];
      goCredentials({ kind: "cloud", path: v.id, name: v.name });
    } else {
      setStage("cloud");
    }
  };

  const backToSelect = () => {
    setPassword("");
    setTarget(null);
    setInvalidPassword(false);
    setLocalError(null);
    setStage("select");
  };

  const pinReady =
    !!target && rememberedRows.some((r) => r.kind === target.kind && r.id === target.path);

  const headerTitle =
    stage === "select"
      ? "OpenValut - 打开密码库"
      : stage === "create"
        ? "新建密码库"
        : stage === "cloud"
          ? "OpenValut Cloud"
          : "";

  return (
    <div className="locked">
      <div className="locked-header">
        {stage !== "select" && (
          <button className="icon-btn" title="返回" onClick={backToSelect}>
            <Icon name="arrow_back" />
          </button>
        )}
        <div className="locked-title">{headerTitle}</div>
        <button className="icon-btn" title="切换主题" onClick={() => void toggleTheme()}>
          <Icon name="moon" />
        </button>
        <button className="icon-btn" title="设置" onClick={() => openSettings(true)}>
          <Icon name="settings" />
        </button>
      </div>

      <div className="locked-body">
        {stage === "select" && (
          <div className="select-wrap">
            {error && <div className="error-banner">{error}</div>}
            <div className="select-label">请打开一个数据库，后缀名为.kdbx</div>
            <div className="action-tiles">
              <button className="action-tile" onClick={() => void openLocal()}>
                <Icon name="folder_open" size={18} />
                <span>打开本地文件</span>
              </button>
              <button className="action-tile" onClick={() => void openCloud()}>
                <Icon name="cloud" size={18} />
                <span>OpenValut Cloud</span>
              </button>
              <button className="action-tile dark" onClick={() => setStage("create")}>
                <Icon name="create_new_folder" size={18} />
                <span>新建一个</span>
              </button>
            </div>

            <div className="recent-block">
              <div className="recent-label">上次打开的密码库:</div>
              {cloudVaults.length === 0 && recentFiles.length === 0 ? (
                <div className="empty-hint">尚未打开任何文件</div>
              ) : (
                <div className="recent-list">
                  {cloudVaults.map((v) => (
                    <div className="recent-item" key={`cloud:${v.id}`}>
                      <button
                        className="recent-main"
                        onClick={() => goCredentials({ kind: "cloud", path: v.id, name: v.name })}
                      >
                        <Icon name="cloud" />
                        <span className="meta">
                          <span className="name">{v.name}</span>
                          <span className="path">
                            云密码库{cloudEmail ? ` · ${cloudEmail}` : ""}
                          </span>
                        </span>
                      </button>
                    </div>
                  ))}
                  {recentFiles.map((r) => (
                    <div className="recent-item" key={r.path}>
                      <button
                        className="recent-main"
                        onClick={() => goCredentials({ kind: "local", path: r.path, name: r.name })}
                      >
                        <Icon name="folder_open" />
                        <span className="meta">
                          <span className="name">{r.name}</span>
                          <span className="path">{r.path}</span>
                        </span>
                      </button>
                      <button
                        className="icon-btn more-btn"
                        title="更多操作"
                        onClick={() =>
                          setRemoveDialogFor({ kind: "local", path: r.path, name: r.name })
                        }
                      >
                        <Icon name="more_vert" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
              <label className="start-check">
                <input
                  type="checkbox"
                  checked={showStartPage}
                  onChange={(e) => {
                    setShowStartPage(e.target.checked);
                    localStorage.setItem(START_PAGE_KEY, e.target.checked ? "1" : "0");
                  }}
                />
                每次打开 OpenValut 时显示此页面
              </label>
            </div>
          </div>
        )}

        {stage === "credentials" && target && (
          <div className="cred-wrap">
            {error && <div className="error-banner">{error}</div>}
            <div className="cred-label">输入这个数据库的解锁密码</div>
            <div className="cred-name">{target.name}</div>
            <div className="cred-path">
              {target.kind === "cloud" ? "OpenValut Cloud" : target.path}
            </div>
            {pinReady && (
              <div className="pin-wrap">
                <button
                  className="btn primary cred-btn"
                  disabled={busy}
                  onClick={() => void unlockWithPin()}
                >
                  使用 PIN 解锁
                </button>
                <div className="pin-hint">或输入主密码</div>
              </div>
            )}
            <div className="pw-wrap">
              <input
                className="input pw-input"
                type={showPassword ? "text" : "password"}
                placeholder="用主密码保护您的密码库"
                value={password}
                autoFocus
                onChange={(e) => {
                  setPassword(e.target.value);
                  if (invalidPassword) setInvalidPassword(false);
                }}
                onKeyDown={(e) => e.key === "Enter" && void unlock()}
              />
              <button
                className="icon-btn pw-toggle"
                title={showPassword ? "隐藏密码" : "显示密码"}
                onClick={() => setShowPassword((v) => !v)}
              >
                <Icon name={showPassword ? "visibility_off" : "visibility"} size={16} />
              </button>
              {invalidPassword && <div className="cred-error">该密码无效</div>}
            </div>
            {target.kind === "local" && (
              <div className="form-row keyfile-row">
                <label>密钥文件</label>
                <input
                  className="input"
                  readOnly
                  placeholder="（可选）"
                  value={keyfilePath ?? ""}
                  onClick={async () => setKeyfilePath((await api.dialogPickKdbx()) ?? null)}
                />
              </div>
            )}
            <div className="cred-actions">
              {busy ? (
                <div className="cred-busy" />
              ) : (
                <button className="btn primary cred-btn" onClick={() => void unlock()}>
                  下一步
                </button>
              )}
            </div>
          </div>
        )}

        {stage === "create" && (
          <CreateVaultForm busy={busy} onCancel={backToSelect} onCreate={createVault} />
        )}

        {stage === "cloud" && (
          <CloudLogin
            onUnlocked={async () => {
              await loadCloudVaults().catch(() => {});
              await refresh();
            }}
          />
        )}
      </div>

      {removeDialogFor && (
        <div className="overlay" onClick={() => setRemoveDialogFor(null)}>
          <div className="modal small" onClick={(e) => e.stopPropagation()}>
            <div className="modal-title">{removeDialogFor.name}</div>
            <button className="remove-option" onClick={() => void removeRecent(removeDialogFor)}>
              <Icon name="remove_circle_outline" />
              删除最近文件
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function CreateVaultForm({
  busy,
  onCancel,
  onCreate,
}: {
  busy: boolean;
  onCancel: () => void;
  onCreate: (name: string, path: string, master: string) => Promise<void>;
}) {
  const [name, setName] = useState("我的密码库");
  const [master, setMaster] = useState("");
  const [confirm, setConfirm] = useState("");
  const [path, setPath] = useState<string | null>(null);
  const [error, setLocalError] = useState<string | null>(null);

  const create = async () => {
    if (master !== confirm) {
      setLocalError("两次输入的密码不一致");
      return;
    }
    const target = path ?? (await api.dialogPickSavePath(`${name || "openvalut"}.kdbx`));
    if (!target) return;
    setPath(target);
    if (!master) {
      setLocalError("主密码不能为空");
      return;
    }
    await onCreate(name || "openvalut", target, master);
  };

  return (
    <div className="form-wrap">
      {error && <div className="error-banner">{error}</div>}
      <div className="hint">设置一个你记得住、别人猜不到的主密码</div>
      <div className="form-row">
        <label>名称</label>
        <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
      </div>
      <div className="form-row">
        <label>保存位置</label>
        <input
          className="input"
          readOnly
          placeholder="点击选择…"
          value={path ?? ""}
          onClick={async () =>
            setPath((await api.dialogPickSavePath(`${name || "openvalut"}.kdbx`)) ?? null)
          }
        />
      </div>
      <input
        className="input"
        type="password"
        placeholder="设置主密码"
        value={master}
        onChange={(e) => setMaster(e.target.value)}
      />
      <input
        className="input"
        type="password"
        placeholder="再次输入主密码"
        value={confirm}
        onChange={(e) => setConfirm(e.target.value)}
      />
      <button className="btn primary cred-btn" disabled={busy} onClick={() => void create()}>
        {busy ? "创建中…" : "创建密码库"}
      </button>
      <button className="link-btn back-link" onClick={onCancel}>
        返回
      </button>
    </div>
  );
}
