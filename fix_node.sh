#!/usr/bin/env bash
# =============================================================================
# fix_node.sh — Clean up conflicting Node.js installs and set up a fresh LTS
#
# HOW TO USE (copy and paste this ONE command into your Terminal):
#   bash fix_node.sh
#
# WHAT THIS SCRIPT DOES (step by step):
#   1. Shows you every Node.js installation it finds on your Mac.
#   2. Warns you BEFORE deleting anything — you must press Y to continue.
#   3. Removes all old/conflicting Node.js and npm binaries.
#   4. Installs a fresh Node.js LTS via Homebrew (brew install node).
#   5. Adds the correct directory to your PATH in ~/.zshrc
#      (auto-detects Apple Silicon vs Intel Mac).
#   6. Reloads ~/.zshrc so the change takes effect immediately.
#   7. Prints node --version, npm --version, and which node to confirm success.
#
# SAFE TO RUN: Nothing is deleted until you type Y and press Enter.
# =============================================================================

set -euo pipefail

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo_step()  { echo -e "${CYAN}${BOLD}>>> $*${RESET}"; }
echo_ok()    { echo -e "${GREEN}    ✔  $*${RESET}"; }
echo_warn()  { echo -e "${YELLOW}    ⚠  $*${RESET}"; }
echo_error() { echo -e "${RED}    ✖  $*${RESET}"; }

# --------------------------------------------------------------------------- #
# STEP 0 — WARNING
# --------------------------------------------------------------------------- #
echo ""
echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${RED}${BOLD}║                        ⚠  WARNING  ⚠                        ║${RESET}"
echo -e "${RED}${BOLD}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo -e "${RED}${BOLD}║  This script will:                                           ║${RESET}"
echo -e "${RED}${BOLD}║  • DELETE all existing Node.js / npm installations           ║${RESET}"
echo -e "${RED}${BOLD}║    (from Homebrew, the official Node.js pkg, and nvm)        ║${RESET}"
echo -e "${RED}${BOLD}║  • MODIFY your ~/.zshrc to update the PATH                  ║${RESET}"
echo -e "${RED}${BOLD}║                                                              ║${RESET}"
echo -e "${RED}${BOLD}║  These are DESTRUCTIVE actions that cannot be easily undone. ║${RESET}"
echo -e "${RED}${BOLD}║  Make sure you have no important running Node.js processes.  ║${RESET}"
echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${YELLOW}${BOLD}Type  Y  and press Enter to continue, or anything else to cancel:${RESET} "
read -r CONFIRM
if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" ]]; then
    echo_warn "Cancelled — nothing was changed."
    exit 0
fi
echo ""

# --------------------------------------------------------------------------- #
# STEP 1 — Detect existing installations
# --------------------------------------------------------------------------- #
echo_step "STEP 1 — Scanning for existing Node.js installations …"

FOUND_ANY=false

for LOC in /usr/local/bin/node /opt/homebrew/bin/node; do
    if [[ -f "$LOC" || -L "$LOC" ]]; then
        echo_warn "Found: $LOC  ($( "$LOC" --version 2>/dev/null || echo 'version unknown' ))"
        FOUND_ANY=true
    fi
done

for LOC in /usr/local/bin/npm /opt/homebrew/bin/npm; do
    if [[ -f "$LOC" || -L "$LOC" ]]; then
        echo_warn "Found: $LOC"
        FOUND_ANY=true
    fi
done

if [[ -d "$HOME/.nvm" ]]; then
    echo_warn "Found nvm directory: $HOME/.nvm"
    # nvm is a shell function, not a binary — source it if present, otherwise
    # fall back to scanning the versions directory directly.
    NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    if [[ -s "$NVM_SCRIPT" ]]; then
        # shellcheck source=/dev/null
        source "$NVM_SCRIPT" 2>/dev/null || true
        NVM_VERS=$(nvm list 2>/dev/null || true)
        [[ -n "$NVM_VERS" ]] && echo_warn "nvm versions installed: $NVM_VERS"
    else
        NVM_VERS=$(find "$HOME/.nvm/versions" -maxdepth 2 -name "node" 2>/dev/null || true)
        [[ -n "$NVM_VERS" ]] && echo_warn "nvm node binaries found: $NVM_VERS"
    fi
    FOUND_ANY=true
fi

if $FOUND_ANY; then
    echo_ok "Scan complete — found installs listed above."
else
    echo_ok "No existing Node.js installations detected."
fi
echo ""

# --------------------------------------------------------------------------- #
# STEP 2 — Remove official pkg Node.js (from /usr/local)
# --------------------------------------------------------------------------- #
echo_step "STEP 2 — Removing official Node.js pkg files from /usr/local …"

OFFICIAL_FILES=(
    /usr/local/bin/node
    /usr/local/bin/npm
    /usr/local/bin/npx
    /usr/local/include/node
    /usr/local/lib/node_modules
    /usr/local/share/man/man1/node.1
    /usr/local/lib/dtrace/node.d
    /usr/local/share/doc/node
    /usr/local/share/systemtap/tapset/node.stp
)

REMOVED_OFFICIAL=false
for F in "${OFFICIAL_FILES[@]}"; do
    if [[ -e "$F" || -L "$F" ]]; then
        echo_warn "Removing: $F"
        sudo rm -rf "$F" && REMOVED_OFFICIAL=true
    fi
done

if $REMOVED_OFFICIAL; then
    echo_ok "Official pkg Node.js files removed."
else
    echo_ok "No official pkg Node.js files found — skipping."
fi
echo ""

# --------------------------------------------------------------------------- #
# STEP 3 — Remove Homebrew Node.js
# --------------------------------------------------------------------------- #
echo_step "STEP 3 — Removing Homebrew Node.js (if installed) …"

if command -v brew &>/dev/null 2>&1; then
    if brew list node &>/dev/null 2>&1; then
        echo_warn "Homebrew node formula found — uninstalling …"
        brew uninstall --ignore-dependencies node && echo_ok "Homebrew node removed."
    else
        echo_ok "Homebrew node not installed — skipping."
    fi
else
    echo_warn "Homebrew not found in PATH — skipping Homebrew removal."
fi
echo ""

# --------------------------------------------------------------------------- #
# STEP 4 — Install Node.js LTS via Homebrew
# --------------------------------------------------------------------------- #
echo_step "STEP 4 — Installing Node.js LTS via Homebrew …"

# Make sure Homebrew is available
if ! command -v brew &>/dev/null 2>&1; then
    echo_warn "Homebrew is not installed. Installing Homebrew first …"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo_ok "Homebrew installed."
fi

echo_warn "Running: brew install node  (this may take a minute …)"
brew install node
echo_ok "Node.js LTS installed via Homebrew."
echo ""

# --------------------------------------------------------------------------- #
# STEP 5 — Update ~/.zshrc with the correct PATH
# --------------------------------------------------------------------------- #
echo_step "STEP 5 — Updating ~/.zshrc with the correct Homebrew PATH …"

# Detect Apple Silicon vs Intel
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_BIN="/opt/homebrew/bin"
    echo_ok "Detected: Apple Silicon Mac (arm64) → Homebrew path: $BREW_BIN"
else
    BREW_BIN="/usr/local/bin"
    echo_ok "Detected: Intel Mac (x86_64) → Homebrew path: $BREW_BIN"
fi

ZSHRC="$HOME/.zshrc"
MARKER="# Added by fix_node.sh — Node.js / Homebrew PATH"

# Create ~/.zshrc if it doesn't exist yet
if [[ ! -f "$ZSHRC" ]]; then
    touch "$ZSHRC"
    echo_ok "Created $ZSHRC (it did not exist)."
fi

# Only add if not already present (idempotent)
if grep -qF "$MARKER" "$ZSHRC" 2>/dev/null; then
    echo_ok "PATH entry already present in ~/.zshrc — skipping duplicate."
else
    {
        echo ""
        echo "$MARKER"
        echo "export PATH=\"$BREW_BIN:\$PATH\""
    } >> "$ZSHRC"
    echo_ok "Added  export PATH=\"$BREW_BIN:\$PATH\"  to $ZSHRC"
fi
echo ""

# --------------------------------------------------------------------------- #
# STEP 6 — Source ~/.zshrc to activate changes immediately
# --------------------------------------------------------------------------- #
echo_step "STEP 6 — Activating ~/.zshrc in the current shell session …"

# Export the new PATH directly so this session benefits immediately even though
# 'source ~/.zshrc' in a script only affects the script's sub-shell.
export PATH="$BREW_BIN:$PATH"

echo_ok "PATH updated for this session: $BREW_BIN is now first in PATH."
echo_warn "Note: Open a new Terminal tab/window (or run  source ~/.zshrc ) to apply"
echo_warn "      the change in other shell sessions."
echo ""

# --------------------------------------------------------------------------- #
# STEP 7 — Verify the installation
# --------------------------------------------------------------------------- #
echo_step "STEP 7 — Verifying Node.js installation …"

if command -v node &>/dev/null 2>&1; then
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version)
    NODE_PATH=$(which node)
    echo_ok "node version : $NODE_VER"
    echo_ok "npm  version : $NPM_VER"
    echo_ok "node location: $NODE_PATH"
    echo ""
    echo -e "${GREEN}${BOLD}🎉  All done! Node.js is installed and working correctly.${RESET}"
    echo -e "${GREEN}    Open a new Terminal tab and run  node --version  to confirm.${RESET}"
else
    echo_error "node command not found after installation."
    echo_error "Try opening a new Terminal window and running  node --version  manually."
    echo_error "If it still fails, run:  source ~/.zshrc"
    exit 1
fi
echo ""
