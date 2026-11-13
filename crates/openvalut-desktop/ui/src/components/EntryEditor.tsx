import { useEffect, useState } from "react";
import { useVault } from "../store";
import { api, type CustomField, type EntryDto } from "../api";
import Icon from "./Icon";

interface FormState {
  title: string;
  username: string;
  password: string;
  url: string;
  group: string;
  otp: string;
  notes: string;
  custom: CustomField[];
  removedKeys: string[];
}

const EMPTY: FormState = {
  title: "",
  username: "",
  password: "",
  url: "",
  group: "",
  otp: "",
  notes: "",
  custom: [],
  removedKeys: [],
};

/**
 * Fields the editor renders as its own rows instead of as custom fields: sending
 * them back inside `custom` would write the value unprotected under the wrong
 * name.
 */
const EDITOR_OWNED_KEYS = ["OTPAuth", "openvalut.read-allowed", "ssh-private-key"];

function toForm(entry: EntryDto): FormState {
  return {
    title: entry.title,
    username: entry.username,
    password: entry.password,
    url: entry.url,
    group: entry.group,
    otp: entry.custom.find((c) => c.key === "OTPAuth")?.value ?? "",
    notes: entry.notes,
    custom: entry.custom.filter((c) => !EDITOR_OWNED_KEYS.includes(c.key)),
    removedKeys: [],
  };
}

const AUTOSAVE_MS = 900;

type EditorTarget = { mode: "create" } | { mode: "edit"; uuid: string };

export default function EntryEditor() {
  const editorOpen = useVault((s) => s.editorOpen);
  if (editorOpen === false) return null;
  // Keyed by target so switching entries remounts the form and drops any
  // autosave timer still pending for the previous one.
  return (
    <div className="detail">
      <div className="detail-scroll editor-inline">
        <EditorForm
          key={editorOpen.mode === "edit" ? editorOpen.uuid : "new"}
          target={editorOpen}
        />
      </div>
    </div>
  );
}

function EditorForm({ target }: { target: EditorTarget }) {
  const entries = useVault((s) => s.entries);
  const groups = useVault((s) => s.groups);
  const refresh = useVault((s) => s.refresh);
  const openEditor = useVault((s) => s.openEditor);
  const select = useVault((s) => s.select);

  const [form, setForm] = useState<FormState>(EMPTY);
  const [uuid, setUuid] = useState<string | null>(null);
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [failure, setFailure] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);

  // Opening (or switching) the editor is the only thing that loads a form: a
  // refresh landing from a background `vault:changed` must not wipe what the
  // user is typing.
  useEffect(() => {
    const want = target.mode === "edit" ? target.uuid : null;
    const entry = want ? entries.find((e) => e.uuid === want) : undefined;
    setUuid(want);
    setForm(entry ? toForm(entry) : EMPTY);
    setDirty(false);
    setSaved(false);
    setFailure(null);
  }, [target]);

  const set = (patch: Partial<FormState>) => {
    setForm((f) => ({ ...f, ...patch }));
    setDirty(true);
    setSaved(false);
  };

  const persist = async () => {
    if (!form.title.trim()) return;
    setSaving(true);
    const custom = form.custom.filter((c) => c.key.trim().length > 0);
    try {
      if (uuid) {
        await api.entryUpdate(uuid, {
          title: form.title,
          username: form.username,
          password: form.password,
          url: form.url,
          notes: form.notes,
          group: form.group,
          otp: form.otp,
          custom,
          remove_custom: form.removedKeys,
        });
        setForm((f) => (f.removedKeys.length ? { ...f, removedKeys: [] } : f));
      } else {
        const created = await api.entryCreate({
          title: form.title,
          username: form.username,
          password: form.password,
          url: form.url,
          notes: form.notes,
          group: form.group,
          otp: form.otp,
          custom,
        });
        // From here on this editor edits that entry: without the switch every
        // autosave tick would create another one.
        setUuid(created);
        select(created);
      }
      await refresh();
      setDirty(false);
      setSaved(true);
      setFailure(null);
    } catch (e) {
      // Autosave failures stay in the footer: a background dialog would
      // interrupt typing, and the draft is still on screen.
      setFailure(String(e));
    } finally {
      setSaving(false);
    }
  };

  useEffect(() => {
    if (!dirty || saving) return;
    const timer = setTimeout(() => void persist(), AUTOSAVE_MS);
    return () => clearTimeout(timer);
  });

  const saveNow = () => void persist();

  const touch = () => {
    setDirty(true);
    setSaved(false);
  };

  const setCustom = (index: number, patch: Partial<CustomField>) => {
    setForm((f) => {
      const old = f.custom[index];
      const custom = f.custom.map((c, i) => (i === index ? { ...c, ...patch } : c));
      // The backend only ever adds or overwrites a field name, so renaming a
      // field has to ask for the old name to be deleted or the entry ends up
      // with both.
      const renamed = patch.key !== undefined && old.key.trim() && old.key !== patch.key;
      return {
        ...f,
        custom,
        removedKeys: renamed && !f.removedKeys.includes(old.key) ? [...f.removedKeys, old.key] : f.removedKeys,
      };
    });
    touch();
  };

  const addCustom = () => {
    setForm((f) => ({ ...f, custom: [...f.custom, { key: "", value: "" }] }));
    touch();
  };

  const dropCustom = (index: number) => {
    setForm((f) => {
      const gone = f.custom[index];
      return {
        ...f,
        custom: f.custom.filter((_, i) => i !== index),
        removedKeys:
          gone.key.trim() && !f.removedKeys.includes(gone.key)
            ? [...f.removedKeys, gone.key]
            : f.removedKeys,
      };
    });
    touch();
  };

  const body = (
    <>
      <h2>{uuid ? "编辑条目" : "新建条目"}</h2>
      <div className="form-row">
        <label>标题</label>
        <input
          className="input"
          value={form.title}
          onChange={(e) => set({ title: e.target.value })}
          autoFocus
        />
      </div>
      <div className="form-row">
        <label>用户名</label>
        <input
          className="input"
          value={form.username}
          onChange={(e) => set({ username: e.target.value })}
        />
      </div>
      <div className="form-row">
        <label>密码</label>
        <div className="cloud-input-wrap grow">
          <input
            className="input"
            type={showPassword ? "text" : "password"}
            value={form.password}
            onChange={(e) => set({ password: e.target.value })}
            style={{ fontFamily: "ui-monospace, monospace" }}
          />
          <button
            className="icon-btn eye-btn"
            title={showPassword ? "隐藏密码" : "显示密码"}
            onClick={() => setShowPassword((v) => !v)}
          >
            <Icon name={showPassword ? "visibility_off" : "visibility"} size={16} />
          </button>
        </div>
        <button
          className="btn"
          title="生成强密码"
          onClick={async () => set({ password: await api.passwordGenerate() })}
        >
          <Icon name="casino" />
        </button>
        <button className="btn" onClick={() => void api.clipboardCopy(form.password, true)}>
          复制
        </button>
      </div>
      <div className="form-row">
        <label>网址</label>
        <input
          className="input"
          value={form.url}
          onChange={(e) => set({ url: e.target.value })}
          placeholder="https://…"
        />
      </div>
      <div className="form-row">
        <label>分组</label>
        <input
          className="input"
          list="group-options"
          value={form.group}
          onChange={(e) => set({ group: e.target.value })}
          placeholder="可用 / 分隔多级，如：工作/邮箱"
        />
        <datalist id="group-options">
          {groups.map((g) => (
            <option key={g.path} value={g.path} />
          ))}
        </datalist>
      </div>
      <div className="form-row">
        <label>验证码 TOTP</label>
        <input
          className="input"
          value={form.otp}
          onChange={(e) => set({ otp: e.target.value })}
          placeholder="otpauth://totp/… 或 base32 密钥"
        />
      </div>
      <div className="form-row" style={{ alignItems: "flex-start" }}>
        <label style={{ paddingTop: 8 }}>备注</label>
        <textarea
          className="input"
          rows={4}
          style={{ resize: "vertical", minHeight: 70 }}
          value={form.notes}
          onChange={(e) => set({ notes: e.target.value })}
        />
      </div>
      <div className="form-row" style={{ alignItems: "flex-start" }}>
        <label style={{ paddingTop: 8 }}>自定义字段</label>
        <div className="custom-fields">
          {form.custom.map((c, i) => (
            <div className="custom-field" key={i}>
              <input
                className="input"
                value={c.key}
                placeholder="名称"
                onChange={(e) => setCustom(i, { key: e.target.value })}
              />
              <input
                className="input grow"
                value={c.value}
                placeholder="值"
                onChange={(e) => setCustom(i, { value: e.target.value })}
              />
              <button
                className="icon-btn"
                title="删除字段"
                onClick={() => dropCustom(i)}
              >
                <Icon name="delete" size={14} />
              </button>
            </div>
          ))}
          <button className="link-btn" onClick={addCustom}>
            <Icon name="add" size={14} /> 添加字段
          </button>
        </div>
      </div>
      <div className="footer">
        <span className="save-state">
          {failure
            ? `保存失败：${failure}`
            : saving
              ? "保存中…"
              : dirty
                ? "有未保存的修改（停顿后自动保存）"
                : saved
                  ? "已自动保存"
                  : ""}
        </span>
        <button className="btn" onClick={() => openEditor(false)}>
          取消
        </button>
        <button className="btn primary" disabled={saving} onClick={saveNow}>
          保存
        </button>
      </div>
    </>
  );

  return body;
}
