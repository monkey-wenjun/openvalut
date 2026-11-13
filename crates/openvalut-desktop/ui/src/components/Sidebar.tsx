import { useEffect, useState } from "react";
import { useVault, type Section } from "../store";
import { api, type GroupInfo } from "../api";
import { hasSsh, hasTotp, inGroup, isCliReadable } from "../entryFilters";
import Icon, { type IconName } from "./Icon";

type Menu = { x: number; y: number; group: GroupInfo };

/** Text input or confirmation, used by every group mutation. */
type Dialog = {
  title: string;
  label?: string;
  initial?: string;
  confirmText: string;
  danger?: boolean;
  run: (value: string) => Promise<void>;
};

export default function Sidebar() {
  const entries = useVault((s) => s.entries);
  const trashed = useVault((s) => s.trashed);
  const groups = useVault((s) => s.groups);
  const section = useVault((s) => s.section);
  const setSection = useVault((s) => s.setSection);
  const openGenerator = useVault((s) => s.openGenerator);
  const refresh = useVault((s) => s.refresh);
  const setError = useVault((s) => s.setError);

  const [menu, setMenu] = useState<Menu | null>(null);
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [value, setValue] = useState("");
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!menu) return;
    const close = () => setMenu(null);
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setMenu(null);
    };
    window.addEventListener("click", close);
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("click", close);
      window.removeEventListener("keydown", onKey);
    };
  }, [menu]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast((t) => (t === msg ? null : t)), 2600);
  };

  const ask = (next: Dialog) => {
    setValue(next.initial ?? "");
    setDialog(next);
  };

  const submit = async () => {
    if (!dialog) return;
    const run = dialog.run;
    setDialog(null);
    try {
      await run(value.trim());
      await refresh();
    } catch (e) {
      setError(String(e));
    }
  };

  const groupAction = (group: GroupInfo, action: "rename" | "child" | "trash") => {
    setMenu(null);
    if (action === "rename") {
      ask({
        title: "重命名分组",
        label: "分组名（不能包含 /）",
        initial: group.name,
        confirmText: "重命名",
        run: async (name) => {
          await api.groupRename(group.uuid, name);
        },
      });
    } else if (action === "child") {
      ask({
        title: `在「${group.name}」下新建子分组`,
        label: "子分组名",
        confirmText: "创建",
        run: async (name) => {
          await api.groupCreate(`${group.path}/${name}`);
        },
      });
    } else {
      const inside = entries.filter((e) => inGroup(e, group.path)).length;
      ask({
        title: "删除分组",
        label: `「${group.name}」和其中 ${inside} 个条目将移入回收站，可以恢复。`,
        confirmText: "移入回收站",
        danger: true,
        run: async () => {
          await api.groupTrash(group.uuid);
        },
      });
    }
  };

  const setGroupCliRead = async (group: GroupInfo, allowed: boolean) => {
    setMenu(null);
    try {
      const changed = await api.groupSetCliRead(group.uuid, allowed);
      await refresh();
      showToast(
        allowed
          ? `已允许 ${changed} 个条目被 CLI/脚本读取（保存后生效）。`
          : `已禁止 ${changed} 个条目被 CLI/脚本读取。`,
      );
    } catch (e) {
      showToast(`设置失败：${String(e)}`);
    }
  };

  const is = (s: Section) => JSON.stringify(section) === JSON.stringify(s);
  const totpCount = entries.filter(hasTotp).length;
  const sshCount = entries.filter(hasSsh).length;
  const menuItem = menu?.group;
  const menuBranch = menuItem ? entries.filter((e) => inGroup(e, menuItem.path)) : [];
  const menuAllReadable = menuBranch.length > 0 && menuBranch.every(isCliReadable);

  const row = (
    label: string,
    icon: IconName,
    active: boolean,
    onClick: () => void,
    count?: number,
  ) => (
    <button className={`side-item${active ? " active" : ""}`} onClick={onClick}>
      <span className="ico">
        <Icon name={icon} />
      </span>
      {label}
      {count !== undefined && <span className="count">{count}</span>}
    </button>
  );

  return (
    <div className="sidebar">
      <div className="side-label">密码库</div>
      {row("所有条目", "list", is("all"), () => setSection("all"), entries.length)}

      <div className="side-sep" />
      <div className="side-label">分组</div>
      {groups.length === 0 && (
        <div style={{ fontSize: 12, color: "var(--text-3)", padding: "0 10px" }}>暂无分组</div>
      )}
      {groups.map((g) => {
        const s: Section = { group: g.path };
        const depth = g.path.split("/").length - 1;
        return (
          <button
            key={g.uuid}
            className={`side-item${is(s) ? " active" : ""}`}
            style={{ paddingLeft: 10 + depth * 14 }}
            onClick={() => setSection(s)}
            onContextMenu={(ev) => {
              ev.preventDefault();
              setMenu({ x: ev.clientX, y: ev.clientY, group: g });
            }}
          >
            <span className="ico">
              <Icon name="folder" />
            </span>
            <span
              style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}
              title={g.path}
            >
              {g.name}
            </span>
            <span className="count">{g.entry_count}</span>
          </button>
        );
      })}
      <button
        className="side-item"
        onClick={() =>
          ask({
            title: "新建分组",
            label: "分组名，可用 / 分隔多级，如：工作/邮箱",
            confirmText: "创建",
            run: (path) => api.groupCreate(path).then(() => undefined),
          })
        }
      >
        <span className="ico">
          <Icon name="create_new_folder" />
        </span>
        新建分组
      </button>

      <div className="side-sep" />
      <div className="side-label">类型</div>
      {row("验证码 TOTP", "timer", is({ type: "totp" }), () => setSection({ type: "totp" }), totpCount)}
      {row("SSH 密钥", "computer", is({ type: "ssh" }), () => setSection({ type: "ssh" }), sshCount)}
      {row(
        "登录凭据",
        "label",
        is({ type: "login" }),
        () => setSection({ type: "login" }),
        entries.filter((e) => !hasTotp(e) && !hasSsh(e)).length,
      )}

      <div className="side-sep" />
      <div className="side-label">其他</div>
      {row("安全体检", "shield", is("audit"), () => setSection("audit"))}
      {row("我的分享", "share", false, () => showToast("云共享接口尚未接入。"))}
      {row("回收站", "delete", is("trash"), () => setSection("trash"), trashed.length)}
      <button className="side-item" onClick={() => openGenerator(true)}>
        <span className="ico">
          <Icon name="casino" />
        </span>
        密码生成器
      </button>

      {menu && menuItem && (
        <div
          className="ctx-menu"
          style={{
            left: Math.min(menu.x, window.innerWidth - 200),
            top: Math.min(menu.y, window.innerHeight - 220),
          }}
          onClick={(e) => e.stopPropagation()}
          onContextMenu={(e) => {
            e.preventDefault();
            setMenu(null);
          }}
        >
          <button className="ctx-item" onClick={() => void groupAction(menuItem, "rename")}>
            <Icon name="edit" size={14} /> 重命名分组
          </button>
          <button className="ctx-item" onClick={() => void groupAction(menuItem, "child")}>
            <Icon name="create_new_folder" size={14} /> 新增子分组
          </button>
          <div className="ctx-sep" />
          <button
            className="ctx-item"
            onClick={() => void setGroupCliRead(menuItem, !menuAllReadable)}
          >
            <Icon name="terminal" size={14} />{" "}
            {menuAllReadable ? "禁止 CLI/脚本读取" : "允许 CLI/脚本读取"}
            {menuAllReadable && <span className="ctx-check">✓</span>}
          </button>
          <div className="ctx-sep" />
          <button
            className="ctx-item danger"
            onClick={() => void groupAction(menuItem, "trash")}
          >
            <Icon name="delete" size={14} /> 删除分组
          </button>
        </div>
      )}

      {dialog && (
        <div className="overlay" onClick={() => setDialog(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} style={{ width: 380 }}>
            <h2>{dialog.title}</h2>
            {dialog.label &&
              (dialog.danger ? (
                <p style={{ fontSize: 12.5, color: "var(--text-2)" }}>{dialog.label}</p>
              ) : (
                <div className="form-row">
                  <label>{dialog.label}</label>
                  <input
                    className="input"
                    autoFocus
                    value={value}
                    onChange={(e) => setValue(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter") void submit();
                    }}
                  />
                </div>
              ))}
            <div className="footer">
              <button className="btn" onClick={() => setDialog(null)}>
                取消
              </button>
              <button
                className={`btn${dialog.danger ? "" : " primary"}`}
                disabled={!dialog.danger && !value.trim()}
                onClick={() => void submit()}
              >
                {dialog.confirmText}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && <div className="toast">{toast}</div>}
    </div>
  );
}
