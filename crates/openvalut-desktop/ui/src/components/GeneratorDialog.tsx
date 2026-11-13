import { useEffect, useState } from "react";
import { useVault } from "../store";
import { api } from "../api";

export default function GeneratorDialog() {
  const openGenerator = useVault((s) => s.openGenerator);
  const [length, setLength] = useState(20);
  const [uppercase, setUppercase] = useState(true);
  const [digits, setDigits] = useState(true);
  const [symbols, setSymbols] = useState(true);
  const [value, setValue] = useState("");

  const generate = async () => {
    setValue(await api.passwordGenerate(length, uppercase, digits, symbols));
  };

  useEffect(() => {
    void generate();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [length, uppercase, digits, symbols]);

  return (
    <div className="overlay" onClick={() => openGenerator(false)}>
      <div className="modal" onClick={(e) => e.stopPropagation()} style={{ width: 420 }}>
        <h2>密码生成器</h2>
        <div className="gen-result">{value}</div>
        <div className="form-row">
          <label>长度 {length}</label>
          <input
            type="range"
            min={4}
            max={64}
            value={length}
            onChange={(e) => setLength(Number(e.target.value))}
            style={{ flex: 1 }}
          />
        </div>
        <div style={{ display: "flex", padding: "4px 0 10px" }}>
          <label className="form-check">
            <input
              type="checkbox"
              checked={uppercase}
              onChange={(e) => setUppercase(e.target.checked)}
            />
            大写字母 A-Z
          </label>
          <label className="form-check">
            <input type="checkbox" checked={digits} onChange={(e) => setDigits(e.target.checked)} />
            数字 0-9
          </label>
          <label className="form-check">
            <input
              type="checkbox"
              checked={symbols}
              onChange={(e) => setSymbols(e.target.checked)}
            />
            符号 !@#$
          </label>
        </div>
        <div className="footer">
          <button className="btn" onClick={() => void api.clipboardCopy(value, true)}>
            复制
          </button>
          <button className="btn" onClick={() => void generate()}>
            重新生成
          </button>
          <button className="btn primary" onClick={() => openGenerator(false)}>
            关闭
          </button>
        </div>
      </div>
    </div>
  );
}
