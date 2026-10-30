use std::path::Path;

use zed_extension_api as zed;

/// The idfkit-lsp language server repository (contains the model-server).
const IDFKIT_LSP_REPO: &str = "https://github.com/idfkit/idfkit-lsp";

/// Usual node fallbacks when missing from the `$PATH` Zed passes through.
const NODE_FALLBACKS: &[&str] = &["/opt/homebrew/bin/node", "/usr/local/bin/node"];

struct IdfkitExtension;

/// Builds a key/value view of the current shell environment
/// (Zed passes the user's shell env to the worktree).
fn shell_env_map(worktree: &zed::Worktree) -> impl Iterator<Item = (String, String)> {
    worktree.shell_env().into_iter()
}

fn env_lookup(worktree: &zed::Worktree, key: &str) -> Option<String> {
    shell_env_map(worktree)
        .find(|(k, _)| k == key)
        .map(|(_, v)| v)
        .filter(|v| !v.trim().is_empty())
}

/// Resolves the idfkit-lsp model-server entry point:
/// `<home>/model-server/dist/main.js`.
///
/// Search order:
/// 1. the `IDFKIT_LSP_HOME` environment variable
/// 2. `$XDG_DATA_HOME/idfkit-lsp`, then `~/.local/share/idfkit-lsp`
/// 3. `~/idfkit-lsp`
fn resolve_model_server_entry(worktree: &zed::Worktree) -> Option<String> {
    let mut candidates: Vec<String> = Vec::new();

    if let Some(home) = env_lookup(worktree, "IDFKIT_LSP_HOME") {
        candidates.push(home);
    }

    let user_home = env_lookup(worktree, "HOME");
    if let Some(xdg) = env_lookup(worktree, "XDG_DATA_HOME") {
        candidates.push(format!("{xdg}/idfkit-lsp"));
    }
    if let Some(home) = &user_home {
        candidates.push(format!("{home}/.local/share/idfkit-lsp"));
        candidates.push(format!("{home}/idfkit-lsp"));
    }

    candidates
        .into_iter()
        .map(|base| format!("{base}/model-server/dist/main.js"))
        .find(|entry| Path::new(entry).exists())
}

/// Resolves the `node` binary:
/// 1. the `$PATH` Zed passes through (via `Worktree::which`)
/// 2. usual macOS/Linux fallbacks
/// 3. the bare name `node` (delegated to the host process's PATH)
fn resolve_node(worktree: &zed::Worktree) -> String {
    if let Some(node) = worktree.which("node") {
        return node;
    }
    for candidate in NODE_FALLBACKS {
        if Path::new(candidate).exists() {
            return (*candidate).to_string();
        }
    }
    "node".to_string()
}

fn install_error() -> String {
    format!(
        "idfkit: the idfkit-lsp language server was not found \
(model-server/dist/main.js not found in $IDFKIT_LSP_HOME, \
$XDG_DATA_HOME/idfkit-lsp, ~/.local/share/idfkit-lsp, or ~/idfkit-lsp).\n\n\
Install it with:\n  \
git clone {IDFKIT_LSP_REPO} && cd idfkit-lsp/model-server && npm ci && npm run build \
&& mkdir -p ~/.local/share/idfkit-lsp/model-server \
&& cp -R dist ~/.local/share/idfkit-lsp/model-server/dist\n\n\
Or use the extension's install.sh (https://github.com/bbrangeo/zed-idfkit).\n\n\
Then reload Zed (cmd-shift-P → \"workspace: reload\")."
    )
}

impl zed::Extension for IdfkitExtension {
    fn new() -> Self {
        IdfkitExtension
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        worktree: &zed::Worktree,
    ) -> zed::Result<zed::Command> {
        let model_server =
            resolve_model_server_entry(worktree).ok_or_else(install_error)?;
        let node = resolve_node(worktree);

        Ok(zed::Command {
            command: node,
            args: vec![model_server, "--stdio".to_string()],
            env: vec![],
        })
    }
}

zed::register_extension!(IdfkitExtension);
