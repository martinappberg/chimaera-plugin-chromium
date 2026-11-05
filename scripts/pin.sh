#!/usr/bin/env bash
# Pin chrome-headless-shell for plugin.toml, or check the pins it has.
#
#   scripts/pin.sh 157.0.8103.38   print the four [[tools.artifacts]] blocks
#                                  for that Chrome for Testing version
#   scripts/pin.sh --check         download every artifact plugin.toml names
#                                  and check its size and sha256
#
# Each download is also checked against the MD5 Google's storage reports
# (x-goog-hash), so a pin is never just "whatever came down the wire".
set -euo pipefail

base="https://storage.googleapis.com/chrome-for-testing-public"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

size_of() { wc -c < "$1" | tr -d ' '; }

# Download $1 to $2 and check it against the storage's own MD5.
fetch() {
  local url="$1" out="$2" want got
  curl -fsSL --retry 3 -o "$out" "$url"
  want="$(curl -fsSI "$url" | tr -d '\r' | grep -i '^x-goog-hash: md5=' | sed 's/^[^=]*=//' | head -1)"
  got="$(openssl md5 -binary "$out" | base64)"
  if [ -z "$want" ] || [ "$want" != "$got" ]; then
    echo "$url: MD5 $got does not match the storage's ${want:-(none)}" >&2
    exit 1
  fi
}

if [ "${1:-}" = "--check" ]; then
  manifest="$(dirname "$0")/../plugin.toml"
  # url, sha256, size come in that order in each artifact block.
  paste -d' ' \
    <(sed -n 's/^url = "\(.*\)"$/\1/p' "$manifest") \
    <(sed -n 's/^sha256 = "\(.*\)"$/\1/p' "$manifest") \
    <(sed -n 's/^size = \([0-9]*\)$/\1/p' "$manifest") |
  while read -r url sha size; do
    fetch "$url" "$work/a.zip"
    if [ "$(sha256 "$work/a.zip")" != "$sha" ] || [ "$(size_of "$work/a.zip")" != "$size" ]; then
      echo "$url: not the pinned file (sha256 $(sha256 "$work/a.zip"), $(size_of "$work/a.zip") bytes)" >&2
      exit 1
    fi
    echo "ok $url"
    rm -f "$work/a.zip"
  done
  exit 0
fi

version="${1:?usage: scripts/pin.sh <chrome-for-testing version> | --check}"
for pair in linux-x86_64:linux64 linux-aarch64:linux-arm64 macos-x86_64:mac-x64 macos-aarch64:mac-arm64; do
  platform="${pair%%:*}" cft="${pair#*:}"
  url="$base/$version/$cft/chrome-headless-shell-$cft.zip"
  fetch "$url" "$work/$cft.zip"
  cat <<BLOCK
[[tools.artifacts]]
platform = "$platform"
url = "$url"
sha256 = "$(sha256 "$work/$cft.zip")"
size = $(size_of "$work/$cft.zip")
unpack = "zip"
bin = "chrome-headless-shell-$cft"

BLOCK
  rm -f "$work/$cft.zip"
done
