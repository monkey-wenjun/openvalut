import { useEffect, useState } from "react";
import { useVault } from "../store";
import { api, type EntryDto, type TotpInfo, type UpdateEntryRequestDto } from "../api";
import { entryVisual } from "../visual";
import Icon from "./Icon";

function CopyButton({ uuid, field, label }: { uuid: string; field: string; label: string }) {
  const [done, setDone] = useState(false);
  return (
    <button
      className="icon-btn"
      title={`复制${label}`}
      onClick={async (e) => {
        e.stopPropagation();
        try {
          const value = await api.entryFieldValue(uuid, field);
          await api.clipboardCopy(value, field === "Password");
          setDone(true);
          setTimeout(() => setDone(false), 1200);
        } catch {
          // field missing — ignore
        }
      }}
    >
      {done ? "✓" : "⧉"}
    </button>
  );
}

function TotpSection({ uuid }: { uuid: string }) {
  const [totp, setTotp] = useState<TotpInfo | null>(null);

  useEffect(() => {
    let cancelled = false;
    const tick = async () => {
      try {
        const t = await api.totpForEntry(uuid);
        if (!cancelled) setTotp(t);
      } catch {
        /* ignore */
      }
    };
    void tick();
    const timer = setInterval(tick, 1000);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, [uuid]);

  if (!totp || !totp.present) return null;
  const code = totp.code ?? "";
  const period = totp.period ?? 30;
  const remaining = totp.remaining ?? period;
  const pct = (remaining / period) * 100;
  const display = code.length > 3 ? `${code.slice(0, code.length - 3)} ${code.slice(-3)}` : code;

  return (
    <div className="totp-box">
      <div>
        <div style={{ fontSize: 11, color: "var(--text-3)", letterSpacing: 1, marginBottom: 2 }}>
          一次性验证码
        </div>
        <div className="totp-code">{display}</div>
      </div>
      <div className="totp-ring" style={{ ["--p" as string]: `${pct}%` }}>
        <i>{remaining}s</i>
      </div>
      <button
        className="icon-btn"
        title="复制验证码"
        onClick={async () => {
          if (totp.code) await api.clipboardCopy(totp.code, true);
        }}
      >
        ⧉
      </button>
    </div>
  );
}

const STRENGTH_LABEL = ["很弱", "弱", "一般", "强", "很强"];
const STRENGTH_COLOR = [
  "var(--red)",
  "var(--red)",
  "var(--amber)",
  "var(--green)",
  "var(--green)",
];

/** `ov://` and friends point at another entry and have no entropy of their own. */
function isReferencePassword(value: string) {
  return value.startsWith("ov://") || value.startsWith("op://") || value.startsWith("{REF:");
}

/**
 * A custom field the file keeps as plain text but that is as sensitive as the
 * password row: an SSH private key, or an API secret pasted in. The detail panel
 * sits open on a desk far longer than a password is ever displayed.
 */
function isObscuredField(key: string) {
  const k = key.toLowerCase();
  return k.includes("private-key") || k.includes("private_key") || k.includes("secret");
}

function SecurityPanel({ entry }: { entry: EntryDto }) {
  const entries = useVault((s) => s.entries);
  const meta = useVault((s) => s.meta);
  const [score, setScore] = useState<number | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!entry.password || isReferencePassword(entry.password)) {
      setScore(null);
      setFailed(false);
      return;
    }
    let alive = true;
    setFailed(false);
    api
      .passwordStrength(entry.password, [entry.username, entry.title, entry.url])
      .then((value) => {
        if (alive) setScore(value);
      })
      .catch(() => {
        if (alive) {
          setScore(null);
          setFailed(true);
        }
      });
    return () => {
      alive = false;
    };
  }, [entry.uuid, entry.password, entry.username, entry.title, entry.url]);

  const literal = !!entry.password && !isReferencePassword(entry.password);
  const shared = literal ? entries.filter((e) => e.password === entry.password).length : 0;
  const sameName = entries.filter(
    (e) => e.title === entry.title && e.username === entry.username,
  ).length;
  const word = !literal
    ? entry.password
      ? "引用其他条目的密码"
      : "没有密码"
    : score === null
      ? failed
        ? "评分暂不可用"
        : "计算中…"
      : `${STRENGTH_LABEL[score]} · ${entry.password.length} 位`;

  return (
    <aside className="detail-side">
      <div className="card">
        <div className="card-head">安全评分</div>
        <div className="score-line">
          <b className="score-num" style={{ color: score === null ? "var(--text-3)" : STRENGTH_COLOR[score] }}>
            {score === null ? "—" : score}
          </b>
          <span className="score-word">{word}</span>
        </div>
        <div className="score-bar">
          <i
            style={{
              width: `${score === null ? 0 : ((score + 1) / 5) * 100}%`,
              background: score === null ? "var(--surface-3)" : STRENGTH_COLOR[score],
            }}
          />
        </div>
      </div>

      <div className="card">
        <div className="card-head">安全报告</div>
        <div className="side-row">
          <span>分组</span>
          <b>{entry.group || meta?.name || "根分组"}</b>
        </div>
        <div className="side-row">
          <span>共用此密码</span>
          <b>{shared > 1 ? `${shared} 个条目` : "仅此条目"}</b>
        </div>
        <div className="side-row">
          <span>同名条目</span>
          <b>{sameName > 1 ? `${sameName} 条，可在安全体检中清理` : "无"}</b>
        </div>
      </div>

      <div className="card">
        <div className="card-head">共享状态</div>
        <div className="side-note">
          云共享与家庭共享接口尚未接入，本条目目前只存在于本地密码库。
        </div>
      </div>
    </aside>
  );
}

function RevealField({ value }: { value: string }) {
  const [revealed, setRevealed] = useState(false);
  return (
    <span className="v-wrap">
      <span className={`v mono${revealed ? "" : " masked"}`}>
        {revealed ? value : "••••••••••••"}
      </span>
      <button className="icon-btn" title="显示 / 隐藏" onClick={() => setRevealed(!revealed)}>
        <Icon name={revealed ? "visibility_off" : "visibility"} size={14} />
      </button>
    </span>
  );
}

type FieldKind = "notes" | "url" | "otp" | "ssh" | "custom";

interface AddOption {
  kind: FieldKind;
  label: string;
  hint: string;
  multiline: boolean;
}

const ADD_OPTIONS: AddOption[] = [
  { kind: "notes", label: "备注", hint: "任意文本", multiline: true },
  { kind: "url", label: "网站", hint: "https://…", multiline: false },
  { kind: "otp", label: "一次性密码", hint: "otpauth://totp/… 或 Base32 密钥", multiline: false },
  { kind: "ssh", label: "SSH 私钥", hint: "粘贴私钥，保存后默认打码", multiline: true },
  {
    kind: "custom",
    label: "自定义字段",
    hint: "自己起名：序列号 / AccessKey / 问题答案…",
    multiline: false,
  },
];

/** Names the file reserves for its own rows; reusing one would bury the value. */
const RESERVED_KEYS = [
  "title",
  "username",
  "password",
  "url",
  "notes",
  "otpauth",
  "ssh-private-key",
  "machine-id",
  "openvalut.read-allowed",
];

function AddFieldRow({ entry, onDone }: { entry: EntryDto; onDone: () => Promise<void> }) {
  const setError = useVault((s) => s.setError);
  const [open, setOpen] = useState(false);
  const [option, setOption] = useState<AddOption | null>(null);
  const [name, setName] = useState("");
  const [value, setValue] = useState("");
  const [busy, setBusy] = useState(false);

  const alreadyThere = (kind: FieldKind) => {
    switch (kind) {
      case "notes":
        return entry.notes.trim().length > 0;
      case "url":
        return entry.url.trim().length > 0;
      case "otp":
        return entry.custom.some((c) => c.key === "OTPAuth");
      case "ssh":
        return entry.custom.some((c) => c.key === "ssh-private-key");
      case "custom":
        return false;
    }
  };
  const options = ADD_OPTIONS.filter((o) => !alreadyThere(o.kind));

  const submit = async () => {
    if (!option) return;
    const request: UpdateEntryRequestDto = {};
    if (option.kind === "custom") {
      const key = name.trim();
      if (!key) {
        setError("请填写字段名");
        return;
      }
      if (RESERVED_KEYS.includes(key.toLowerCase())) {
        setError(`「${key}」是保留名称，换一个`);
        return;
      }
      request.custom = [{ key, value }];
    } else if (option.kind === "notes") {
      request.notes = value;
    } else if (option.kind === "url") {
      request.url = value;
    } else if (option.kind === "otp") {
      request.otp = value;
    } else {
      request.ssh_private_key = value;
    }
    setBusy(true);
    try {
      await api.entryUpdate(entry.uuid, request);
      await onDone();
      setOption(null);
      setName("");
      setValue("");
      setOpen(false);
    } catch (e) {
      setError(String(e));
    } finally {
      setBusy(false);
    }
  };

  if (option) {
    return (
      <div className="field-add">
        <div className="field-add-head">
          <span>添加「{option.label}」</span>
          <button className="link-btn" onClick={() => setOption(null)}>
            取消
          </button>
        </div>
        {option.kind === "custom" && (
          <input
            className="input"
            placeholder="字段名"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        )}
        {option.multiline ? (
          <textarea
            className="input"
            rows={option.kind === "ssh" ? 6 : 3}
            placeholder={option.hint}
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
        ) : (
          <input
            className="input"
            placeholder={option.hint}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") void submit();
            }}
          />
        )}
        <div className="field-add-foot">
          <button
            className="btn primary"
            disabled={busy || !value.trim()}
            onClick={() => void submit()}
          >
            {busy ? "保存中…" : "保存"}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="field-add">
      <button className="link-btn" onClick={() => setOpen(!open)}>
        <Icon name="add" size={14} /> 添加字段
      </button>
      {open && (
        <div className="field-add-list">
          {options.length === 0 && <span className="field-add-none">这些项都已经有了</span>}
          {options.map((o) => (
            <button
              className="field-add-item"
              key={o.kind}
              onClick={() => {
                setOption(o);
                setName("");
                setValue("");
              }}
            >
              <b>{o.label}</b>
              <span>{o.hint}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

export default function EntryDetail() {
  const selectedUuid = useVault((s) => s.selectedUuid);
  const entries = useVault((s) => s.entries);
  const trashed = useVault((s) => s.trashed);
  const meta = useVault((s) => s.meta);
  const section = useVault((s) => s.section);
  const refresh = useVault((s) => s.refresh);
  const openEditor = useVault((s) => s.openEditor);
  const setError = useVault((s) => s.setError);

  const pool = section === "trash" ? trashed : entries;
  const entry: EntryDto | undefined = pool.find((e) => e.uuid === selectedUuid);

  if (!entry) {
    return (
      <div className="detail">
        <div className="detail-empty">从列表中选择一个条目查看详情</div>
      </div>
    );
  }

  const vis = entryVisual(entry.title);
  const standardCustom = entry.custom.filter(
    (c) => c.key !== "OTPAuth" && c.key !== "openvalut.read-allowed",
  );
  const otpRaw = entry.custom.find((c) => c.key === "OTPAuth")?.value ?? "";

  const trashOrRestore = async () => {
    try {
      if (section === "trash") {
        await api.entryRestore(entry.uuid);
      } else {
        await api.entryTrash(entry.uuid);
      }
      await refresh();
    } catch (e) {
      setError(String(e));
    }
  };

  const removeForever = async () => {
    try {
      await api.entryDelete(entry.uuid);
      await refresh();
    } catch (e) {
      setError(String(e));
    }
  };

  return (
    <div className="detail detail-split">
      <div className="detail-scroll">
        <div className="detail-top">
          <div className="detail-icon" style={{ background: vis.background }}>
            {vis.letter}
          </div>
          <div className="detail-title">
            <h1>{entry.title || "(无标题)"}</h1>
            <div className="sub">
              {entry.group || meta?.name || "根分组"} · {section === "trash" ? "回收站" : "登录凭据"}
            </div>
          </div>
          <div className="detail-actions">
            {section !== "trash" && (
              <button className="btn" onClick={() => openEditor({ mode: "edit", uuid: entry.uuid })}>
                <Icon name="edit" /> 编辑
              </button>
            )}
            <button className="btn" onClick={() => void trashOrRestore()}>
              {section === "trash" ? (
                <>
                  <Icon name="restore" /> 恢复
                </>
              ) : (
                <>
                  <Icon name="delete" /> 移到回收站
                </>
              )}
            </button>
            {section === "trash" && (
              <button className="btn danger" onClick={() => void removeForever()}>
                彻底删除
              </button>
            )}
          </div>
        </div>

        <div style={{ marginTop: 24 }}>
          <div className="card">
            <div className="card-head">登录信息</div>
            {entry.username && (
              <div className="field">
                <span className="k">用户名</span>
                <span className="v">{entry.username}</span>
                <span className="ops">
                  <CopyButton uuid={entry.uuid} field="UserName" label="用户名" />
                </span>
              </div>
            )}
            {entry.password && (
              <div className="field">
                <span className="k">密码</span>
                <RevealField value={entry.password} />
                <span className="ops">
                  <CopyButton uuid={entry.uuid} field="Password" label="密码" />
                </span>
              </div>
            )}
            {otpRaw && <TotpSection uuid={entry.uuid} />}
            {entry.url && (
              <div className="field">
                <span className="k">网站</span>
                <span className="v">{entry.url}</span>
                <span className="ops">
                  <button
                    className="icon-btn"
                    title="打开"
                    onClick={() => window.open(entry.url, "_blank")}
                  >
                    ↗
                  </button>
                </span>
              </div>
            )}
            {entry.notes.trim() && (
              <div className="field">
                <span className="k">备注</span>
                <span className="v notes-value">{entry.notes}</span>
                <span className="ops">
                  <CopyButton uuid={entry.uuid} field="Notes" label="备注" />
                </span>
              </div>
            )}
            {standardCustom.map((c) => (
              <div className="field" key={c.key}>
                <span className="k">{c.key}</span>
                {isObscuredField(c.key) ? (
                  <RevealField value={c.value} />
                ) : (
                  <span className="v mono">{c.value}</span>
                )}
                <span className="ops">
                  <CopyButton uuid={entry.uuid} field={c.key} label={c.key} />
                </span>
              </div>
            ))}
            {section !== "trash" && <AddFieldRow entry={entry} onDone={refresh} />}
          </div>
        </div>
      </div>
      <SecurityPanel entry={entry} />
    </div>
  );
}
