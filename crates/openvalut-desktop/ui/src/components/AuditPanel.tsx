import { useVault } from "../store";
import { api, type AuditIssue } from "../api";
import { entryVisual } from "../visual";

const KIND_LABEL: Record<AuditIssue["kind"], string> = {
  weak: "弱密码",
  reused: "重复使用",
  old: "长期未改",
  duplicate: "重复条目",
};

const KIND_CLASS: Record<AuditIssue["kind"], string> = {
  weak: "weak",
  reused: "reused",
  old: "old",
  duplicate: "duplicate",
};

function detailOf(issue: AuditIssue): string {
  if (issue.kind === "weak") return `强度评分 ${issue.score}/4，很容易被猜出`;
  if (issue.kind === "reused") return `同一密码在 ${issue.reuse_count} 个条目中使用`;
  if (issue.kind === "duplicate")
    return `${issue.duplicate_count} 个条目同名同账号，「清理重复」会保留最近修改的一条`;
  return `已 ${issue.days_since_update} 天未更新`;
}

function IssueRow({
  issue,
  onTrash,
  onClean,
}: {
  issue: AuditIssue;
  onTrash?: () => void;
  onClean?: () => void;
}) {
  const select = useVault((s) => s.select);
  const selectedUuid = useVault((s) => s.selectedUuid);
  const vis = entryVisual(issue.title);

  return (
    <div
      className={`item audit-item${selectedUuid === issue.uuid ? " sel" : ""}`}
      onClick={() => select(issue.uuid)}
    >
      <div className="favicon" style={{ background: vis.background }}>
        {vis.letter}
      </div>
      <div className="meta">
        <div className="t">{issue.title || "(无标题)"}</div>
        <div className="s">
          {issue.username || issue.group}
          <span className="audit-detail"> · {detailOf(issue)}</span>
        </div>
      </div>
      {onTrash && (
        <button className="icon-btn" title="移入回收站" onClick={onTrash}>
          ×
        </button>
      )}
      {onClean && (
        <button
          className="btn"
          title="除最近修改的一条外，其余移入回收站"
          onClick={(e) => {
            e.stopPropagation();
            onClean();
          }}
        >
          清理重复
        </button>
      )}
      <span className={`minitag ${KIND_CLASS[issue.kind]}`}>{KIND_LABEL[issue.kind]}</span>
    </div>
  );
}

export default function AuditPanel() {
  const audit = useVault((s) => s.audit);
  const auditLoading = useVault((s) => s.auditLoading);
  const runAudit = useVault((s) => s.runAudit);
  const refresh = useVault((s) => s.refresh);
  const setError = useVault((s) => s.setError);

  if (!audit) {
    return (
      <div className="listcol">
        <div className="audit-empty">{auditLoading ? "正在扫描…" : "尚未扫描"}</div>
      </div>
    );
  }

  const total =
    audit.weak.length + audit.reused.length + audit.old.length + audit.duplicates.length;

  const trash = async (uuid: string) => {
    await api.entryTrash(uuid);
    await refresh();
    await runAudit();
  };

  const cleanGroup = async (issue: AuditIssue) => {
    try {
      await api.entryTrashDuplicates(issue.title, issue.username);
      await refresh();
      await runAudit();
    } catch (e) {
      setError(String(e));
    }
  };

  return (
    <div className="listcol">
      <div className="audit-head">
        <div className="audit-summary">
          <div className={`audit-score ${total === 0 ? "good" : "bad"}`}>
            {total === 0 ? "未发现问题" : `发现 ${total} 个问题`}
          </div>
          <div className="audit-sub">
            已扫描 {audit.entry_count} 个条目
            {total > 0 && "，点击条目查看详情"}
          </div>
        </div>
        <button className="btn" onClick={() => void runAudit()}>
          重新扫描
        </button>
      </div>
      <div className="items">
        {total === 0 && (
          <div className="audit-empty">
            所有密码强度良好、没有复用、更新及时，也没有同名条目。
          </div>
        )}
        {audit.weak.map((i) => (
          <IssueRow key={`w-${i.uuid}`} issue={i} />
        ))}
        {audit.reused.map((i) => (
          <IssueRow key={`r-${i.uuid}`} issue={i} />
        ))}
        {audit.old.map((i) => (
          <IssueRow key={`o-${i.uuid}`} issue={i} />
        ))}
        {audit.duplicates.map((i) => (
          <IssueRow
            key={`d-${i.uuid}`}
            issue={i}
            onTrash={() => void trash(i.uuid)}
            onClean={() => void cleanGroup(i)}
          />
        ))}
      </div>
    </div>
  );
}
