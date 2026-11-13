import { useVault, toggleTheme } from "../store";
import Icon from "./Icon";

export default function Topbar() {
  const meta = useVault((s) => s.meta);
  const lock = useVault((s) => s.lock);
  const save = useVault((s) => s.save);
  const openEditor = useVault((s) => s.openEditor);
  const openSettings = useVault((s) => s.openSettings);

  if (!meta) return null;

  return (
    <div className="topbar">
      <div className="brand">
        <Icon name="shield" size={16} />
        openvalut
      </div>
      <div className="vault-chip">
        <span className={`dot${meta.dirty ? " dirty" : ""}`} />
        {meta.name ?? "密码库"} · {meta.dirty ? "有未保存更改" : "已保存"} · {meta.entry_count} 个条目
      </div>
      <button className="btn" onClick={() => openEditor({ mode: "create" })}>
        <Icon name="add" /> 新建条目
      </button>
      <button className="btn" onClick={() => void save()} disabled={!meta.dirty}>
        保存
      </button>
      <button className="btn" onClick={() => void toggleTheme()} title="切换主题">
        <Icon name="moon" />
      </button>
      <button className="btn" onClick={() => openSettings(true)} title="设置">
        <Icon name="settings" />
      </button>
      <button className="btn" onClick={() => void lock()}>
        <Icon name="lock" /> 锁定
      </button>
    </div>
  );
}
