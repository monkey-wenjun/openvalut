import { type EntryDto } from "./api";

export const READ_ALLOWED_FIELD = "openvalut.read-allowed";

export const isCliReadable = (e: EntryDto) =>
  e.custom.some((c) => c.key === READ_ALLOWED_FIELD && c.value === "1");

export const hasTotp = (e: EntryDto) =>
  e.custom.some((c) => c.key === "OTPAuth" || c.key === "otp" || c.key === "TOTP Seed");

export const hasSsh = (e: EntryDto) => e.custom.some((c) => c.key === "ssh-private-key");

/** Entries stored in a group or any of its subgroups. */
export const inGroup = (e: EntryDto, path: string) =>
  e.group === path || e.group.startsWith(path + "/");
