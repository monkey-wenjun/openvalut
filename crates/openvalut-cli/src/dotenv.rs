//! Minimal `.env` discovery and parsing for `item import-env`.
//!
//! The parser is intentionally small: comments and blank lines are skipped,
//! an optional `export ` prefix is tolerated, values may be wrapped in single
//! or double quotes, and double-quoted values support `\n`/`\t`/`\r` escapes.

use std::path::{Path, PathBuf};

/// Finds the nearest directory holding env files starting at `start` and
/// walking up towards the filesystem root. Returns `[.env, .env.local]` for
/// the files that exist there, mirroring the common local-override ordering.
pub fn find_env(start: &Path) -> Option<Vec<PathBuf>> {
    let mut dir = Some(start.to_path_buf());
    while let Some(d) = dir {
        let mut found = Vec::new();
        for name in [".env", ".env.local"] {
            let path = d.join(name);
            if path.is_file() {
                found.push(path);
            }
        }
        if !found.is_empty() {
            return Some(found);
        }
        dir = d.parent().map(Path::to_path_buf);
    }
    None
}

/// Parses the given files in order; later files override earlier duplicate
/// keys, so `.env.local` naturally wins over `.env`.
pub fn parse_files(paths: &[PathBuf]) -> Result<Vec<(String, String)>, String> {
    let mut out: Vec<(String, String)> = Vec::new();
    for path in paths {
        let text = std::fs::read_to_string(path)
            .map_err(|e| format!("无法读取 {}: {e}", path.display()))?;
        for (key, value) in parse(&text) {
            if let Some(existing) = out.iter_mut().find(|(k, _)| *k == key) {
                existing.1 = value;
            } else {
                out.push((key, value));
            }
        }
    }
    Ok(out)
}

/// Parses `KEY=VALUE` lines in order; later duplicate keys keep their last
/// value, like most dotenv loaders.
pub fn parse(text: &str) -> Vec<(String, String)> {
    let mut out = Vec::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let line = line.strip_prefix("export ").unwrap_or(line);
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let key = key.trim();
        if key.is_empty() {
            continue;
        }
        let value = unquote(value.trim());
        if let Some(existing) = out.iter_mut().find(|(k, _)| *k == key) {
            existing.1 = value;
        } else {
            out.push((key.to_string(), value));
        }
    }
    out
}

fn unquote(value: &str) -> String {
    let bytes = value.as_bytes();
    if bytes.len() >= 2 {
        let (first, last) = (bytes[0], bytes[bytes.len() - 1]);
        let quoted = (first == b'\'' && last == b'\'') || (first == b'"' && last == b'"');
        if quoted {
            let inner = &value[1..value.len() - 1];
            if first == b'\'' {
                return inner.to_string();
            }
            let mut out = String::new();
            let mut chars = inner.chars();
            while let Some(c) = chars.next() {
                if c == '\\' {
                    match chars.next() {
                        Some('n') => out.push('\n'),
                        Some('t') => out.push('\t'),
                        Some('r') => out.push('\r'),
                        Some('"') => out.push('"'),
                        Some('\\') => out.push('\\'),
                        Some(other) => {
                            out.push('\\');
                            out.push(other);
                        }
                        None => out.push('\\'),
                    }
                } else {
                    out.push(c);
                }
            }
            return out;
        }
    }
    value.to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn should_skip_comments_and_blanks() {
        let vars = parse("# comment\n\nFOO=bar\n");
        assert_eq!(vars, vec![("FOO".to_string(), "bar".to_string())]);
    }

    #[test]
    fn should_handle_export_prefix_and_quotes() {
        let vars = parse("export A='x y'\nB=\"p\\nq\"\nC=plain");
        assert_eq!(vars.len(), 3);
        assert_eq!(vars[0], ("A".to_string(), "x y".to_string()));
        assert_eq!(vars[1], ("B".to_string(), "p\nq".to_string()));
        assert_eq!(vars[2], ("C".to_string(), "plain".to_string()));
    }

    #[test]
    fn should_keep_last_duplicate_value() {
        let vars = parse("KEY=first\nKEY=second\n");
        assert_eq!(vars, vec![("KEY".to_string(), "second".to_string())]);
    }
}
