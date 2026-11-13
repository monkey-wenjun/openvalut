import { create } from "zustand";
import { listen } from "@tauri-apps/api/event";
import { api, type AuditReport, type EntryDto, type GroupInfo, type VaultMeta } from "./api";

export type Section =
  | "all"
  | "trash"
  | "audit"
  | { group: string }
  | { type: "totp" | "ssh" | "login" };

interface VaultState {
  meta: VaultMeta | null;
  entries: EntryDto[];
  trashed: EntryDto[];
  groups: GroupInfo[];
  selectedUuid: string | null;
  search: string;
  section: Section;
  editorOpen: false | { mode: "create" } | { mode: "edit"; uuid: string };
  generatorOpen: boolean;
  settingsOpen: boolean;
  error: string | null;
  audit: AuditReport | null;
  auditLoading: boolean;
  init: () => Promise<void>;
  refresh: () => Promise<void>;
  setSearch: (search: string) => void;
  setSection: (section: Section) => void;
  select: (uuid: string | null) => void;
  openEditor: (editor: false | { mode: "create" } | { mode: "edit"; uuid: string }) => void;
  openGenerator: (open: boolean) => void;
  openSettings: (open: boolean) => void;
  runAudit: () => Promise<void>;
  save: () => Promise<void>;
  lock: () => Promise<void>;
  setError: (error: string | null) => void;
}

export const useVault = create<VaultState>((set, get) => ({
  meta: null,
  entries: [],
  trashed: [],
  groups: [],
  selectedUuid: null,
  search: "",
  section: "all",
  editorOpen: false,
  generatorOpen: false,
  settingsOpen: false,
  error: null,
  audit: null,
  auditLoading: false,

  init: async () => {
    const settings = await api.settingsGet();
    document.documentElement.dataset.theme = settings.theme;
    await get().refresh();
    await listen("vault:locked", () => get().refresh());
    await listen("vault:unlocked", () => get().refresh());
    await listen("vault:changed", () => {
      void get().refresh();
    });
  },

  refresh: async () => {
    try {
      const meta = await api.vaultGetMeta();
      if (meta.locked) {
        set({
          meta,
          entries: [],
          trashed: [],
          groups: [],
          selectedUuid: null,
          editorOpen: false,
          generatorOpen: false,
          error: null,
        });
        return;
      }
      const [entries, trashed, groups] = await Promise.all([
        api.entryList(),
        api.trashedList(),
        api.groupList(),
      ]);
      const selectedUuid = get().selectedUuid;
      const stillThere =
        selectedUuid && entries.some((e) => e.uuid === selectedUuid) ? selectedUuid : null;
      set({ meta, entries, trashed, groups, selectedUuid: stillThere, error: null });
    } catch (e) {
      set({ error: String(e) });
    }
  },

  setSearch: (search) => set({ search }),
  setSection: (section) => {
    set({ section });
    if (section === "audit") {
      void get().runAudit();
    }
  },
  select: (uuid) => set({ selectedUuid: uuid }),
  openEditor: (editorOpen) => set({ editorOpen }),
  openGenerator: (generatorOpen) => set({ generatorOpen }),
  openSettings: (settingsOpen) => set({ settingsOpen }),

  runAudit: async () => {
    set({ auditLoading: true });
    try {
      const audit = await api.auditRun();
      set({ audit, auditLoading: false, error: null });
    } catch (e) {
      set({ auditLoading: false, error: String(e) });
    }
  },

  save: async () => {
    try {
      const meta = await api.vaultSave();
      set({ meta });
    } catch (e) {
      set({ error: String(e) });
    }
  },

  lock: async () => {
    try {
      await api.vaultLock();
      set({ search: "", section: "all", selectedUuid: null });
      await get().refresh();
    } catch (e) {
      set({ error: String(e) });
    }
  },

  setError: (error) => set({ error }),
}));

/** Toggle dark/light theme and persist it. */
export async function toggleTheme() {
  const root = document.documentElement;
  const next = root.dataset.theme === "light" ? "dark" : "light";
  root.dataset.theme = next;
  const settings = await api.settingsGet();
  await api.settingsSet({ ...settings, theme: next });
}
