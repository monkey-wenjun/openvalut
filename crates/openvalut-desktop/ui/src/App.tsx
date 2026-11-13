import { useEffect } from "react";
import { useVault } from "./store";
import LockedScreen from "./components/LockedScreen";
import Topbar from "./components/Topbar";
import Sidebar from "./components/Sidebar";
import EntryList from "./components/EntryList";
import EntryDetail from "./components/EntryDetail";
import EntryEditor from "./components/EntryEditor";
import GeneratorDialog from "./components/GeneratorDialog";
import SettingsDialog from "./components/SettingsDialog";

export default function App() {
  const init = useVault((s) => s.init);
  const locked = useVault((s) => s.meta === null || s.meta.locked);
  const error = useVault((s) => s.error);
  const editorOpen = useVault((s) => s.editorOpen);
  const generatorOpen = useVault((s) => s.generatorOpen);
  const settingsOpen = useVault((s) => s.settingsOpen);

  useEffect(() => {
    void init();
  }, [init]);

  const settings = settingsOpen ? (
    <SettingsDialog onClose={() => useVault.getState().openSettings(false)} />
  ) : null;

  if (locked) {
    return (
      <>
        <LockedScreen />
        {generatorOpen && <GeneratorDialog />}
        {settings}
      </>
    );
  }

  return (
    <div className="app">
      <Topbar />
      <div className="app-body">
        <Sidebar />
        <EntryList />
        {editorOpen !== false ? <EntryEditor /> : <EntryDetail />}
      </div>
      {generatorOpen && <GeneratorDialog />}
      {settings}
      {error && (
        <div className="overlay" onClick={() => useVault.getState().setError(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h2>出错了</h2>
            <p style={{ fontSize: 13, color: "var(--text-2)", whiteSpace: "pre-wrap" }}>{error}</p>
            <div className="footer">
              <button className="btn primary" onClick={() => useVault.getState().setError(null)}>
                好
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
