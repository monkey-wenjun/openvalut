import { invoke } from "@tauri-apps/api/core";

// ---- shared types (mirror crates/openvalut-core/src/dto.rs) ----

export interface CustomField {
  key: string;
  value: string;
}

export interface EntryDto {
  uuid: string;
  title: string;
  username: string;
  password: string;
  url: string;
  notes: string;
  group: string;
  custom: CustomField[];
}

export interface CreateEntryRequestDto {
  title: string;
  username: string;
  password: string;
  url: string;
  notes: string;
  group?: string | null;
  otp?: string | null;
  ssh_private_key?: string | null;
  machine_id?: string | null;
  custom: CustomField[];
}

export interface UpdateEntryRequestDto {
  title?: string | null;
  username?: string | null;
  password?: string | null;
  url?: string | null;
  notes?: string | null;
  group?: string | null;
  otp?: string | null;
  ssh_private_key?: string | null;
  machine_id?: string | null;
  custom?: CustomField[] | null;
  remove_custom?: string[] | null;
}

export interface VaultMeta {
  locked: boolean;
  name: string | null;
  path: string | null;
  dirty: boolean;
  cloud: boolean;
  entry_count: number;
}

export interface RecentFile {
  path: string;
  name: string;
  last_opened_at: string;
}

export type CloseAction = "hide" | "minimize" | "exit";

export interface Settings {
  theme: string;
  language: string;
  clipboard_clear_seconds: number;
  autostart: boolean;
  remember_unlock_days: number;
  close_action: CloseAction;
  ui_zoom: number;
}

export interface GroupInfo {
  uuid: string;
  name: string;
  path: string;
  entry_count: number;
}

export interface TotpInfo {
  present: boolean;
  code: string | null;
  remaining: number | null;
  period: number | null;
}

export interface AuditIssue {
  kind: "weak" | "reused" | "old" | "duplicate";
  uuid: string;
  title: string;
  username: string;
  group: string;
  score: number | null;
  reuse_count: number | null;
  duplicate_count: number | null;
  days_since_update: number | null;
}

export interface AuditReport {
  weak: AuditIssue[];
  reused: AuditIssue[];
  old: AuditIssue[];
  duplicates: AuditIssue[];
  entry_count: number;
}

export interface BridgeStatus {
  running: boolean;
  port: number | null;
}

export interface CloudAccountStatus {
  configured: boolean;
  email: string | null;
  server: string | null;
}

export interface CloudVaultInfo {
  id: string;
  name: string;
}

export interface CloudRegisterResult {
  secret_key: string;
  meta: VaultMeta;
}

export interface ScanStartInfo {
  session_id: string;
  qr_content: string;
  qr_svg: string;
}

export interface ScanPollInfo {
  status: "pending" | "expired" | "confirmed";
  unlocked: boolean;
  needs_master: boolean;
  message: string | null;
}

export interface RememberedSummary {
  kind: "local" | "cloud";
  id: string;
  name: string;
  remaining_days: number;
}

// ---- commands ----

export const api = {
  vaultStatus: () => invoke<VaultMeta>("vault_status"),
  vaultOpen: (path: string, password: string, keyfilePath?: string) =>
    invoke<VaultMeta>("vault_open", { path, password, keyfilePath }),
  vaultCreate: (path: string, name: string, password: string, keyfilePath?: string) =>
    invoke<VaultMeta>("vault_create", { path, name, password, keyfilePath }),
  vaultLock: () => invoke<VaultMeta>("vault_lock"),
  vaultSave: () => invoke<VaultMeta>("vault_save"),
  vaultSaveAs: (path: string) => invoke<VaultMeta>("vault_save_as", { path }),
  vaultGetMeta: () => invoke<VaultMeta>("vault_get_meta"),
  vaultSetName: (name: string) => invoke<void>("vault_set_name", { name }),
  vaultChangeMasterPassword: (currentPassword: string, newPassword: string, keyfilePath?: string) =>
    invoke<void>("vault_change_master_password", { currentPassword, newPassword, keyfilePath }),
  recentsList: () => invoke<RecentFile[]>("recents_list"),
  recentsRemove: (path: string) => invoke<void>("recents_remove", { path }),
  recentsClear: () => invoke<void>("recents_clear"),

  entryList: (search?: string, group?: string) =>
    invoke<EntryDto[]>("entry_list", { search: search ?? null, group: group ?? null }),
  entryGet: (uuid: string) => invoke<EntryDto>("entry_get", { uuid }),
  entryCreate: (request: CreateEntryRequestDto) => invoke<string>("entry_create", { request }),
  entryUpdate: (uuid: string, request: UpdateEntryRequestDto) =>
    invoke<void>("entry_update", { uuid, request }),
  entrySetCliRead: (uuid: string, allowed: boolean) =>
    invoke<void>("entry_set_cli_read", { uuid, allowed }),
  entryDelete: (uuid: string) => invoke<void>("entry_delete", { uuid }),
  entryTrash: (uuid: string) => invoke<void>("entry_trash", { uuid }),
  entryTrashDuplicates: (title: string, username: string) =>
    invoke<number>("entry_trash_duplicates", { title, username }),
  entryRestore: (uuid: string) => invoke<void>("entry_restore", { uuid }),
  trashedList: () => invoke<EntryDto[]>("trashed_list"),
  entryFieldValue: (uuid: string, key: string) =>
    invoke<string>("entry_field_value", { uuid, key }),
  groupList: () => invoke<GroupInfo[]>("group_list"),
  groupCreate: (path: string) => invoke<string>("group_create", { path }),
  groupRename: (uuid: string, name: string) => invoke<void>("group_rename", { uuid, name }),
  groupTrash: (uuid: string) => invoke<void>("group_trash", { uuid }),
  groupSetCliRead: (uuid: string, allowed: boolean) =>
    invoke<number>("group_set_cli_read", { uuid, allowed }),

  totpForEntry: (uuid: string) => invoke<TotpInfo>("totp_for_entry", { uuid }),
  passwordGenerate: (length?: number, uppercase?: boolean, digits?: boolean, symbols?: boolean) =>
    invoke<string>("password_generate", { length, uppercase, digits, symbols }),
  clipboardCopy: (value: string, sensitive: boolean) =>
    invoke<void>("clipboard_copy", { value, sensitive }),
  settingsGet: () => invoke<Settings>("settings_get"),
  settingsSet: (settings: Settings) => invoke<void>("settings_set", { settings }),

  rememberedStatus: () => invoke<RememberedSummary[]>("remembered_status"),
  rememberedUnlock: (kind: string, id: string) =>
    invoke<VaultMeta>("remembered_unlock", { kind, id }),
  rememberedForget: (kind?: string, id?: string) =>
    invoke<void>("remembered_forget", { kind: kind ?? null, id: id ?? null }),

  auditRun: () => invoke<AuditReport>("audit_run"),
  bridgeStatus: () => invoke<BridgeStatus>("bridge_status"),

  cloudAccountStatus: () => invoke<CloudAccountStatus>("cloud_account_status"),
  cloudAccountSave: (email: string, secretKey: string, server?: string) =>
    invoke<CloudAccountStatus>("cloud_account_save", {
      email,
      secretKey,
      server: server ?? null,
    }),
  cloudVaults: () => invoke<CloudVaultInfo[]>("cloud_vaults"),
  cloudOpen: (password: string, vaultId?: string) =>
    invoke<VaultMeta>("cloud_open", { password, vaultId: vaultId ?? null }),
  cloudLogin: (email: string, secretKey: string, server: string, masterPassword: string) =>
    invoke<VaultMeta>("cloud_login", {
      email,
      secretKey,
      server: server || null,
      masterPassword,
      vaultId: null,
    }),
  cloudRegister: (email: string, server: string, name: string, master: string) =>
    invoke<CloudRegisterResult>("cloud_register", {
      email,
      server: server || null,
      name,
      master,
    }),
  scanStart: (server: string) => invoke<ScanStartInfo>("scan_start", { server: server || null }),
  scanPoll: (sessionId: string) => invoke<ScanPollInfo>("scan_poll", { sessionId }),
  scanCancel: () => invoke<void>("scan_cancel"),
  passwordStrength: (password: string, userInputs?: string[]) =>
    invoke<number>("password_strength", { password, userInputs: userInputs ?? null }),
  fileWriteText: (path: string, content: string) => invoke<void>("file_write_text", { path, content }),

  dialogPickKdbx: () => invoke<string | null>("dialog_pick_kdbx"),
  dialogPickSavePath: (defaultName?: string) =>
    invoke<string | null>("dialog_pick_save_path", { defaultName }),
};
