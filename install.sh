#!/usr/bin/env bash
#
# install.sh — installe le language server idfkit-lsp pour l'extension Zed idfkit.
#
# Ce script :
#   1. vérifie que node >= 18 est disponible ;
#   2. clone https://github.com/idfkit/idfkit-lsp si nécessaire ;
#   3. build le model-server (npm ci && npm run build) ;
#   4. copie le résultat dans ~/.local/share/idfkit-lsp/model-server/dist/.
#
# Idempotent : peut être relancé sans risque (le clone est réutilisé,
# la destination est écrasée).
set -euo pipefail

IDFKIT_LSP_REPO="https://github.com/idfkit/idfkit-lsp"
IDFKIT_LSP_SRC="${IDFKIT_LSP_SRC:-$HOME/.local/share/idfkit-lsp/src}"
IDFKIT_LSP_DEST="${IDFKIT_LSP_HOME:-$HOME/.local/share/idfkit-lsp}"

log()  { printf '\033[1;34m[idfkit]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[idfkit] ERREUR:\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. Node >= 18 -----------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    fail "node est introuvable dans le PATH. Installez Node.js >= 18 (https://nodejs.org) puis relancez ./install.sh"
fi
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 18 ]; then
    fail "node >= 18 requis (trouvé : $(node --version)). Mettez à jour Node.js puis relancez ./install.sh"
fi
log "node $(node --version) détecté"

# --- 2. Clone des sources idfkit-lsp -----------------------------------------
if [ -d "$IDFKIT_LSP_SRC/.git" ]; then
    log "sources déjà présentes dans $IDFKIT_LSP_SRC — git pull"
    git -C "$IDFKIT_LSP_SRC" pull --ff-only || log "pull échoué, on continue avec la copie existante"
else
    log "clone de $IDFKIT_LSP_REPO vers $IDFKIT_LSP_SRC"
    rm -rf "$IDFKIT_LSP_SRC"
    mkdir -p "$(dirname "$IDFKIT_LSP_SRC")"
    git clone --depth 1 "$IDFKIT_LSP_REPO" "$IDFKIT_LSP_SRC"
fi

# --- 3. Build du model-server -------------------------------------------------
if [ ! -d "$IDFKIT_LSP_SRC/model-server" ]; then
    fail "répertoire model-server/ introuvable dans $IDFKIT_LSP_SRC — le repo $IDFKIT_LSP_REPO n'existe pas ou a changé de structure."
fi

log "build du model-server (npm ci && npm run build)…"
(
    cd "$IDFKIT_LSP_SRC/model-server"
    npm ci
    npm run build
)

if [ ! -f "$IDFKIT_LSP_SRC/model-server/dist/main.js" ]; then
    fail "dist/main.js absent après le build — vérifiez le script 'build' dans model-server/package.json"
fi

# --- 4. Installation ----------------------------------------------------------
mkdir -p "$IDFKIT_LSP_DEST/model-server"
rm -rf "$IDFKIT_LSP_DEST/model-server/dist"
cp -R "$IDFKIT_LSP_SRC/model-server/dist" "$IDFKIT_LSP_DEST/model-server/dist"

log "installé : $IDFKIT_LSP_DEST/model-server/dist/main.js"
log "Rechargez Zed (cmd-shift-P → \"workspace: reload\") — l'extension idfkit démarrera le language server automatiquement."
