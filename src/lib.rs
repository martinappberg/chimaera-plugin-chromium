//! Chromium for Chimaera (plugin API 0.2). The plugin is its manifest:
//! `provides.browser` names the `chrome-headless-shell` its one tool
//! installs, and the daemon's agent browser runs it when the host has no
//! Chrome or Chromium of its own. The host does the download on the user's
//! click (pinned URL, sha256 checked as it streams, size cap, safe unzip);
//! this component adds no views, tools or events.

use chimaera_plugin_api::Plugin;

struct Chromium;

impl Plugin for Chromium {}

chimaera_plugin_api::export!(Chromium);

#[cfg(test)]
mod tests {
    const MANIFEST: &str = include_str!("../plugin.toml");

    /// Each platform the host knows has exactly one download, and every
    /// download names the tool's version in its fixed URL.
    #[test]
    fn every_platform_has_one_pinned_download() {
        let version = MANIFEST
            .lines()
            .skip_while(|l| *l != "[[tools]]")
            .find_map(|l| l.strip_prefix("version = \""))
            .and_then(|v| v.strip_suffix('"'))
            .expect("the tool's version");
        for platform in ["linux-x86_64", "linux-aarch64", "macos-x86_64", "macos-aarch64"] {
            let line = format!("platform = \"{platform}\"");
            assert_eq!(MANIFEST.matches(&line).count(), 1, "{platform}");
        }
        let urls: Vec<&str> = MANIFEST
            .lines()
            .filter_map(|l| l.strip_prefix("url = \""))
            .collect();
        assert_eq!(urls.len(), 4);
        for url in urls {
            assert!(url.starts_with("https://storage.googleapis.com/chrome-for-testing-public/"));
            assert!(url.contains(&format!("/{version}/")), "{url}");
        }
        let shas = MANIFEST.lines().filter(|l| l.starts_with("sha256 = \"")).count();
        assert_eq!(shas, 4);
    }
}
