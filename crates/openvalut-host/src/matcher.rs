//! Entry matching based on the registrable domain (eTLD+1).
//!
//! The rule is the same as the Dart/shared matcher: an entry matches the exact
//! host, or any host under the same registrable domain (`accounts.google.com`
//! matches an entry stored as `mail.google.com`). Registrable domains are
//! resolved with the full Mozilla Public Suffix List via the `psl` crate.

/// How closely an entry matched the fill request.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Quality {
    Host,
    Domain,
}

impl Quality {
    pub fn name(&self) -> &'static str {
        match self {
            Quality::Host => "host",
            Quality::Domain => "registrableDomain",
        }
    }
}

/// Lower-cased host of `url`, with a leading `www.` removed.
pub fn host_of(url: &str) -> Option<String> {
    let value = url.trim();
    if value.is_empty() {
        return None;
    }
    let full = if value.contains("//") {
        value.to_string()
    } else {
        format!("https://{value}")
    };
    let after_scheme = full.split("://").nth(1)?;
    // Drop path, query, fragment and port.
    let mut host = after_scheme
        .split(['/', '?', '#', ':'])
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase();
    if host.is_empty() || host.contains('%') || host.chars().any(|c| c.is_whitespace()) {
        return None;
    }
    if host.starts_with("www.") {
        host = host[4..].to_string();
    }
    if host.is_empty() {
        return None;
    }
    Some(host)
}

/// The registrable domain (eTLD+1) of a host, or `None` when there is none
/// (IP addresses, bare single labels, and public suffixes themselves).
pub fn registrable_domain(host: &str) -> Option<String> {
    let host = host.trim_end_matches('.');
    let labels: Vec<&str> = host.split('.').collect();
    if labels.len() < 2 {
        return None;
    }
    // IPv4 address: four numeric labels.
    if labels.len() == 4 && labels.iter().all(|l| l.parse::<u8>().is_ok()) {
        return None;
    }
    psl::domain_str(host).map(|s| s.to_ascii_lowercase())
}

/// Best quality for a request host against an entry URL, or `None`.
pub fn match_quality(request_host: &str, entry_url: &str) -> Option<Quality> {
    let entry_host = host_of(entry_url)?;
    if entry_host == request_host {
        return Some(Quality::Host);
    }
    let request_domain = registrable_domain(request_host)?;
    let entry_domain = registrable_domain(&entry_host)?;
    if request_domain == entry_domain {
        Some(Quality::Domain)
    } else {
        None
    }
}

/// The set of URLs an entry answers to: its primary URL plus any `KP2A_URL*`
/// custom fields.
pub fn entry_urls(url: &str, custom: &[(String, String)]) -> Vec<String> {
    let mut urls = Vec::new();
    if !url.is_empty() {
        urls.push(url.to_string());
    }
    for (k, v) in custom {
        if k.to_ascii_uppercase().starts_with("KP2A_URL") && !v.is_empty() {
            urls.push(v.clone());
        }
    }
    urls
}

/// Best quality across every request host and entry URL.
pub fn best_quality(request_hosts: &[String], entry_urls: &[String]) -> Option<Quality> {
    let mut best: Option<Quality> = None;
    for request in request_hosts {
        for url in entry_urls {
            match match_quality(request, url) {
                Some(Quality::Host) => return Some(Quality::Host),
                Some(q) => best = Some(best.map_or(q, |b: Quality| b.min(q))),
                None => {}
            }
        }
    }
    best
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_host_and_strips_www() {
        assert_eq!(
            host_of("https://accounts.google.com/login").as_deref(),
            Some("accounts.google.com")
        );
        assert_eq!(host_of("www.example.com").as_deref(), Some("example.com"));
        assert_eq!(host_of("github.com:443/x").as_deref(), Some("github.com"));
        assert_eq!(host_of("").as_deref(), None);
        // Matches the Dart host: the "host" of an otpauth URL is its label.
        assert_eq!(host_of("otpauth://totp/x").as_deref(), Some("totp"));
    }

    #[test]
    fn registrable_domain_handles_multipart_suffixes() {
        assert_eq!(
            registrable_domain("accounts.google.com").as_deref(),
            Some("google.com")
        );
        assert_eq!(
            registrable_domain("example.co.uk").as_deref(),
            Some("example.co.uk")
        );
        assert_eq!(
            registrable_domain("a.b.c.example.com.cn").as_deref(),
            Some("example.com.cn")
        );
        assert_eq!(registrable_domain("192.0.2.1").as_deref(), None);
    }

    #[test]
    fn registrable_domain_uses_full_psl() {
        // Private / multi-level suffixes that the old hard-coded list missed.
        assert_eq!(
            registrable_domain("user.github.io").as_deref(),
            Some("user.github.io")
        );
        assert_eq!(
            registrable_domain("a.b.example.pvt.k12.ma.us").as_deref(),
            Some("example.pvt.k12.ma.us")
        );
        // Bare suffixes and non-registrable inputs.
        assert_eq!(registrable_domain("com").as_deref(), None);
        assert_eq!(registrable_domain("localhost").as_deref(), None);
        assert_eq!(registrable_domain("192.0.2.1").as_deref(), None);
    }

    #[test]
    fn match_quality_ranks_host_over_domain() {
        assert_eq!(
            match_quality("accounts.google.com", "https://accounts.google.com/login"),
            Some(Quality::Host)
        );
        assert_eq!(
            match_quality("accounts.google.com", "https://mail.google.com"),
            Some(Quality::Domain)
        );
        assert_eq!(
            match_quality("accounts.google.com", "https://github.com"),
            None
        );
    }
}
