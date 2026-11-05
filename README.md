# Chromium for Chimaera

A [Chimaera](https://github.com/martinappberg/chimaera) plugin that gives the agent browser a headless Chromium on a host that has none: a cluster job, a remote Linux host, a container where you can't install packages.

Chimaera's agents get `browser_*` tools to see and drive the web apps they build. With the Chimaera app open, the app's own web views answer them. With no app connected, the daemon drives a headless Chrome or Chromium on the host instead, and finds one in this order: the `browser.path` setting, `google-chrome` / `chromium` / `chrome-headless-shell` on the `PATH`, the macOS app bundles, and only then a plugin like this one.

## What it does

- **Nothing until you ask.** Installing the plugin downloads only the plugin itself. The browser is a tool on its card: Extensions → Plugins → Chromium → Tools → **Install**.
- **One pinned build.** [Chrome for Testing](https://googlechromelabs.github.io/chrome-for-testing/)'s `chrome-headless-shell` 157.0.8103.38, for Linux x86_64 and aarch64 and macOS Intel and Apple silicon. Chimaera checks each download's size and sha256 while it streams, unzips it into its own folder (`~/.chimaera/tools/chromium/`, or wherever the `plugins.toolsDir` setting points), and changes nothing else on the system.
- **Where it is switched on.** Like every plugin it serves the sessions of workspaces where it is switched on, and only when the host has no browser of its own.
- **Never on a login node.** Chimaera's agent browser refuses to start a browser on a cluster login node whatever is installed; use it in a job.

About 105 to 130 MB to download, 215 to 290 MB unpacked. Linux hosts need the usual shared libraries of a headless Chromium (NSS among them); when one is missing, the browser tools name it.

## Updating the pin

```sh
scripts/pin.sh 158.0.0000.00   # prints the four [[tools.artifacts]] blocks
scripts/pin.sh --check         # re-downloads every pinned artifact and checks it
```

Paste the blocks into `plugin.toml`, set the tool's `version`, bump the plugin's `version` in `plugin.toml` and `Cargo.toml`, and tag `vX.Y.Z`: the release workflow checks the pins again and publishes `plugin.wasm`, `plugin.toml` and `SHA256SUMS`.

## Build

```sh
cargo test
cargo build --release --target wasm32-wasip2
mkdir -p dist && cp target/wasm32-wasip2/release/chimaera_plugin_chromium.wasm dist/plugin.wasm && cp plugin.toml dist/
chimaera plugin add --path dist
```

MIT licensed. Chrome for Testing is Google's; see its own licence in the downloaded folder.
