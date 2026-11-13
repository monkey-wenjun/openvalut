import { useState } from "react";
import { api } from "../api";
import Icon from "./Icon";

/// Mirrors Dart `formatSecretKey`: strip dashes, uppercase, 4-char groups.
export function formatSecretKey(key: string) {
  const clean = key.replace(/-/g, "").toUpperCase();
  const groups = [];
  for (let i = 0; i < 8; i += 1) {
    groups.push(clean.substring(i * 4, i * 4 + 4));
  }
  return groups.join("-");
}

export default function SecretKeyDialog({
  secretKey,
  email,
  onDone,
}: {
  secretKey: string;
  email: string;
  onDone: () => void;
}) {
  const formatted = formatSecretKey(secretKey);
  const [note, setNote] = useState<string | null>(null);

  const copy = () => {
    void api
      .clipboardCopy(formatted, false)
      .then(() => setNote("已复制到剪贴板"))
      .catch((e) => setNote(String(e)));
  };

  const saveToFile = async () => {
    const suggested = `openvalut-secret-key-${email.replace(/@/g, "_at_")}.txt`;
    try {
      const path = await api.dialogPickSavePath(suggested);
      if (!path) return;
      const content =
        "OpenValut Cloud Secret Key\n" +
        "========================\n" +
        `账号：${email}\n` +
        `Secret Key：${formatted}\n` +
        "\n" +
        "登录时需要：邮箱 + Secret Key + 主密码\n" +
        "此密钥无法找回，请妥善保管。\n";
      await api.fileWriteText(path, content);
      setNote("Secret Key 已保存到本地文件，请妥善保管。");
    } catch (e) {
      setNote(`无法保存 Secret Key：${String(e).replace(/^Error: /, "")}`);
    }
  };

  return (
    <div className="overlay">
      <div className="modal small secret-modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-title">保存你的 Secret Key</div>
        <div className="secret-desc">
          这是你 OpenValut Cloud 账号的唯一身份密钥（账号 UUID）。登录时需要 邮箱 + Secret Key +
          主密码。此密钥无法找回，请立即复制并妥善保存；也可以稍后跳过。
        </div>
        <div className="secret-key-box">{formatted}</div>
        {note && <div className="secret-note">{note}</div>}
        <button className="btn secret-save-btn" onClick={() => void saveToFile()}>
          <Icon name="save_alt" size={15} /> 保存到本地文件
        </button>
        <div className="modal-actions">
          <button className="link-btn" onClick={copy}>
            <Icon name="content_copy" size={15} /> 复制
          </button>
          <button className="link-btn" onClick={onDone}>
            跳过
          </button>
          <button className="btn primary" onClick={onDone}>
            我已保存并继续
          </button>
        </div>
      </div>
    </div>
  );
}
