//! OpenValut Rust desktop UI (egui).
//!
//! MVP: open a local KDBX file, unlock with the master password, browse /
//! search entries, copy username / password / TOTP to the clipboard, lock.

use std::path::{Path, PathBuf};
use std::time::Duration;

use arboard::Clipboard;
use eframe::egui;
use egui::{Color32, RichText, ScrollArea, TextEdit};
use openvalut_core::kdbx::{CreateEntryRequest, Entry, UpdateEntryRequest, Vault, VaultKey};
use openvalut_core::totp::{generate_totp, parse_otp_auth};

const OTP_FIELD: &str = "OTPAuth";
const CONFIG_DIR: &str = "openvalut-ui";
const CONFIG_FILE: &str = "config.json";

fn main() -> eframe::Result {
    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_inner_size([1120.0, 720.0])
            .with_min_inner_size([800.0, 500.0])
            .with_title("OpenValut"),
        ..Default::default()
    };
    eframe::run_native(
        "OpenValut",
        options,
        Box::new(|cc| Ok(Box::new(OpenValutApp::new(cc)))),
    )
}

struct OpenValutApp {
    path_input: String,
    password_input: String,
    show_password: bool,
    last_path: Option<String>,
    status: Option<(bool, String)>,
    unlocked: Option<Unlocked>,
    selected_group: Option<String>,
    selected_uuid: Option<String>,
    search: String,
    search_focus_requested: bool,
    filtered_uuids: Vec<String>,
    reveal_selected_password: bool,
    editor: Option<EntryEditor>,
    confirm_delete: Option<String>,
}

struct Unlocked {
    vault_name: String,
    path: PathBuf,
    vault: Vault,
    key: VaultKey,
    entries: Vec<Entry>,
    groups: Vec<String>,
}

struct EntryEditor {
    editing_uuid: Option<String>,
    group: String,
    title: String,
    username: String,
    password: String,
    url: String,
    notes: String,
    otp: String,
    show_password: bool,
}

impl OpenValutApp {
    fn new(cc: &eframe::CreationContext<'_>) -> Self {
        install_cjk_fonts(&cc.egui_ctx);
        apply_openvalut_theme(&cc.egui_ctx);
        let mut style = (*cc.egui_ctx.style()).clone();
        style.spacing.item_spacing = egui::vec2(10.0, 6.0);
        style.spacing.button_padding = egui::vec2(10.0, 5.0);
        style.text_styles.insert(
            egui::TextStyle::Heading,
            egui::FontId::new(22.0, egui::FontFamily::Proportional),
        );
        style.text_styles.insert(
            egui::TextStyle::Body,
            egui::FontId::new(15.0, egui::FontFamily::Proportional),
        );
        style.text_styles.insert(
            egui::TextStyle::Button,
            egui::FontId::new(14.0, egui::FontFamily::Proportional),
        );
        style.text_styles.insert(
            egui::TextStyle::Small,
            egui::FontId::new(12.0, egui::FontFamily::Proportional),
        );
        cc.egui_ctx.set_style(style);
        Self {
            path_input: String::new(),
            password_input: String::new(),
            show_password: false,
            last_path: load_last_path(),
            status: None,
            unlocked: None,
            selected_group: None,
            selected_uuid: None,
            search: String::new(),
            search_focus_requested: false,
            filtered_uuids: Vec::new(),
            reveal_selected_password: false,
            editor: None,
            confirm_delete: None,
        }
    }

    fn pick_file(&mut self) {
        if let Some(path) = rfd::FileDialog::new()
            .add_filter("KeePass 数据库", &["kdbx", "kdb"])
            .pick_file()
        {
            self.path_input = path.display().to_string();
        }
    }

    fn try_unlock(&mut self) {
        let path = PathBuf::from(self.path_input.trim());
        if !path.exists() {
            self.status = Some((false, format!("文件不存在：{}", path.display())));
            return;
        }
        if self.password_input.is_empty() {
            self.status = Some((false, "请输入主密码".into()));
            return;
        }
        let bytes = match std::fs::read(&path) {
            Ok(b) => b,
            Err(e) => {
                self.status = Some((false, format!("读取文件失败：{e}")));
                return;
            }
        };
        let key = VaultKey::with_password(self.password_input.clone());
        match Vault::open(&bytes, &key) {
            Ok(vault) => {
                let vault_name = vault
                    .name()
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| "密码库".to_string());
                self.unlocked = Some(Unlocked {
                    vault_name,
                    path,
                    vault,
                    key,
                    entries: Vec::new(),
                    groups: Vec::new(),
                });
                self.refresh_entries();
                self.last_path = Some(self.path_input.trim().to_string());
                persist_last_path(self.last_path.as_deref());
                self.status = Some((
                    true,
                    format!(
                        "已解锁（{} 条条目）。主密码仅保存在内存中。",
                        self.unlocked.as_ref().unwrap().entries.len()
                    ),
                ));
                self.selected_group = None;
                self.selected_uuid = None;
                self.password_input.clear();
                self.search.clear();
            }
            Err(e) => {
                self.status = Some((false, format!("解锁失败（主密码错误？）：{e}")));
            }
        }
    }

    fn lock(&mut self) {
        self.unlocked = None;
        self.selected_uuid = None;
        self.selected_group = None;
        self.editor = None;
        self.confirm_delete = None;
        self.search.clear();
        self.reveal_selected_password = false;
        self.status = Some((true, "已锁定，内存中的密码已清除。".into()));
    }

    fn refresh_entries(&mut self) {
        if let Some(u) = self.unlocked.as_mut() {
            u.entries = u.vault.entries();
            let mut groups: Vec<String> = u
                .entries
                .iter()
                .map(|e| {
                    if e.group.is_empty() {
                        "（根目录）".to_string()
                    } else {
                        e.group.clone()
                    }
                })
                .collect();
            groups.sort();
            groups.dedup();
            u.groups = groups;
        }
    }

    fn save_vault(&mut self) -> Result<(), String> {
        let Some(unlocked) = self.unlocked.as_mut() else {
            return Err("没有打开的密码库".into());
        };
        let bytes = unlocked
            .vault
            .save(&unlocked.key)
            .map_err(|e| format!("序列化失败：{e}"))?;
        std::fs::write(&unlocked.path, bytes).map_err(|e| format!("写入失败：{e}"))?;
        Ok(())
    }

    fn open_editor_new(&mut self) {
        let group = self.selected_group.clone().unwrap_or_default();
        let group = if group == "（根目录）" { String::new() } else { group };
        self.editor = Some(EntryEditor {
            editing_uuid: None,
            group,
            title: String::new(),
            username: String::new(),
            password: String::new(),
            url: String::new(),
            notes: String::new(),
            otp: String::new(),
            show_password: false,
        });
    }

    fn open_editor_edit(&mut self, entry: &Entry) {
        let otp = Self::otp_value(entry).unwrap_or_default().to_string();
        self.editor = Some(EntryEditor {
            editing_uuid: Some(entry.uuid.clone()),
            group: entry.group.clone(),
            title: entry.title.clone(),
            username: entry.username.clone(),
            password: entry.password.clone(),
            url: entry.url.clone(),
            notes: entry.notes.clone(),
            otp,
            show_password: false,
        });
    }

    fn commit_editor(&mut self, ed: EntryEditor) {
        let Some(unlocked) = self.unlocked.as_mut() else {
            return;
        };
        let otp = if ed.otp.trim().is_empty() {
            None
        } else {
            Some(ed.otp.trim().to_string())
        };
        let group = if ed.group.trim().is_empty() {
            None
        } else {
            Some(ed.group.trim().to_string())
        };
        let result = match &ed.editing_uuid {
            None => unlocked
                .vault
                .add_entry(&CreateEntryRequest {
                    title: ed.title.clone(),
                    username: ed.username.clone(),
                    password: ed.password.clone(),
                    url: ed.url.clone(),
                    notes: ed.notes.clone(),
                    otp,
                    ssh_private_key: None,
                    machine_id: None,
                    group,
                    custom: Vec::new(),
                })
                .map(|_| ()),
            Some(uuid) => unlocked.vault.update_entry(uuid, &UpdateEntryRequest {
                title: Some(ed.title.clone()),
                username: Some(ed.username.clone()),
                password: Some(ed.password.clone()),
                url: Some(ed.url.clone()),
                notes: Some(ed.notes.clone()),
                otp,
                ssh_private_key: None,
                machine_id: None,
                group,
                custom: Vec::new(),
                remove_custom: Vec::new(),
            }),
        };
        match result {
            Ok(_) => {
                self.refresh_entries();
                match self.save_vault() {
                    Ok(()) => {
                        self.editor = None;
                        self.status = Some((
                            true,
                            if ed.editing_uuid.is_some() {
                                "已保存修改".into()
                            } else {
                                "已新增条目并保存".into()
                            },
                        ));
                    }
                    Err(e) => {
                        self.editor = None;
                        self.status = Some((false, format!("已修改但保存失败：{e}")));
                    }
                }
            }
            Err(e) => {
                self.status = Some((false, format!("操作失败：{e}")));
            }
        }
    }

    fn delete_selected(&mut self) {
        let Some(uuid) = self.confirm_delete.clone() else {
            return;
        };
        let Some(unlocked) = self.unlocked.as_mut() else {
            return;
        };
        let result = unlocked.vault.delete_entry(&uuid);
        self.confirm_delete = None;
        match result {
            Ok(()) => {
                self.refresh_entries();
                self.selected_uuid = None;
                match self.save_vault() {
                    Ok(()) => self.status = Some((true, "已删除并保存".into())),
                    Err(e) => self.status = Some((false, format!("已删除但保存失败：{e}"))),
                }
            }
            Err(e) => self.status = Some((false, format!("删除失败：{e}"))),
        }
    }

    fn move_selection(&mut self, delta: i32) {
        if self.filtered_uuids.is_empty() {
            return;
        }
        let len = self.filtered_uuids.len() as i32;
        let current = self
            .selected_uuid
            .as_ref()
            .and_then(|u| self.filtered_uuids.iter().position(|x| x == u))
            .map(|i| i as i32);
        let next = match current {
            Some(i) => (i + delta).rem_euclid(len),
            None => {
                if delta > 0 {
                    0
                } else {
                    len - 1
                }
            }
        } as usize;
        self.selected_uuid = Some(self.filtered_uuids[next].clone());
        self.reveal_selected_password = false;
    }

    fn copy_selected_password(&mut self) {
        let Some(entry) = self.selected_entry().map(|e| e.clone()) else {
            self.status = Some((false, "没有选中的条目".into()));
            return;
        };
        if entry.password.is_empty() {
            self.status = Some((false, "该条目没有密码".into()));
            return;
        }
        self.copy_text(&entry.password, "密码");
    }

    fn esc_pressed(&mut self) {
        if self.editor.is_some() {
            self.editor = None;
            return;
        }
        if self.confirm_delete.is_some() {
            self.confirm_delete = None;
            return;
        }
        if self.unlocked.is_some() {
            if !self.search.is_empty() {
                self.search.clear();
            } else {
                self.selected_uuid = None;
            }
        }
    }

    fn visible_entries(&self) -> Vec<&Entry> {
        let Some(unlocked) = &self.unlocked else {
            return Vec::new();
        };
        let query = self.search.trim().to_lowercase();
        unlocked
            .entries
            .iter()
            .filter(|e| {
                let group_ok = match &self.selected_group {
                    None => true,
                    Some(g) => {
                        if g == "（根目录）" {
                            e.group.is_empty()
                        } else {
                            e.group == *g
                        }
                    }
                };
                if !group_ok {
                    return false;
                }
                if query.is_empty() {
                    return true;
                }
                e.title.to_lowercase().contains(&query)
                    || e.username.to_lowercase().contains(&query)
                    || e.url.to_lowercase().contains(&query)
                    || e.notes.to_lowercase().contains(&query)
                    || e.group.to_lowercase().contains(&query)
            })
            .collect()
    }

    fn selected_entry(&self) -> Option<&Entry> {
        let unlocked = self.unlocked.as_ref()?;
        let uuid = self.selected_uuid.as_ref()?;
        unlocked.entries.iter().find(|e| &e.uuid == uuid)
    }

    fn copy_text(&mut self, text: &str, what: &str) {
        match Clipboard::new().and_then(|mut c| c.set_text(text.to_string())) {
            Ok(()) => self.status = Some((true, format!("已复制{what}到剪贴板"))),
            Err(e) => self.status = Some((false, format!("复制失败：{e}"))),
        }
    }

    fn otp_value(entry: &Entry) -> Option<&str> {
        entry
            .custom
            .iter()
            .find(|(k, _)| k.eq_ignore_ascii_case(OTP_FIELD))
            .map(|(_, v)| v.as_str())
    }

    fn show_locked(&mut self, ui: &mut egui::Ui) {
        ui.add_space(24.0);
        ui.vertical_centered(|ui| {
            ui.heading("OpenValut");
            ui.label("Rust (egui) 桌面版 · MVP");
        });
        ui.add_space(16.0);
        egui::Frame::group(ui.style()).show(ui, |ui| {
            ui.set_width(520.0);
            ui.horizontal(|ui| {
                ui.label("KDBX 文件：");
                ui.add(
                    TextEdit::singleline(&mut self.path_input)
                        .hint_text("/path/to/vault.kdbx"),
                );
                if ui.button("浏览…").clicked() {
                    self.pick_file();
                }
            });
            ui.add_space(8.0);
            ui.horizontal(|ui| {
                ui.label("主密码：");
                ui.add(
                    TextEdit::singleline(&mut self.password_input)
                        .password(!self.show_password)
                        .desired_width(220.0),
                );
                if ui
                    .button(if self.show_password { "隐藏" } else { "显示" })
                    .on_hover_text("显示/隐藏密码")
                    .clicked()
                {
                    self.show_password = !self.show_password;
                }
                if ui
                    .add_enabled(
                        !self.path_input.trim().is_empty()
                            && !self.password_input.is_empty(),
                        egui::Button::new(
                            RichText::new("解锁")
                                .strong()
                                .color(Color32::from_rgb(6, 40, 30)),
                        )
                        .fill(Color32::from_rgb(5, 150, 105)),
                    )
                    .clicked()
                {
                    self.try_unlock();
                }
            });
            if ui.button("用刚才的本地副本打开").clicked() {
                self.path_input = "/home/user/vault.kdbx".into();
            }
            if let Some(last) = self.last_path.clone() {
                if !last.is_empty()
                    && Path::new(&last).exists()
                    && ui.button("打开上次的文件").clicked()
                {
                    self.path_input = last;
                }
            }
        });
    }

    fn show_unlocked(&mut self, ui: &mut egui::Ui) {
        let vault_name = {
            let u = self.unlocked.as_ref().unwrap();
            u.vault_name.clone()
        };
        let selected_uuid = self.selected_uuid.clone();
        // 预先收集成 owned 数据，避免遍历时同时修改 self。
        let (items, total) = {
            let filtered = self.visible_entries();
            let items: Vec<(String, String)> = filtered
                .iter()
                .map(|e| {
                    let title = if e.title.is_empty() {
                        "(无标题)".to_string()
                    } else {
                        e.title.clone()
                    };
                    let line = if e.username.is_empty() {
                        title
                    } else {
                        format!("{}  ·  {}", title, e.username)
                    };
                    (e.uuid.clone(), line)
                })
                .collect();
            let total = items.len();
            (items, total)
        };
        self.filtered_uuids = items.iter().map(|(u, _)| u.clone()).collect();

        ui.horizontal(|ui| {
            ui.heading(&vault_name);
            ui.label(format!("（{total} 条）"));
            ui.separator();
            ui.label("搜索：");
            let search_resp = ui.add(
                TextEdit::singleline(&mut self.search)
                    .hint_text("标题 / 用户名 / 网址…")
                    .desired_width(240.0),
            );
            if self.search_focus_requested {
                search_resp.request_focus();
                self.search_focus_requested = false;
            }
        });
        ui.separator();
        ui.horizontal(|ui| {
            if ui.button("锁定").clicked() {
                self.lock();
            }
                if ui.button("+ 新增条目").clicked() {
                    self.open_editor_new();
                }
        });
        ScrollArea::vertical().show(ui, |ui| {
            for (uuid, line) in &items {
                let selected = Some(uuid.clone()) == selected_uuid;
                if ui.selectable_label(selected, line).clicked() {
                    self.selected_uuid = Some(uuid.clone());
                    self.reveal_selected_password = false;
                }
            }
        });
    }

    fn show_groups(&mut self, ui: &mut egui::Ui) {
        let Some(unlocked) = &self.unlocked else {
            return;
        };
        ui.add_space(4.0);
        ui.strong("分组");
        ui.separator();
        let total = unlocked.entries.len();
        let mut clicked: Option<Option<String>> = None;
        ScrollArea::vertical().show(ui, |ui| {
            if ui
                .selectable_label(self.selected_group.is_none(), format!("全部（{total}）"))
                .clicked()
            {
                clicked = Some(None);
            }
            for g in &unlocked.groups {
                let count = if g == "（根目录）" {
                    unlocked.entries.iter().filter(|e| e.group.is_empty()).count()
                } else {
                    unlocked.entries.iter().filter(|e| e.group == *g).count()
                };
                if ui
                    .selectable_label(
                        self.selected_group.as_deref() == Some(g),
                        format!("{g}（{count}）"),
                    )
                    .clicked()
                {
                    clicked = Some(Some(g.clone()));
                }
            }
        });
        if let Some(sel) = clicked {
            self.selected_group = sel;
            self.selected_uuid = None;
        }
    }

    fn show_details(&mut self, ui: &mut egui::Ui, entry: &Entry) {
        ui.add_space(4.0);
        ScrollArea::vertical().show(ui, |ui| {
            ui.heading(if entry.title.is_empty() {
                "(无标题)"
            } else {
                &entry.title
            });
            ui.label(format!("分组：{}", if entry.group.is_empty() { "（根目录）" } else { &entry.group }));
            ui.separator();
            ui.horizontal(|ui| {
                ui.label("用户名：");
                ui.monospace(if entry.username.is_empty() {
                    "（空）".to_string()
                } else {
                    entry.username.clone()
                });
                if !entry.username.is_empty() && ui.button("复制").clicked() {
                    self.copy_text(&entry.username, "用户名");
                }
            });
            let secret = if self.reveal_selected_password {
                entry.password.clone()
            } else {
                "•".repeat(entry.password.len().clamp(1, 24))
            };
            ui.horizontal(|ui| {
                ui.label("密码：");
                ui.monospace(&secret);
                if ui
                    .button(if self.reveal_selected_password { "隐藏" } else { "显示" })
                    .clicked()
                {
                    self.reveal_selected_password = !self.reveal_selected_password;
                }
                if !entry.password.is_empty() {
                    if ui.button("复制").clicked() {
                        self.copy_text(&entry.password, "密码");
                    }
                }
            });
            ui.horizontal(|ui| {
                ui.label("网址：");
                ui.monospace(if entry.url.is_empty() {
                    "（空）".to_string()
                } else {
                    entry.url.clone()
                });
                if !entry.url.is_empty() && ui.button("复制").clicked() {
                    self.copy_text(&entry.url, "网址");
                }
            });
            ui.label("备注：");
            ui.label(if entry.notes.is_empty() {
                "（无）".to_string()
            } else {
                entry.notes.clone()
            });
            ui.add_space(6.0);
            if let Some(otp) = Self::otp_value(entry) {
                match parse_otp_auth(otp) {
                    Ok(auth) => {
                        match generate_totp(&auth, None) {
                            Ok((code, remaining, _)) => {
                                ui.horizontal(|ui| {
                                    ui.label("TOTP：");
                                    ui.monospace(
                                        RichText::new(code.clone())
                                            .size(26.0)
                                            .color(Color32::from_rgb(80, 200, 140)),
                                    );
                                    if ui.button("复制").clicked() {
                                        self.copy_text(&code, "验证码");
                                    }
                                });
                                ui.label(format!("{remaining} 秒后刷新"));
                                ui.ctx().request_repaint_after(Duration::from_millis(500));
                            }
                            Err(e) => {
                                ui.label(format!("TOTP 计算失败：{e}"));
                            }
                        }
                    }
                    Err(e) => {
                        ui.label(format!("TOTP 解析失败：{e}"));
                    }
                }
            }
            ui.add_space(8.0);
            ui.horizontal(|ui| {
                if ui.button("编辑").clicked() {
                    let entry = entry.clone();
                    self.open_editor_edit(&entry);
                }
                if ui.button("删除").clicked() {
                    self.confirm_delete = Some(entry.uuid.clone());
                }
            });
            ui.weak(format!("UUID：{}", entry.uuid));
        });
    }
}

fn install_cjk_fonts(ctx: &egui::Context) {
    let candidates = [
        "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/wenquanyi/wqy-zenhei/wqy-zenhei.ttc",
        "/usr/share/fonts/adobe-source-han-sans/SourceHanSansCN-Regular.otf",
    ];
    let Some(path) = candidates.iter().find(|p| Path::new(p).exists()) else {
        eprintln!("warning: no CJK font found, Chinese text may not render");
        return;
    };
    if let Ok(bytes) = std::fs::read(path) {
        let mut fonts = egui::FontDefinitions::default();
        fonts
            .font_data
            .insert("cjk".to_owned(), egui::FontData::from_owned(bytes).into());
        for family in [egui::FontFamily::Proportional, egui::FontFamily::Monospace] {
            if let Some(list) = fonts.families.get_mut(&family) {
                list.push("cjk".to_owned());
            }
        }
        ctx.set_fonts(fonts);
    }
}

/// UI/UX Pro Max 设计规范（Minimalism & Swiss Style，深色）。
/// 背景 #0F172A · 卡片 #192134 · 强调/安全绿 #059669 · 文字 #E2E8F0。
fn apply_openvalut_theme(ctx: &egui::Context) {
    let mut style = (*ctx.style()).clone();
    let v = &mut style.visuals;
    v.dark_mode = true;

    let bg = Color32::from_rgb(15, 23, 42); // #0F172A
    let panel = Color32::from_rgb(16, 25, 46); // #10192E muted
    let card = Color32::from_rgb(25, 33, 52); // #192134
    let hover = Color32::from_rgb(35, 48, 73); // 悬停
    let accent = Color32::from_rgb(5, 150, 105); // #059669
    let danger = Color32::from_rgb(220, 38, 38); // #DC2626
    let text = Color32::from_rgb(226, 232, 240); // #E2E8F0
    let muted = Color32::from_rgb(148, 163, 184); // #94A3B8
    let border = Color32::from_rgba_unmultiplied(255, 255, 255, 24);

    v.panel_fill = panel;
    v.window_fill = card;
    v.extreme_bg_color = bg;
    v.faint_bg_color = Color32::TRANSPARENT;
    v.code_bg_color = Color32::from_rgb(30, 41, 59);
    v.selection.bg_fill = accent;
    v.selection.stroke = egui::Stroke::NONE;
    v.hyperlink_color = Color32::from_rgb(52, 211, 153); // 绿系链接

    for w in [
        &mut v.widgets.noninteractive,
        &mut v.widgets.inactive,
        &mut v.widgets.hovered,
        &mut v.widgets.active,
    ] {
        w.rounding = egui::Rounding::same(6.0);
        w.bg_stroke = egui::Stroke::new(1.0_f32, border);
        w.expansion = 0.0;
    }
    v.widgets.noninteractive.bg_fill = Color32::TRANSPARENT;
    v.widgets.noninteractive.fg_stroke = egui::Stroke::new(1.0_f32, text);
    v.widgets.inactive.bg_fill = card;
    v.widgets.inactive.fg_stroke = egui::Stroke::new(1.0_f32, text);
    v.widgets.hovered.bg_fill = hover;
    v.widgets.hovered.fg_stroke = egui::Stroke::new(1.0_f32, Color32::WHITE);
    v.widgets.active.bg_fill = accent;
    v.widgets.active.fg_stroke = egui::Stroke::new(1.0_f32, Color32::from_rgb(6, 40, 30));
    v.window_stroke = egui::Stroke::new(1.0_f32, border);
    v.window_rounding = egui::Rounding::same(8.0);

    let _ = danger;
    let _ = muted;
    ctx.set_style(style);
}

impl eframe::App for OpenValutApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        let (
            key_enter,
            key_esc,
            key_slash,
            key_j,
            key_k,
            key_down,
            key_up,
            key_delete,
            ctrl_o,
            ctrl_f,
            ctrl_n,
            ctrl_e,
            ctrl_s,
            ctrl_l,
        ) = ctx.input(|i| {
            let ctrl = i.modifiers.ctrl || i.modifiers.command;
            (
                i.key_pressed(egui::Key::Enter),
                i.key_pressed(egui::Key::Escape),
                i.key_pressed(egui::Key::Slash),
                i.key_pressed(egui::Key::J),
                i.key_pressed(egui::Key::K),
                i.key_pressed(egui::Key::ArrowDown),
                i.key_pressed(egui::Key::ArrowUp),
                i.key_pressed(egui::Key::Delete),
                ctrl && i.key_pressed(egui::Key::O),
                ctrl && i.key_pressed(egui::Key::F),
                ctrl && i.key_pressed(egui::Key::N),
                ctrl && i.key_pressed(egui::Key::E),
                ctrl && i.key_pressed(egui::Key::S),
                ctrl && i.key_pressed(egui::Key::L),
            )
        });
        let text_editing = ctx.memory(|m| m.focused().is_some());
        let modal_open = self.editor.is_some() || self.confirm_delete.is_some();

        if key_esc {
            self.esc_pressed();
        }
        if !modal_open {
            if self.unlocked.is_none() {
                if key_enter
                    && !self.path_input.trim().is_empty()
                    && !self.password_input.is_empty()
                {
                    self.try_unlock();
                }
                if ctrl_o {
                    self.pick_file();
                }
            } else {
                if !text_editing {
                    if key_slash || ctrl_f {
                        self.search_focus_requested = true;
                    }
                    if key_j || key_down {
                        self.move_selection(1);
                    }
                    if key_k || key_up {
                        self.move_selection(-1);
                    }
                    if key_enter {
                        self.copy_selected_password();
                    }
                    if key_delete {
                        if self.selected_uuid.is_some() {
                            self.confirm_delete = self.selected_uuid.clone();
                        }
                    }
                }
                if ctrl_n {
                    self.open_editor_new();
                }
                if ctrl_e && !text_editing {
                    if let Some(entry) = self.selected_entry().map(|e| e.clone()) {
                        self.open_editor_edit(&entry);
                    }
                }
                if ctrl_s {
                    match self.save_vault() {
                        Ok(()) => self.status = Some((true, "已保存".into())),
                        Err(e) => self.status = Some((false, e)),
                    }
                }
                if ctrl_l {
                    self.lock();
                }
            }
        }

        egui::TopBottomPanel::top("top").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.strong("OpenValut");
                if self.unlocked.is_some() {
                    ui.separator();
                    if ui.button("+ 新增条目").clicked() {
                        self.open_editor_new();
                    }
                    let save_btn = egui::Button::new(
                        RichText::new("保存")
                            .strong()
                            .color(Color32::from_rgb(6, 40, 30)),
                    )
                    .fill(Color32::from_rgb(5, 150, 105));
                    if ui.add(save_btn).clicked() {
                        match self.save_vault() {
                            Ok(()) => {
                                self.status = Some((true, "已保存".into()));
                            }
                            Err(e) => self.status = Some((false, e)),
                        }
                    }
                    if ui.button("锁定").clicked() {
                        self.lock();
                    }
                }
                if let Some((ok, msg)) = &self.status {
                    ui.separator();
                    let color = if *ok {
                        Color32::from_rgb(110, 200, 130)
                    } else {
                        Color32::from_rgb(230, 110, 110)
                    };
                    ui.label(RichText::new(msg).color(color));
                }
            });
        });

        egui::TopBottomPanel::bottom("shortcuts").show(ctx, |ui| {
            ui.horizontal(|ui| {
                ui.weak(if self.unlocked.is_some() {
                    "j/k 或 ↑/↓ 选择 · / 搜索 · Enter 复制密码 · Ctrl+N 新建 · Ctrl+E 编辑 · Del 删除 · Ctrl+S 保存 · Ctrl+L 锁定 · Esc 返回"
                } else {
                    "Ctrl+O 打开文件 · Enter 解锁"
                });
            });
        });

        // 侧栏要先于中央面板布局，避免叠绘闪烁。
        if self.unlocked.is_some() {
            egui::SidePanel::left("groups")
                .resizable(true)
                .default_width(190.0)
                .show(ctx, |ui| self.show_groups(ui));
        }
        if let Some(entry) = self.unlocked.as_ref().and_then(|_| self.selected_entry().cloned()) {
            egui::SidePanel::right("details")
                .resizable(true)
                .default_width(360.0)
                .show(ctx, |ui| {
                    self.show_details(ui, &entry);
                });
        }

        egui::CentralPanel::default().show(ctx, |ui| {
            if self.unlocked.is_none() {
                ui.vertical_centered(|ui| {
                    ui.set_max_width(560.0);
                    self.show_locked(ui);
                });
                return;
            }
            self.show_unlocked(ui);
        });

        // 新增 / 编辑条目窗口
        if self.editor.is_some() {
            let mut ed = self.editor.take().unwrap();
            let mut commit = false;
            let mut cancel = false;
            let is_edit = ed.editing_uuid.is_some();
            egui::Window::new(if is_edit { "编辑条目" } else { "新增条目" })
                .collapsible(false)
                .resizable(false)
                .default_width(440.0)
                .show(ctx, |ui| {
                    ui.horizontal(|ui| {
                        ui.label("分组：");
                        ui.add(
                            TextEdit::singleline(&mut ed.group)
                                .hint_text("留空为根目录，可用 / 表示层级"),
                        );
                    });
                    labeled_edit(ui, "标题：", &mut ed.title);
                    labeled_edit(ui, "用户名：", &mut ed.username);
                    ui.horizontal(|ui| {
                        ui.label("密码：");
                        ui.add(
                            TextEdit::singleline(&mut ed.password)
                                .password(!ed.show_password)
                                .desired_width(220.0),
                        );
                        if ui.button(if ed.show_password { "隐藏" } else { "显示" }).clicked() {
                            ed.show_password = !ed.show_password;
                        }
                        if ui.button("生成").on_hover_text("生成 20 位随机密码").clicked() {
                            ed.password = openvalut_core::generate_password(20, true, true, true)
                                .unwrap_or_default();
                        }
                    });
                    labeled_edit(ui, "网址：", &mut ed.url);
                    ui.horizontal(|ui| {
                        ui.label("备注：");
                        ui.add(
                            TextEdit::singleline(&mut ed.notes).desired_width(300.0),
                        );
                    });
                    ui.horizontal(|ui| {
                        ui.label("TOTP：");
                        ui.add(
                            TextEdit::singleline(&mut ed.otp)
                                .hint_text("otpauth:// 或 base32 密钥")
                                .desired_width(300.0),
                        );
                    });
                    ui.add_space(8.0);
                    ui.horizontal(|ui| {
                        if ui.button("取消").clicked() {
                            cancel = true;
                        }
                        if ui
                            .add_enabled(
                                !ed.title.trim().is_empty(),
                                egui::Button::new("保存"),
                            )
                            .clicked()
                        {
                            commit = true;
                        }
                    });
                    if ed.title.trim().is_empty() {
                        ui.weak("标题不能为空");
                    }
                });
            if commit {
                self.commit_editor(ed);
            } else if cancel {
                self.editor = None;
            } else {
                self.editor = Some(ed);
            }
        }

        // 删除确认窗口
        if let Some(uuid) = self.confirm_delete.clone() {
            let title = self
                .unlocked
                .as_ref()
                .and_then(|u| u.entries.iter().find(|e| e.uuid == uuid))
                .map(|e| {
                    if e.title.is_empty() {
                        "(无标题)".to_string()
                    } else {
                        e.title.clone()
                    }
                })
                .unwrap_or_else(|| "该条目".to_string());
            let mut confirmed = false;
            let mut cancelled = false;
            egui::Window::new("删除确认")
                .collapsible(false)
                .resizable(false)
                .show(ctx, |ui| {
                    ui.label(format!("确定删除「{title}」吗？此操作会立即保存。"));
                    ui.add_space(8.0);
                    ui.horizontal(|ui| {
                        if ui.button("取消").clicked() {
                            cancelled = true;
                        }
                        if ui.button("删除").clicked() {
                            confirmed = true;
                        }
                    });
                });
            if confirmed {
                self.confirm_delete = Some(uuid);
                self.delete_selected();
            } else if cancelled {
                self.confirm_delete = None;
            }
        }
    }
}

fn labeled_edit(ui: &mut egui::Ui, label: &str, value: &mut String) {
    ui.horizontal(|ui| {
        ui.label(label);
        ui.add(TextEdit::singleline(value).desired_width(300.0));
    });
}

fn config_path() -> PathBuf {
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_default();
    home.join(".config").join(CONFIG_DIR).join(CONFIG_FILE)
}

fn load_last_path() -> Option<String> {
    let raw = std::fs::read_to_string(config_path()).ok()?;
    let v: serde_json::Value = serde_json::from_str(&raw).ok()?;
    v.get("last_path")
        .and_then(|p| p.as_str())
        .map(|s| s.to_string())
}

fn persist_last_path(path: Option<&str>) {
    let Some(path) = path else { return };
    let file = config_path();
    if let Some(dir) = file.parent() {
        let _ = std::fs::create_dir_all(dir);
    }
    let _ = std::fs::write(
        file,
        format!("{{\"last_path\":{}}}\n", serde_json::to_string(path).unwrap_or_default()),
    );
}
