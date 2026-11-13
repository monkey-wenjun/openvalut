import { useCallback, useEffect, useRef, useState } from "react";
import { api, type ScanStartInfo } from "../api";
import Icon from "./Icon";
import SecretKeyDialog from "./SecretKeyDialog";

const DEFAULT_SERVER = "https://openvalut.example.com";

type Mode = "login" | "register" | "scan";

function cleanError(msg: string) {
  return msg.replace(/^Error: /, "");
}

function mapUnlockError(msg: string) {
  return /解锁失败|解密失败|无法解锁/.test(msg) ? "主密码错误，无法解锁密码库。" : msg;
}

export default function CloudLogin({ onUnlocked }: { onUnlocked: () => Promise<void> | void }) {
  const [mode, setMode] = useState<Mode>("login");
  const [server, setServer] = useState(DEFAULT_SERVER);
  const [email, setEmail] = useState("");
  const [secretKey, setSecretKey] = useState("");
  const [name, setName] = useState("我的密码库");
  const [master, setMaster] = useState("");
  const [confirm, setConfirm] = useState("");
  const [showMaster, setShowMaster] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [showSecret, setShowSecret] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [strength, setStrength] = useState(0);
  const [savedKey, setSavedKey] = useState<{ key: string; email: string } | null>(null);

  useEffect(() => {
    void api
      .cloudAccountStatus()
      .then((s) => {
        if (s.server) setServer(s.server);
        if (s.email) setEmail(s.email);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (mode !== "register") return;
    if (!master) {
      setStrength(0);
      return;
    }
    const t = window.setTimeout(() => {
      api
        .passwordStrength(master, [email.trim(), name].filter(Boolean))
        .then(setStrength)
        .catch(() => {});
    }, 250);
    return () => window.clearTimeout(t);
  }, [master, mode, email, name]);

  const validate = (): string | null => {
    if (!server.trim()) return "请输入服务器地址";
    if (!/^https?:\/\//.test(server.trim())) return "服务器地址需以 http:// 或 https:// 开头";
    if (!email.trim()) return "请输入邮箱";
    if (email.includes(" ")) return "邮箱不能包含空格";
    if (!email.includes("@")) return "请输入有效的邮箱地址";
    if (mode === "login") {
      if (!secretKey.trim()) return "请输入 Secret Key";
      if (!/^[0-9a-fA-F-]+$/.test(secretKey.trim()))
        return "Secret Key 只能包含十六进制字符和 - 分隔符";
      if (secretKey.trim().replace(/-/g, "").length !== 32)
        return "Secret Key 应为 32 位十六进制字符";
      if (!master) return "请输入密码库主密码";
      if (master.includes(" ")) return "密码不能包含空格";
    } else {
      if (!name.trim()) return "请输入密码库名称";
      if (/^[0-9]/.test(name)) return "名称不能以数字开头";
      if (!/^[\u4e00-\u9fa5a-zA-Z0-9]+$/.test(name)) return "名称只能包含中文、英文和数字";
      if (!master) return "请输入密码库主密码";
      if (master.includes(" ")) return "密码不能包含空格";
      if (master.length < 6) return "主密码至少 6 位";
      if (master !== confirm) return "两次输入的密码不一致";
    }
    return null;
  };

  const submit = async () => {
    if (busy) return;
    const problem = validate();
    if (problem) {
      setError(problem);
      return;
    }
    setBusy(true);
    setError(null);
    try {
      if (mode === "login") {
        await api.cloudLogin(email.trim(), secretKey.trim(), server.trim(), master);
        await onUnlocked();
      } else {
        const res = await api.cloudRegister(email.trim(), server.trim(), name.trim(), master);
        setSavedKey({ key: res.secret_key, email: email.trim() });
      }
    } catch (e) {
      setError(mapUnlockError(cleanError(String(e))));
    } finally {
      setBusy(false);
    }
  };

  const switchMode = (next: Mode) => {
    if (busy) return;
    setMode(next);
    setSecretKey("");
    setError(null);
  };

  const title =
    mode === "login" ? "登录 OpenValut Cloud" : mode === "register" ? "注册 OpenValut Cloud 账号" : "扫码登录 OpenValut Cloud";
  const intro =
    mode === "login"
      ? "输入邮箱、Secret Key 和主密码登录，或使用移动端扫码。"
      : mode === "register"
        ? "注册只需邮箱；密码库主密码仅在本机用于加密，不会上传服务器。"
        : "请使用已登录 OpenValut Cloud 的移动端 App 扫描下方二维码确认登录。";

  if (savedKey) {
    return (
      <SecretKeyDialog
        secretKey={savedKey.key}
        email={savedKey.email}
        onDone={() => {
          setSavedKey(null);
          void onUnlocked();
        }}
      />
    );
  }

  return (
    <div className="cloud-wrap">
      <div className="cloud-hero">
        <Icon name="cloud" size={48} />
      </div>
      <div className="cloud-title">{title}</div>
      <div className="cloud-intro">{intro}</div>

      {mode === "scan" ? (
        <ScanPanel server={server.trim() || DEFAULT_SERVER} onUnlocked={onUnlocked} onBack={() => switchMode("login")} />
      ) : (
        <div className="cloud-form">
          <div className="cloud-field">
            <label>
              <Icon name="dns" size={14} /> 服务器地址
            </label>
            <input
              className="input cloud-input"
              value={server}
              placeholder="https://openvalut.example.com"
              onChange={(e) => setServer(e.target.value)}
              disabled={busy}
            />
            <div className="cloud-helper">已内置默认服务器地址，可改为自建域名。</div>
          </div>

          <div className="cloud-field">
            <label>
              <Icon name="person" size={14} /> 邮箱
            </label>
            <input
              className="input cloud-input"
              value={email}
              placeholder="you@example.com"
              autoFocus
              onChange={(e) => setEmail(e.target.value)}
              disabled={busy}
            />
          </div>

          {mode === "login" && (
            <div className="cloud-field">
              <label>
                <Icon name="vpn_key" size={14} /> Secret Key（注册时保存的 UUID）
              </label>
              <div className="cloud-input-wrap">
                <input
                  className="input cloud-input"
                  type={showSecret ? "text" : "password"}
                  value={secretKey}
                  placeholder="32 位十六进制字符，可含 - 分隔"
                  onChange={(e) => setSecretKey(e.target.value)}
                  disabled={busy}
                />
                <button
                  className="icon-btn eye-btn"
                  title={showSecret ? "隐藏" : "显示"}
                  onClick={() => setShowSecret((v) => !v)}
                >
                  <Icon name={showSecret ? "visibility_off" : "visibility"} size={16} />
                </button>
              </div>
            </div>
          )}

          {mode === "register" && (
            <div className="cloud-field">
              <label>
                <Icon name="label" size={14} /> 密码库名称
              </label>
              <input
                className="input cloud-input"
                value={name}
                placeholder="我的密码库"
                onChange={(e) => setName(e.target.value)}
                disabled={busy}
              />
            </div>
          )}

          <div className="cloud-field">
            <label>
              <Icon name="lock" size={14} /> 密码库主密码
            </label>
            <div className="cloud-input-wrap">
              <input
                className="input cloud-input"
                type={showMaster ? "text" : "password"}
                value={master}
                placeholder={mode === "login" ? "解锁时输入的密码库主密码" : "至少 6 位，仅存本机"}
                onChange={(e) => setMaster(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && void submit()}
                disabled={busy}
              />
              <button
                className="icon-btn eye-btn"
                title={showMaster ? "隐藏密码" : "显示密码"}
                onClick={() => setShowMaster((v) => !v)}
              >
                <Icon name={showMaster ? "visibility_off" : "visibility"} size={16} />
              </button>
            </div>
            {mode === "register" && (
              <div className="strength-track">
                {[0, 1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className={`strength-seg${i < strength ? ` on s${Math.min(strength, 4)}` : ""}`}
                  />
                ))}
              </div>
            )}
          </div>

          {mode === "register" && (
            <div className="cloud-field">
              <label>确认主密码</label>
              <div className="cloud-input-wrap">
                <input
                  className="input cloud-input"
                  type={showConfirm ? "text" : "password"}
                  value={confirm}
                  placeholder="再次输入主密码"
                  onChange={(e) => setConfirm(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && void submit()}
                  disabled={busy}
                />
                <button
                  className="icon-btn eye-btn"
                  title={showConfirm ? "隐藏密码" : "显示密码"}
                  onClick={() => setShowConfirm((v) => !v)}
                >
                  <Icon name={showConfirm ? "visibility_off" : "visibility"} size={16} />
                </button>
              </div>
            </div>
          )}

          {error && <div className="cloud-error">{error}</div>}

          <button className="btn primary cloud-submit" onClick={() => void submit()} disabled={busy}>
            {busy ? <span className="btn-spinner" /> : mode === "login" ? "登录" : "注册并创建密码库"}
          </button>

          <button className="link-btn cloud-switch" onClick={() => switchMode(mode === "login" ? "register" : "login")}>
            {mode === "login" ? "没有账号？注册一个" : "已有账号？去登录"}
          </button>

          <button className="link-btn cloud-scan-entry" onClick={() => switchMode("scan")}>
            <Icon name="qr_code" size={15} /> 使用移动端扫码登录
          </button>
        </div>
      )}

      <div className="server-footer">服务器：{server.trim() || DEFAULT_SERVER}</div>
    </div>
  );
}

type ScanStatus = "starting" | "waiting" | "expired" | "needs_master";

function ScanPanel({
  server,
  onUnlocked,
  onBack,
}: {
  server: string;
  onUnlocked: () => Promise<void> | void;
  onBack: () => void;
}) {
  const [qr, setQr] = useState<ScanStartInfo | null>(null);
  const [status, setStatus] = useState<ScanStatus>("starting");
  const [note, setNote] = useState<string | null>(null);
  const [master, setMaster] = useState("");
  const [showMaster, setShowMaster] = useState(false);
  const [busy, setBusy] = useState(false);
  const inFlight = useRef(false);

  const start = useCallback(async () => {
    setStatus("starting");
    setQr(null);
    setNote(null);
    try {
      const info = await api.scanStart(server);
      setQr(info);
      setStatus("waiting");
    } catch (e) {
      setNote(`无法创建登录二维码：${cleanError(String(e))}`);
      setStatus("expired");
    }
  }, [server]);

  useEffect(() => {
    void start();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!qr || status !== "waiting") return;
    let alive = true;
    const timer = window.setInterval(async () => {
      if (!alive || inFlight.current) return;
      inFlight.current = true;
      try {
        const res = await api.scanPoll(qr.session_id);
        if (!alive) return;
        if (res.status === "pending") setNote(null);
        else if (res.status === "expired") setStatus("expired");
        else if (res.unlocked) void onUnlocked();
        else {
          setStatus("needs_master");
          setNote(res.message);
        }
      } catch (e) {
        if (alive) setNote(`等待手机确认中（${cleanError(String(e))}）`);
      } finally {
        inFlight.current = false;
      }
    }, 2000);
    return () => {
      alive = false;
      window.clearInterval(timer);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [qr, status]);

  useEffect(
    () => () => {
      void api.scanCancel().catch(() => {});
    },
    [],
  );

  const unlockWithMaster = async () => {
    if (busy) return;
    if (!master) {
      setNote("请输入密码库主密码");
      return;
    }
    setBusy(true);
    setNote(null);
    try {
      await api.cloudOpen(master);
      await onUnlocked();
    } catch (e) {
      setNote(mapUnlockError(cleanError(String(e))));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="cloud-form qr-form">
      {status !== "needs_master" && (
        <div className="qr-card">
          {qr ? (
            <div className="qr-svg" dangerouslySetInnerHTML={{ __html: qr.qr_svg }} />
          ) : (
            <div className="qr-placeholder">{status === "starting" ? "生成二维码…" : "二维码已过期"}</div>
          )}
        </div>
      )}

      {status === "waiting" && (
        <div className="qr-status">{note ?? "等待手机确认…"}</div>
      )}

      {status === "expired" && (
        <>
          <div className="qr-status">{note ?? "二维码已过期，请刷新后重试。"}</div>
          <button className="btn primary cloud-submit" onClick={() => void start()}>
            <Icon name="refresh" size={16} /> 刷新二维码
          </button>
        </>
      )}

      {status === "needs_master" && (
        <div className="cloud-field">
          <div className="qr-status">{note ?? "手机已授权，请输入主密码解锁"}</div>
          <div className="cloud-input-wrap">
            <input
              className="input cloud-input"
              type={showMaster ? "text" : "password"}
              placeholder="密码库主密码"
              value={master}
              autoFocus
              onChange={(e) => setMaster(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && void unlockWithMaster()}
              disabled={busy}
            />
            <button
              className="icon-btn eye-btn"
              title={showMaster ? "隐藏密码" : "显示密码"}
              onClick={() => setShowMaster((v) => !v)}
            >
              <Icon name={showMaster ? "visibility_off" : "visibility"} size={16} />
            </button>
          </div>
          <button className="btn primary cloud-submit" onClick={() => void unlockWithMaster()} disabled={busy}>
            {busy ? <span className="btn-spinner" /> : "解锁"}
          </button>
        </div>
      )}

      <button className="link-btn cloud-switch" onClick={onBack}>
        返回手动输入
      </button>
    </div>
  );
}
