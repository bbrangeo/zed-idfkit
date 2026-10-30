#!/usr/bin/env bash
#
# install.sh — installs the idfkit-lsp language server for the Zed idfkit extension.
#
# It:
#   1. checks that node >= 18 is available;
#   2. clones https://github.com/idfkit/idfkit-lsp if needed;
#   3. builds the model-server (npm ci && npm run build);
#   4. copies the result into ~/.local/share/idfkit-lsp/model-server/dist/;
#   5. creates an executable `idfkit-lsp` wrapper on the user's PATH so the
#      Zed extension can find the language server via `Worktree::which`.
#
# Idempotent: safe to re-run (the clone is reused, the destination and the
# wrapper are overwritten).
set -euo pipefail

IDFKIT_LSP_REPO="https://github.com/idfkit/idfkit-lsp"
IDFKIT_LSP_SRC="${IDFKIT_LSP_SRC:-$HOME/.local/share/idfkit-lsp/src}"
IDFKIT_LSP_DEST="${IDFKIT_LSP_HOME:-$HOME/.local/share/idfkit-lsp}"
IDFKIT_LSP_BIN="${IDFKIT_LSP_BIN:-$HOME/.local/bin}"

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

# The model-server walks up from dist/main.js looking for capabilities.json
# (DECLARATION_FILENAME) — it must sit at the root of the install destination.
if [ ! -f "$IDFKIT_LSP_SRC/capabilities.json" ]; then
    fail "capabilities.json not found at the root of $IDFKIT_LSP_SRC — the repository layout changed."
fi
cp "$IDFKIT_LSP_SRC/capabilities.json" "$IDFKIT_LSP_DEST/capabilities.json"

# node_modules must sit above dist/ (node resolves imports by walking up from
# the script): the model-server dynamically imports @idfkit/* at startup, and
# without them it starts but advertises no capability.
if [ -d "$IDFKIT_LSP_SRC/model-server/node_modules" ]; then
    rm -rf "$IDFKIT_LSP_DEST/model-server/node_modules"
    cp -R "$IDFKIT_LSP_SRC/model-server/node_modules" "$IDFKIT_LSP_DEST/model-server/node_modules"
fi

log "installed: $IDFKIT_LSP_DEST/model-server/dist/main.js"

# --- 5. Wrapper `idfkit-lsp` sur le PATH ---------------------------------------
# Les extensions Zed tournent en WASM (wasip2) : leur vue du filesystem est
# limitée au worktree. L'extension ne peut donc pas vérifier l'existence de
# dist/main.js ; en revanche `Worktree::which` (méthode hôte) cherche dans le
# PATH de l'utilisateur. Ce wrapper rend le language server découvrable.
#
# Le wrapper embarque le chemin ABSOLU de dist/main.js et de node (résolus
# maintenant, pas de variable dans le fichier généré).
NODE_BIN="$(command -v node)"
mkdir -p "$IDFKIT_LSP_BIN"
cat > "$IDFKIT_LSP_BIN/idfkit-lsp" <<WRAPPER
#!/usr/bin/env bash
exec "$NODE_BIN" "$IDFKIT_LSP_DEST/model-server/dist/main.js" --stdio "\$@"
WRAPPER
chmod +x "$IDFKIT_LSP_BIN/idfkit-lsp"

log "wrapper created: $IDFKIT_LSP_BIN/idfkit-lsp"
case ":$PATH:" in
    *":$IDFKIT_LSP_BIN:"*) ;;
    *) log "warning: $IDFKIT_LSP_BIN is not in your PATH — add it (most shells include ~/.local/bin by default):"
       log "  export PATH=\"$IDFKIT_LSP_BIN:\$PATH\"  (in ~/.zshrc or ~/.bashrc)" ;;
esac

log "Reload Zed (cmd-shift-P → \"workspace: reload\") — the idfkit extension will find idfkit-lsp via the PATH (Worktree::which) and start the language server automatically."
