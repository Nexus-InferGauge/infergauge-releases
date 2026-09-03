#!/bin/sh
# InferGauge installer for macOS/Linux - no root/sudo needed.
#
# Downloads the latest binary, installs it to ~/.local/bin, and adds that
# folder to PATH in your shell's rc file if it isn't there already. Safe to
# re-run any time to upgrade - detects an install already in PATH or already
# added to the rc file and skips redoing that part.
#
# This script itself lives in Nexus-InferGauge/InferGauge under
# packaging/install.sh and is kept in sync on every release to the public,
# source-free Nexus-InferGauge/infergauge-releases repo (see
# .github/workflows/release.yml's homebrew job) - that's the copy
# `curl ... | sh` actually fetches.
set -eu

INSTALL_DIR="$HOME/.local/bin"
REPO="https://github.com/Nexus-InferGauge/infergauge-releases/releases/latest/download"

os=$(uname -s)
arch=$(uname -m)

case "$os" in
  Darwin)
    if [ "$arch" != "arm64" ]; then
      echo "InferGauge no longer ships an Intel macOS build (GitHub's Intel" >&2
      echo "runner fleet has been drawn down too far to build one)." >&2
      echo "Run it under Rosetta with the arm64 build, or use: pip install infergauge" >&2
      exit 1
    fi
    asset="infergauge-macos-arm64.tar.gz"
    ;;
  Linux)
    case "$arch" in
      x86_64|amd64) asset="infergauge-linux-x86_64.tar.gz" ;;
      *)
        echo "InferGauge doesn't ship a Linux $arch build yet - only x86_64." >&2
        echo "Use: pip install infergauge" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "This installer supports macOS and Linux only. On Windows, use:" >&2
    echo "  irm https://raw.githubusercontent.com/Nexus-InferGauge/infergauge-releases/main/install.ps1 | iex" >&2
    exit 1
    ;;
esac

echo "Downloading InferGauge for $os/$arch..."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL "$REPO/$asset" -o "$tmp/infergauge.tar.gz"

mkdir -p "$INSTALL_DIR"
tar -xzf "$tmp/infergauge.tar.gz" -C "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/infergauge"

already_in_path=0
case ":$PATH:" in *":$INSTALL_DIR:"*) already_in_path=1 ;; esac

rc="$HOME/.profile"
case "${SHELL:-}" in
  */zsh) rc="$HOME/.zshrc" ;;
  */bash) rc="$HOME/.bashrc" ;;
esac

already_in_rc=0
if [ -f "$rc" ] && grep -qF "$INSTALL_DIR" "$rc" 2>/dev/null; then
  already_in_rc=1
fi
if [ "$already_in_rc" = "0" ]; then
  printf '\n# Added by the InferGauge installer\nexport PATH="%s:$PATH"\n' "$INSTALL_DIR" >> "$rc"
fi

echo ""
if [ "$already_in_path" = "1" ]; then
  echo "InferGauge updated to the latest version. Run:"
else
  echo "Added $INSTALL_DIR to PATH in $rc."
  echo "InferGauge installed. Open a NEW terminal window (or run: . $rc), then run:"
fi
echo "  infergauge init -y && infergauge run"
echo ""
if [ "$os" = "Darwin" ]; then
  echo "Note: macOS may show a Gatekeeper warning the first time you run it,"
  echo "since the binary isn't code-signed yet. Files fetched with curl usually"
  echo "skip this (only browser downloads get the quarantine flag that triggers"
  echo "it), but if you do see \"cannot be opened\" or \"is damaged\", run:"
  echo "  xattr -d com.apple.quarantine $INSTALL_DIR/infergauge"
fi
