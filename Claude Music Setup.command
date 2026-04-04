#!/bin/bash

# =============================================================================
# Claude + Apple Music Setup Script
# =============================================================================
# This is the installer. The .dmg file it came in is just a delivery container
# (like a zip or folder) — double-clicking "Claude Music Setup.command" inside
# it is what actually runs the installation. The .dmg itself does nothing and
# can be ejected or deleted once setup is complete.
#
# This script connects Claude Desktop to your Apple Music library so you can
# ask Claude to explore and build historically-informed playlists in plain English.
#
# What this script does:
#   1. Checks that you are running macOS on Apple Silicon
#   2. Checks that Claude Desktop is installed
#   3. Installs Node.js if it is not already present
#   4. Adds the music connector to Claude Desktop's configuration
#   5. Opens the macOS permission screen for the one step you must do manually
# =============================================================================

# Exit immediately if any command fails, treat unset variables as errors,
# and propagate failures through pipes (e.g. curl | installer won't silently hide a curl failure)
set -euo pipefail

# ── Formatting helpers ────────────────────────────────────────────────────────
# tput reads Terminal capabilities to produce bold/color escape sequences.
# The "|| echo """ fallback produces an empty string on terminals that don't
# support tput, so the script still runs cleanly without any stray characters.

BOLD=$(tput bold 2>/dev/null || echo "")
RESET=$(tput sgr0 2>/dev/null || echo "")
GREEN=$(tput setaf 2 2>/dev/null || echo "")
YELLOW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
CYAN=$(tput setaf 6 2>/dev/null || echo "")

# Shorthand print functions used throughout the script for consistent output
step()    { echo; echo "${BOLD}${CYAN}▶ $1${RESET}"; }   # Major step heading
success() { echo "  ${GREEN}✓${RESET} $1"; }              # Green tick for completed actions
warn()    { echo "  ${YELLOW}⚠${RESET}  $1"; }            # Yellow warning (non-fatal)
fail()    { echo; echo "  ${RED}✗ ERROR: $1${RESET}"; echo; exit 1; }  # Red error then exit
info()    { echo "  $1"; }                                 # Plain indented text

# ── Header ────────────────────────────────────────────────────────────────────

clear
echo
echo "${BOLD}Claude + Apple Music Setup${RESET}"
echo "────────────────────────────────────────────────────────────"
echo "This installer connects Claude Desktop to your Apple Music"
echo "library. When finished, you can ask Claude to build playlists"
echo "based on music history, sampling lineage, and influence."
echo "────────────────────────────────────────────────────────────"
echo
echo "The setup takes about 2 minutes and requires your Mac"
echo "password at one point to install Node.js (if needed)."
echo
read -rp "Press Enter to begin, or Ctrl+C to cancel... "

# ── Step 1: Confirm macOS ─────────────────────────────────────────────────────

step "Step 1 of 5 — Checking your system"

# The music connector uses AppleScript to talk to the Music app, which is
# macOS-only. uname returns "Darwin" on all macOS versions.
if [[ "$(uname)" != "Darwin" ]]; then
  fail "This installer only works on macOS. The Apple Music connector \
uses AppleScript, which is a Mac-only technology."
fi

# Only Apple Silicon (arm64) is supported. uname -m returns the CPU architecture.
if [[ "$(uname -m)" != "arm64" ]]; then
  fail "This installer requires an Apple Silicon Mac (M1 or later).
  Intel Macs are not supported."
fi

# sw_vers -productVersion returns the human-readable version, e.g. "14.5"
MACOS_VERSION=$(sw_vers -productVersion)
success "Running macOS $MACOS_VERSION on Apple Silicon"

# ── Step 2: Confirm Claude Desktop is installed ───────────────────────────────

step "Step 2 of 5 — Checking for Claude Desktop"

# Standard installation paths for Claude Desktop on macOS
CLAUDE_APP="/Applications/Claude.app"
CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/claude_desktop_config.json"

# Claude must be installed before we modify its config — there is nothing
# to configure if the app bundle is not present
if [[ ! -d "$CLAUDE_APP" ]]; then
  fail "Claude Desktop is not installed in your Applications folder.
  Please download it from claude.ai/download, install it, sign in,
  and then run this installer again."
fi

success "Claude Desktop is installed"

# Config file changes only take effect after Claude is restarted.
# Warn the user now so they are not surprised at the end.
if pgrep -x "Claude" > /dev/null 2>&1; then
  warn "Claude Desktop is currently open. It will need to be restarted"
  info  "  after this installer finishes for the changes to take effect."
fi

# ── Step 3: Install Node.js if needed ────────────────────────────────────────

step "Step 3 of 5 — Checking for Node.js"

# The music connector is music-mcp, an open-source project by Pedro Cid (@pedrocid).
# Source code and documentation: https://github.com/pedrocid/music-mcp
# License: MIT — free to inspect, modify, and redistribute.
#
# This installer fetches the latest published version from the npm registry
# (@pedrocid/music-mcp@latest) via npx each time Claude starts a music tool session.
# No separate update step is needed — npx always pulls the current release.
#
# TURNING THE CONNECTOR ON OR OFF:
# The easiest way to disable it temporarily is inside Claude Desktop — click
# the "+" icon in the chat input bar, go to Connectors, and toggle the music
# connector off. Toggle it back on the same way to re-enable it. No restart needed.
#
# To disable via the config file instead: quit Claude Desktop, open
# ~/Library/Application Support/Claude/claude_desktop_config.json in a text
# editor, remove the "music" block under "mcpServers", save, and reopen Claude.
# Run this installer again to re-enable it.
#
# LIBRARY LIMITATION:
# The connector can only search and add songs that are already in the user's
# personal Apple Music library. It has no access to the Apple Music streaming
# catalogue. If a requested track is not in the library, the connector will not
# find it and cannot add it to a playlist automatically.
#
# In practice, Claude will build the playlist from whatever matching tracks it
# can find in the library, then list any missing tracks by name so the user can
# find them in Apple Music, add them to their library manually, and ask Claude
# to include them afterwards.
#
# Node.js 18 or later is required by the music-mcp package.
NODE_MIN_VERSION=18

install_node() {
  info "Downloading the Node.js installer from nodejs.org..."
  info "(This may take a minute depending on your internet speed.)"
  echo

  # Apple Silicon (arm64) only. Abort early if someone runs this on an Intel Mac.
  ARCH=$(uname -m)
  if [[ "$ARCH" != "arm64" ]]; then
    fail "This installer requires an Apple Silicon Mac (M1 or later).
  Intel Macs are not supported."
  fi

  # Signed package for Apple Silicon
  NODE_PKG="node-v22.12.0-pkg-signed.pkg"
  NODE_URL="https://nodejs.org/dist/v22.12.0/node-v22.12.0.pkg"

  # Download to /tmp so we don't leave installer files in the user's home folder
  TMP_PKG="/tmp/$NODE_PKG"

  # -f: fail on HTTP errors, -s: silent progress bar, -S: show errors, -L: follow redirects
  if ! curl -fsSL "$NODE_URL" -o "$TMP_PKG"; then
    fail "Could not download Node.js. Please check your internet connection
  and try again, or download Node.js manually from nodejs.org (LTS version)
  and then run this installer again."
  fi

  info "Installing Node.js — your Mac password is required..."
  echo

  # The macOS installer daemon (installer) requires root to write to /usr/local.
  # -pkg points to our downloaded package, -target / means install to the boot volume.
  if ! sudo installer -pkg "$TMP_PKG" -target /; then
    fail "Node.js installation failed. Please install it manually from
  nodejs.org (download the LTS version) and then run this installer again."
  fi

  # Remove the downloaded .pkg now that installation is complete
  rm -f "$TMP_PKG"

  # The installer puts node in /usr/local/bin. Prepend it to PATH so the
  # rest of this script can find the newly installed binary immediately
  # without requiring a new shell session.
  export PATH="/usr/local/bin:/usr/bin:$PATH"
}

if command -v node &>/dev/null; then
  # Strip the leading "v" from the version string (e.g. "v20.11.0" → "20"),
  # then compare just the major version number against our minimum requirement
  NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
  if (( NODE_VERSION >= NODE_MIN_VERSION )); then
    success "Node.js $(node --version) is already installed"
  else
    warn "Node.js $(node --version) is installed but version $NODE_MIN_VERSION+ is required."
    info  "  Installing an updated version now..."
    install_node
    success "Node.js $(node --version) installed successfully"
  fi
else
  info "Node.js is not installed. Installing now..."
  install_node
  success "Node.js $(node --version) installed successfully"
fi

# ── Step 4: Update Claude Desktop configuration ───────────────────────────────

step "Step 4 of 5 — Connecting the music server to Claude Desktop"

# Claude Desktop reads MCP server definitions from this JSON file on startup.
# We need to add a "music" entry under "mcpServers" without removing any
# other servers the user may have already configured.
mkdir -p "$CLAUDE_CONFIG_DIR"

# The JSON block that tells Claude how to start the music MCP server.
# npx downloads and runs the package on demand — no separate install step needed.
MUSIC_SERVER_JSON='{
      "command": "npx",
      "args": ["@pedrocid/music-mcp@latest"]
    }'

if [[ ! -f "$CLAUDE_CONFIG_FILE" ]]; then
  # No config file exists yet — write a minimal valid one from scratch
  info "No existing Claude configuration found. Creating one..."
  cat > "$CLAUDE_CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
    "music": {
      "command": "npx",
      "args": ["@pedrocid/music-mcp@latest"]
    }
  }
}
EOF
  success "Configuration file created"

else
  # Config file already exists — use Python to parse and merge it safely.
  # Python 3 ships with macOS and handles edge cases (trailing commas,
  # malformed JSON) better than sed/awk string manipulation would.
  info "Existing Claude configuration found. Adding music server..."

  MERGE_RESULT=$(python3 - "$CLAUDE_CONFIG_FILE" << 'PYEOF'
import json, sys

config_path = sys.argv[1]

with open(config_path, "r") as f:
    try:
        config = json.load(f)
    except json.JSONDecodeError:
        # The file exists but contains invalid JSON (e.g. was hand-edited).
        # Back it up with a timestamp so the user can recover it, then
        # start fresh rather than aborting the whole install.
        import shutil, datetime
        backup = config_path + ".backup-" + datetime.datetime.now().strftime("%Y%m%d%H%M%S")
        shutil.copy(config_path, backup)
        print(f"BACKUP:{backup}", file=sys.stderr)
        config = {}

# Create the mcpServers key if this config predates MCP support
if "mcpServers" not in config:
    config["mcpServers"] = {}

# Write the music server entry, overwriting any previous version of it
config["mcpServers"]["music"] = {
    "command": "npx",
    "args": ["@pedrocid/music-mcp@latest"]
}

# Write back with consistent 2-space indentation
with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print("OK")
PYEOF
  )

  if [[ "$MERGE_RESULT" == "OK" ]]; then
    success "Music server added to your existing configuration"
  else
    fail "Could not update the Claude configuration file. Please check that
  the file at the path below is valid JSON and try again:
  $CLAUDE_CONFIG_FILE"
  fi
fi

# Final sanity check — confirm the file is valid JSON before we move on.
# This catches any unlikely write errors or filesystem issues.
if python3 -c "import json; json.load(open('$CLAUDE_CONFIG_FILE'))" 2>/dev/null; then
  success "Configuration file verified — JSON is valid"
else
  fail "The configuration file appears to be malformed after writing.
  Please open this file in a text editor and check its contents:
  $CLAUDE_CONFIG_FILE"
fi

# ── Step 5: Open the macOS permission screen ──────────────────────────────────

step "Step 5 of 5 — Opening the macOS permission screen"

info "One permission must be granted manually."
info "macOS requires you to personally approve any application that wants"
info "to control other apps — this cannot be done by a script."
echo
info "What to do when System Settings opens:"
info "  1. Find 'Claude' in the list"
info "  2. Make sure the toggle next to 'Music' is switched ON (blue)"
info "  3. If Claude is not listed yet, it will appear after you first"
info "     use the music tools — come back here and enable it then."
echo
read -rp "  Press Enter to open System Settings now..."

# This URL scheme deep-links directly into the Automation privacy pane,
# skipping the need to navigate through System Settings manually.
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"

success "System Settings opened to Privacy & Security → Automation"

# ── Done ──────────────────────────────────────────────────────────────────────

echo
echo "────────────────────────────────────────────────────────────"
echo "${BOLD}${GREEN}Setup complete.${RESET}"
echo "────────────────────────────────────────────────────────────"
echo
echo "  Two things left to do:"
echo
echo "  ${BOLD}1. Grant the permission${RESET} in System Settings (just opened)."
echo "     Enable the Music toggle under Claude."
echo
echo "  ${BOLD}2. Restart Claude Desktop.${RESET}"
echo "     Quit Claude and reopen it from your Applications folder."
echo "     The music tools will then be active."
echo
echo "  ${BOLD}Then try this prompt in Claude:${RESET}"
echo
echo '  "Build a playlist of the 20 most sampled songs from the 1970s'
echo '   that were sampled in 1980s and 1990s hip hop. Create it in my'
echo '   Apple Music library and call it 70s Hip Hop Samples."'
echo
echo "────────────────────────────────────────────────────────────"
echo
