#!/usr/bin/env bash
#
# install.sh — installs the idfkit-lsp language server for the Zed idfkit extension.
#
# It:
#   1. checks that node >= 18 is available;
#   2. clones https://github.com/idfkit/idfkit-lsp if needed;
#   3. builds the model-server (npm ci && npm run build);
#   4. copies the result into ~/.local/share/idfkit-lsp/model-server/dist/.
#
# Idempotent: safe to re-run (the clone is reused, the destination is overwritten).
set -euo pipefail

IDFKIT_LSP_REPO="https://github.com/idfkit/idfkit-lsp"
IDFKIT_LSP_SRC="${IDFKIT_LSP_SRC:-$HOME/.local/share/idfkit-lsp/src}"
IDFKIT_LSP_DEST="${IDFKIT_LSP_HOME:-$HOME/.local/share/idfkit-lsp}"

log()  { printf '\033[1;34m[idfkit]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[idfkit] ERREUR:\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. Node >= 18 -----------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    fail "node was not found in PATH. Install Node.js >= 18 (https://nodejs.org) then re-run ./install.sh"
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 18 ]; then
    fail "node >= 18 required (found: $(node --version)). Update Node.js then re-run ./install.sh"
fi
log "found node $(node --version)"

# --- 2. Clone des sources idfkit-lsp -----------------------------------------
if [ -d "$IDFKIT_LSP_SRC/.git" ]; then
    log "sources already present in $IDFKIT_LSP_SRC — git pull"
    git -C "$IDFKIT_LSP_SRC" pull --ff-only || log "pull failed, continuing with the existing copy"
else
    log "cloning $IDFKIT_LSP_REPO into $IDFKIT_LSP_SRC"
    rm -rf "$IDFKIT_LSP_SRC"
    mkdir -p "$(dirname "$IDFKIT_LSP_SRC")"
    git clone --depth 1 "$IDFKIT_LSP_REPO" "$IDFKIT_LSP_SRC"
fi

# --- 3. Build du model-server -------------------------------------------------
if [ ! -d "$IDFKIT_LSP_SRC/model-server" ]; then
    fail "model-server/ directory not found in $IDFKIT_LSP_SRC — the $IDFKIT_LSP_REPO repository does not exist or changed structure."
fi

log "building the model-server (npm ci && npm run build)…"
(
    cd "$IDFKIT_LSP_SRC/model-server"
    npm ci
    npm run build
)

if [ ! -f "$IDFKIT_LSP_SRC/model-server/dist/main.js" ]; then
    fail "dist/main.js missing after build — check the 'build' script in model-server/package.json"
fi

# --- 4. Installation ----------------------------------------------------------
mkdir -p "$IDFKIT_LSP_DEST/model-server"
rm -rf "$IDFKIT_LSP_DEST/model-server/dist"
cp -R "$IDFKIT_LSP_SRC/model-server/dist" "$IDFKIT_LSP_DEST/model-server/dist"

log "installed: $IDFKIT_LSP_DEST/model-server/dist/main.js"
log "Reload Zed (cmd-shift-P → \"workspace: reload\") — the idfkit extension will start the language server automatically."
