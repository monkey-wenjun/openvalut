//! JSON DTOs shared by the Flutter FFI bridge, the Chrome native host, and the
//! desktop (Tauri) client. Keeping one definition ensures the wire format
//! stays identical across every client.

use serde::{Deserialize, Serialize};

use crate::kdbx::{CreateEntryRequest, Entry, UpdateEntryRequest};

#[derive(Serialize, Deserialize)]
pub struct EntryDto {
    pub uuid: String,
    pub title: String,
    pub username: String,
    pub password: String,
    pub url: String,
    pub notes: String,
    pub group: String,
    pub custom: Vec<CustomFieldDto>,
}

#[derive(Serialize, Deserialize)]
pub struct CustomFieldDto {
    pub key: String,
    pub value: String,
}

impl From<Entry> for EntryDto {
    fn from(e: Entry) -> Self {
        Self {
            uuid: e.uuid,
            title: e.title,
            username: e.username,
            password: e.password,
            url: e.url,
            notes: e.notes,
            group: e.group,
            custom: e
                .custom
                .into_iter()
                .map(|(key, value)| CustomFieldDto { key, value })
                .collect(),
        }
    }
}

#[derive(Deserialize, Default)]
pub struct CreateEntryRequestDto {
    pub title: String,
    pub username: String,
    pub password: String,
    pub url: String,
    pub notes: String,
    pub group: Option<String>,
    pub otp: Option<String>,
    pub ssh_private_key: Option<String>,
    pub machine_id: Option<String>,
    pub custom: Vec<CustomFieldDto>,
}

impl From<CreateEntryRequestDto> for CreateEntryRequest {
    fn from(d: CreateEntryRequestDto) -> Self {
        Self {
            title: d.title,
            username: d.username,
            password: d.password,
            url: d.url,
            notes: d.notes,
            group: d.group,
            otp: d.otp,
            ssh_private_key: d.ssh_private_key,
            machine_id: d.machine_id,
            custom: d.custom.into_iter().map(|c| (c.key, c.value)).collect(),
        }
    }
}

#[derive(Deserialize, Default)]
pub struct UpdateEntryRequestDto {
    pub title: Option<String>,
    pub username: Option<String>,
    pub password: Option<String>,
    pub url: Option<String>,
    pub notes: Option<String>,
    pub group: Option<String>,
    pub otp: Option<String>,
    pub ssh_private_key: Option<String>,
    pub machine_id: Option<String>,
    pub custom: Option<Vec<CustomFieldDto>>,
    pub remove_custom: Option<Vec<String>>,
}

impl From<UpdateEntryRequestDto> for UpdateEntryRequest {
    fn from(d: UpdateEntryRequestDto) -> Self {
        Self {
            title: d.title,
            username: d.username,
            password: d.password,
            url: d.url,
            notes: d.notes,
            otp: d.otp,
            ssh_private_key: d.ssh_private_key,
            machine_id: d.machine_id,
            group: d.group,
            custom: d
                .custom
                .map(|v| v.into_iter().map(|c| (c.key, c.value)).collect())
                .unwrap_or_default(),
            remove_custom: d.remove_custom.unwrap_or_default(),
        }
    }
}
