#!/bin/sh
# Marv OS installer for Linux (and WSL2).
#
#   curl -fsSL https://raw.githubusercontent.com/FlologixAI/marv-os-releases/main/install.sh | sh
#
# Environment:
#   MARV_OS_VERSION   install this version (e.g. 1.0.0-beta.1) instead of the newest release
#   MARV_OS_FORMAT    "deb" or "appimage" to override the automatic choice
#
# The script downloads one package from this repository's GitHub releases,
# verifies it against the release's SHA256SUMS, and installs it. It runs nothing
# else from the network. It uses sudo only for apt, and tells you first.
set -eu

REPO="FlologixAI/marv-os-releases"
API="https://api.github.com/repos/$REPO/releases"

say() { printf '%s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Testing only: serve a release from somewhere else (needs MARV_OS_VERSION).
BASE_URL="${MARV_OS_BASE_URL:-}"

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL --retry 2 -o "$2" "$1"; }
  fetch_out() { curl -fsSL --retry 2 "$1"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q -O "$2" "$1"; }
  fetch_out() { wget -q -O - "$1"; }
else
  die "need curl or wget to download Marv OS"
fi

# --- platform checks ---------------------------------------------------------

[ "$(uname -s)" = "Linux" ] || die "this installer is for Linux. On macOS, download the .dmg from https://github.com/$REPO/releases"

case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  *) die "unsupported CPU '$(uname -m)': only x86_64 builds exist for now" ;;
esac

ID=""; ID_LIKE=""
OSREL="${MARV_OS_RELEASE_FILE:-/etc/os-release}"   # override is for testing
if [ -r "$OSREL" ]; then
  # shellcheck disable=SC1090,SC1091
  . "$OSREL"
fi
DISTRO="${ID:-unknown}"
LIKE=" $DISTRO ${ID_LIKE:-} "

IS_WSL=0
if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  IS_WSL=1
fi

IS_DEBIAN=0
case "$LIKE" in *" debian "*|*" ubuntu "*) command -v apt-get >/dev/null 2>&1 && IS_DEBIAN=1 ;; esac

FORMAT="${MARV_OS_FORMAT:-}"
case "$FORMAT" in
  "") if [ "$IS_DEBIAN" = 1 ]; then FORMAT=deb; else FORMAT=appimage; fi ;;
  deb) [ "$IS_DEBIAN" = 1 ] || die "MARV_OS_FORMAT=deb needs a Debian or Ubuntu system with apt" ;;
  appimage) ;;
  *) die "MARV_OS_FORMAT must be 'deb' or 'appimage'" ;;
esac

if [ "$IS_WSL" = 1 ]; then
  say "Detected WSL ($DISTRO)."
  if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
    warn "WSLg (the graphics layer that shows Linux apps on Windows) doesn't look available."
    warn "In Windows PowerShell run:  wsl --update   then   wsl --shutdown   and open this distro again."
    warn "WSLg needs Windows 10 21H2+ or Windows 11. Installing anyway; Marv OS won't open until WSLg works."
  fi
fi

# --- pick the version --------------------------------------------------------

VERSION="${MARV_OS_VERSION:-}"
VERSION="${VERSION#os-v}"
VERSION="${VERSION#v}"
if [ -n "$BASE_URL" ]; then
  [ -n "$VERSION" ] || die "MARV_OS_BASE_URL needs MARV_OS_VERSION"
else
  if [ -z "$VERSION" ]; then
    say "Looking up the newest Marv OS release..."
    # Releases are pre-releases for now, so /releases/latest would not find them.
    VERSION=$(fetch_out "$API?per_page=30" 2>/dev/null \
      | grep -oE '"tag_name": *"os-v[^"]+"' | head -n 1 | sed -E 's/.*"os-v([^"]+)"/\1/') || true
    [ -n "$VERSION" ] || die "couldn't find a release (GitHub API rate limit?). Set MARV_OS_VERSION=<version> and retry."
  fi
  BASE_URL="https://github.com/$REPO/releases/download/os-v$VERSION"
fi
say "Installing Marv OS $VERSION ($FORMAT, $ARCH)."

# --- download and verify -----------------------------------------------------

WORK=$(mktemp -d)
chmod 755 "$WORK"   # lets apt's sandbox user read the .deb
trap 'rm -rf "$WORK"' EXIT INT TERM

if [ "$FORMAT" = deb ]; then
  FILE="marv-os_${VERSION}_${ARCH}.deb"
else
  FILE="Marv_${VERSION}_${ARCH}.AppImage"
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
  die "need sha256sum or shasum to verify the download"
fi

fetch "$BASE_URL/SHA256SUMS" "$WORK/SHA256SUMS" || die "couldn't download SHA256SUMS for $VERSION (is that version published?)"
say "Downloading $FILE ..."
fetch "$BASE_URL/$FILE" "$WORK/$FILE" || die "couldn't download $FILE"

WANT=$(awk -v f="$FILE" '{n=$2; sub(/^\*/,"",n); if (n==f) {print $1; exit}}' "$WORK/SHA256SUMS")
[ -n "$WANT" ] || die "$FILE is not listed in SHA256SUMS"
GOT=$(sha256 "$WORK/$FILE")
[ "$WANT" = "$GOT" ] || die "checksum mismatch for $FILE (expected $WANT, got $GOT). Nothing was installed."
say "Checksum OK."

# --- helpers -----------------------------------------------------------------

bwrap_hint() {
  command -v bwrap >/dev/null 2>&1 && return 0
  warn "bubblewrap (bwrap) isn't installed. Marv OS runs commands in a sandbox and needs it."
  case "$LIKE" in
    *" arch "*) say "  Install it with:  sudo pacman -S bubblewrap" ;;
    *" fedora "*|*" rhel "*|*" centos "*) say "  Install it with:  sudo dnf install bubblewrap" ;;
    *" suse "*|*" opensuse"*|*" sles "*) say "  Install it with:  sudo zypper install bubblewrap" ;;
    *" debian "*|*" ubuntu "*) say "  Install it with:  sudo apt install bubblewrap" ;;
    *" alpine "*) say "  Install it with:  sudo apk add bubblewrap" ;;
    *) say "  Install the 'bubblewrap' package with your distribution's package manager." ;;
  esac
}

# --- install -----------------------------------------------------------------

if [ "$FORMAT" = deb ]; then
  SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    command -v sudo >/dev/null 2>&1 || die "need root to run apt: install sudo or run this as root"
    SUDO="sudo"
    say "About to run 'sudo apt-get install' for the .deb. This is the only step that uses sudo."
  fi
  if [ -n "$SUDO" ]; then
    $SUDO apt-get install -y "$WORK/$FILE"
  else
    apt-get install -y "$WORK/$FILE"
  fi
  bwrap_hint
  say ""
  say "Marv OS is installed. Start it from your app menu, or run:  marv-os"
else
  BIN_DIR="$HOME/.local/bin"
  APP_DIR="$HOME/.local/share/applications"
  mkdir -p "$BIN_DIR" "$APP_DIR"
  cp "$WORK/$FILE" "$BIN_DIR/marv-os.new"
  chmod 755 "$BIN_DIR/marv-os.new"
  mv -f "$BIN_DIR/marv-os.new" "$BIN_DIR/marv-os"

  EXEC="$BIN_DIR/marv-os"
  if [ ! -e /dev/fuse ] || ! { command -v fusermount >/dev/null 2>&1 || command -v fusermount3 >/dev/null 2>&1; }; then
    warn "FUSE isn't available, which AppImages normally need. Marv OS will unpack itself on each start (slower)."
    EXEC="env APPIMAGE_EXTRACT_AND_RUN=1 $BIN_DIR/marv-os"
    say "  To run it by hand:  APPIMAGE_EXTRACT_AND_RUN=1 marv-os"
  fi
  cat > "$APP_DIR/marv-os.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Marv OS
Comment=Run several coding agents on your own machine
Exec=$EXEC
Terminal=false
Categories=Development;
DESKTOP
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true

  bwrap_hint
  say ""
  say "Marv OS is installed at $BIN_DIR/marv-os, with an app menu entry."
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *) say "Add $BIN_DIR to your PATH to run it as 'marv-os'." ;; esac
  say "To uninstall: rm $BIN_DIR/marv-os $APP_DIR/marv-os.desktop"
fi

if [ "$IS_WSL" = 1 ]; then
  say "On Windows, the app also appears in the Start menu through WSLg."
fi
