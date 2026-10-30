#!/usr/bin/env bash
#
# uninstall.sh — removes what install.sh installed for the Zed idfkit extension.
#
# Default: removes the `idfkit-lsp` wrapper and the installed model-server
# (model-server/dist, capabilities.json, node_modules under the install
# destination). The cloned sources ($IDFKIT_LSP_SRC) and the rest of the
# idfkit-lsp home are preserved: they may hold the user's own work.
#
# --purge: also removes the cloned sources and the whole idfkit-lsp home
# directory. Destructive — everything is re-downloadable, but local
# modifications to the sources are lost.
#
# Idempotent: safe to re-run (already-removed targets are skipped quietly).
#
# Safety: every recursive deletion goes through a guard that requires the
# resolved path to contain "idfkit-lsp", so a mis-set environment variable
# can never target an unrelated directory.
set -euo pipefail

IDFKIT_LSP_HOME="${IDFKIT_LSP_HOME:-$HOME/.local/share/idfkit-lsp}"
IDFKIT_LSP_BIN="${IDFKIT_LSP_BIN:-$HOME/.local/bin}"
IDFKIT_LSP_SRC="${IDFKIT_LSP_SRC:-$HOME/.local/share/idfkit-lsp/src}"

PURGE=0
[ "${1:-}" = "--purge" ] && PURGE=1

log()  { printf '\033[1;34m[idfkit]\033[0m %s\n' "$*"; }
skip() { printf '\033[2m[idfkit]\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m[idfkit] ERREUR:\033[0m %s\n' "$*" >&2; exit 1; }

# Resolves a path and refuses anything that does not contain "idfkit-lsp":
# the last line of defence against a wrong target in a recursive deletion.
guarded() {
    local resolved
    resolved="$(cd "$1" 2>/dev/null && pwd -P)" || resolved="$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)/$(basename "$1")"
    case "$resolved" in
        *idfkit-lsp*) printf '%s' "$resolved" ;;
        *) fail "refusing to delete '$1' (resolves to '$resolved'): the path does not contain 'idfkit-lsp'" ;;
    esac
}

# Removes a file or directory tree, logging what is done.
remove() {
    local target="$1" description="$2"
    if [ ! -e "$target" ]; then
        skip "nothing to remove: $description ($target)"
        return 0
    fi
    local resolved
    resolved="$(guarded "$target")"
    rm -rf "$resolved"
    log "removed $description: $resolved"
}

log "uninstalling the idfkit-lsp language server (Zed idfkit extension)"

# --- 1. The wrapper on the PATH ----------------------------------------------
WRAPPER="$(guarded "$IDFKIT_LSP_BIN/idfkit-lsp")"
if [ -e "$WRAPPER" ]; then
    rm -f "$WRAPPER"
    log "removed wrapper: $WRAPPER"
else
    skip "nothing to remove: wrapper ($WRAPPER)"
fi

# --- 2. The installed model-server --------------------------------------------
# Only what install.sh wrote under the install destination: model-server/
# (dist, node_modules) and capabilities.json. Nothing else in the home is
# touched without --purge.
if [ -d "$IDFKIT_LSP_HOME" ]; then
    remove "$IDFKIT_LSP_HOME/model-server" "installed model-server"
    remove "$IDFKIT_LSP_HOME/capabilities.json" "installed capabilities.json"
else
    skip "nothing to remove: install destination ($IDFKIT_LSP_HOME does not exist)"
fi

# --- 3. Sources and full home: only with --purge ------------------------------
if [ "$PURGE" -eq 1 ]; then
    remove "$IDFKIT_LSP_SRC" "cloned sources"
    if [ -d "$IDFKIT_LSP_HOME" ]; then
        remove "$IDFKIT_LSP_HOME" "idfkit-lsp home directory"
    else
        skip "nothing to remove: idfkit-lsp home ($IDFKIT_LSP_HOME)"
    fi
else
    log "kept the cloned sources: $IDFKIT_LSP_SRC (use --purge to remove them)"
    if [ -d "$IDFKIT_LSP_HOME" ]; then
        log "kept the rest of the idfkit-lsp home: $IDFKIT_LSP_HOME (use --purge to remove it)"
    fi
fi

log "done. Reload Zed (cmd-shift-P → \"workspace: reload\") — the idfkit extension will no longer find the language server."
