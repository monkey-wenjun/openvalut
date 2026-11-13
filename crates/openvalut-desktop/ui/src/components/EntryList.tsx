import { useEffect, useRef, useState } from "react";
import { useVault } from "../store";
import { api, type EntryDto } from "../api";
import { hasSsh, hasTotp, inGroup, isCliReadable } from "../entryFilters";
import { entryVisual } from "../visual";
import AuditPanel from "./AuditPanel";
import Icon from "./Icon";

type Menu = { x: number; y: number; uuid: string };

export default function EntryList() {
  const entries = useVault((s) => s.entries);
  const trashed = useVault((s) => s.trashed);
  const groups = useVault((s) => s.groups);
  const meta = useVault((s) => s.meta);
  const search = useVault((s) => s.search);
  const setSearch = useVault((s) => s.setSearch);
  const section = useVault((s) => s.section);
  const selectedUuid = useVault((s) => s.selectedUuid);
  const select = useVault((s) => s.select);
  const refresh = useVault((s) => s.refresh);
  const openEditor = useVault((s) => s.openEditor);
  const editorOpen = useVault((s) => s.editorOpen);
  const searchRef = useRef<HTMLInputElement>(null);

  const [menu, setMenu] = useState<Menu | null>(null);
  const [subOpen, setSubOpen] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const creating = editorOpen !== false && editorOpen.mode === "create";

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        searchRef.current?.focus();
      }
      if (e.key === "Escape") setMenu(null);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    if (!menu) return;
    const close = () => setMenu(null);
    window.addEventListener("click", close);
    return () => window.removeEventListener("click", close);
  }, [menu]);

  useEffect(() => {
    void refresh();
  }, [section, refresh]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast((t) => (t === msg ? null : t)), 2600);
  };

  const entryByUuid = (uuid: string): EntryDto | undefined =>
    (section === "trash" ? trashed : entries).find((e) => e.uuid === uuid);

  const moveTo = async (entry: EntryDto, group: string) => {
    const otp = entry.custom.find((c) => c.key === "OTPAuth")?.value ?? "";
    await api.entryUpdate(entry.uuid, {
      title: entry.title,
      username: entry.username,
      password: entry.password,
      url: entry.url,
      notes: entry.notes,
      group,
      otp,
    });
    setMenu(null);
    await refresh();
  };

  const doTrash = async (entry: EntryDto) => {
    setMenu(null);
    await api.entryTrash(entry.uuid);
    await refresh();
  };

  const doRestore = async (entry: EntryDto) => {
    setMenu(null);
    await api.entryRestore(entry.uuid);
    await refresh();
  };

  const doDeleteForever = async (entry: EntryDto) => {
    setMenu(null);
    await api.entryDelete(entry.uuid);
    await refresh();
  };

  const toggleCliRead = async (entry: EntryDto) => {
    setMenu(null);
    const allowed = isCliReadable(entry);
    try {
      await api.entrySetCliRead(entry.uuid, !allowed);
      await refresh();
      showToast(
        allowed
          ? "已禁止 CLI/脚本读取此条目。"
          : "已允许 openvalut-cli list/get 与本地凭据服务读取此条目（保存后生效）。",
      );
    } catch (e) {
      showToast(`设置失败：${String(e)}`);
    }
  };

  if (section === "audit") {
    return <AuditPanel />;
  }

  const byType = (e: EntryDto) => {
    if (typeof section === "object" && "type" in section) {
      if (section.type === "totp") return hasTotp(e);
      if (section.type === "ssh") return hasSsh(e);
      return !hasTotp(e) && !hasSsh(e);
    }
    return true;
  };

  const list =
    section === "trash"
      ? trashed
      : section === "all"
        ? entries
        : typeof section === "object" && "group" in section
          ? entries.filter((e) => inGroup(e, section.group))
          : entries.filter(byType);

  const q = search.trim().toLowerCase();
  const shown = (
    section === "trash"
      ? [...trashed]
      : [...list].sort((a, b) => a.title.localeCompare(b.title, "zh-CN"))
  ).filter((e) => {
    if (!q || section === "trash") return true;
    const hay = `${e.title} ${e.username} ${e.url} ${e.group}`.toLowerCase();
    return hay.includes(q);
  });

  const menuEntry = menu ? entryByUuid(menu.uuid) : undefined;

  return (
    <div className="listcol">
      <div className="list-head">
        <div className="search">
          <span><Icon name="search" size={13} /></span>
          <input
            ref={searchRef}
            placeholder={section === "trash" ? "搜索回收站…" : "搜索标题、用户名、网址…"}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            disabled={section === "trash"}
          />
          <span className="kbd">Ctrl K</span>
        </div>
      </div>
      <div className="items">
        {creating && (
          <div className="item sel draft" onClick={() => setMenu(null)}>
            <div className="favicon" style={{ background: "var(--accent)" }}>
              +
            </div>
            <div className="meta">
              <div className="t">新条目…</div>
              <div className="s">在右侧填写后保存</div>
            </div>
          </div>
        )}
        {shown.length === 0 && !creating && (
          <div style={{ padding: 20, fontSize: 12.5, color: "var(--text-3)", textAlign: "center" }}>
            没有条目
          </div>
        )}
        {shown.map((e) => {
          const vis = entryVisual(e.title);
          const withTotp = hasTotp(e);
          const withSsh = hasSsh(e);
          return (
            <div
              key={e.uuid}
              className={`item${selectedUuid === e.uuid ? " sel" : ""}`}
              onClick={() => select(e.uuid)}
              onContextMenu={(ev) => {
                ev.preventDefault();
                select(e.uuid);
                setSubOpen(false);
                setMenu({ x: ev.clientX, y: ev.clientY, uuid: e.uuid });
              }}
            >
              <div className="favicon" style={{ background: vis.background }}>
                {vis.letter}
              </div>
              <div className="meta">
                <div className="t">{e.title || "(无标题)"}</div>
                <div className="s">{e.username || e.url || e.group}</div>
                {(withTotp || withSsh) && (
                  <div className="tags-r">
                    {withTotp && <span className="minitag totp">TOTP</span>}
                    {withSsh && <span className="minitag ssh">SSH</span>}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {menu && menuEntry && (
        <div
          className="ctx-menu"
          style={{ left: Math.min(menu.x, window.innerWidth - 190), top: Math.min(menu.y, window.innerHeight - 220) }}
          onClick={(e) => e.stopPropagation()}
        >
          {section === "trash" ? (
            <>
              <button className="ctx-item" onClick={() => void doRestore(menuEntry)}>
                <Icon name="restore" size={14} /> 恢复
              </button>
              <button className="ctx-item danger" onClick={() => void doDeleteForever(menuEntry)}>
                <Icon name="delete" size={14} /> 彻底删除
              </button>
            </>
          ) : (
            <>
              <button
                className="ctx-item"
                onClick={() => {
                  setMenu(null);
                  openEditor({ mode: "edit", uuid: menuEntry.uuid });
                }}
              >
                <Icon name="edit" size={14} /> 编辑
              </button>
              <button className="ctx-item" onClick={() => setSubOpen((v) => !v)}>
                <Icon name="folder" size={14} /> 移动到分组 <span className="ctx-arrow">›</span>
              </button>
              {subOpen && (
                <div className="ctx-sub">
                  <button className="ctx-item" onClick={() => void moveTo(menuEntry, "")}>
                    {meta?.name || "根分组"}
                  </button>
                  {groups.map((g) => (
                    <button key={g.path} className="ctx-item" onClick={() => void moveTo(menuEntry, g.path)}>
                      {g.path}
                    </button>
                  ))}
                </div>
              )}
              <button className="ctx-item" onClick={() => void toggleCliRead(menuEntry)}>
                <Icon name="terminal" size={14} />{" "}
                {isCliReadable(menuEntry) ? "禁止 CLI/脚本读取" : "允许 CLI/脚本读取"}
                {isCliReadable(menuEntry) && <span className="ctx-check">✓</span>}
              </button>
              <div className="ctx-sep" />
              <button className="ctx-item danger" onClick={() => void doTrash(menuEntry)}>
                <Icon name="delete" size={14} /> 删除
              </button>
            </>
          )}
        </div>
      )}

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
