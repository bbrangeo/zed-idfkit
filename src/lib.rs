use zed_extension_api as zed;

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

/// Resolves the model-server data home (NOT the entry point itself):
///
/// 1. the `IDFKIT_LSP_HOME` environment variable
/// 2. `$XDG_DATA_HOME/idfkit-lsp`, then `~/.local/share/idfkit-lsp`
///
/// The entry point is `<home>/model-server/dist/main.js`. No filesystem
/// check is performed here: Zed extensions run as WASM (wasip2) and only
/// see the worktree, so `Path::exists()` on absolute paths would always
/// return false. If the file is missing, `node` will log a clear
/// `ERR_MODULE_NOT_FOUND` in Zed's LSP log instead.
fn resolve_model_server_home(worktree: &zed::Worktree) -> String {
    if let Some(home) = env_lookup(worktree, "IDFKIT_LSP_HOME") {
        return home;
    }
    if let Some(xdg) = env_lookup(worktree, "XDG_DATA_HOME") {
        return format!("{xdg}/idfkit-lsp");
    }
    match env_lookup(worktree, "HOME") {
        Some(home) => format!("{home}/.local/share/idfkit-lsp"),
        // No env at all: fall back to the conventional location.
        None => "/home/user/.local/share/idfkit-lsp".to_string(),
    }
}

/// Resolves the `node` binary:
/// 1. the `$PATH` Zed passes through (via `Worktree::which`, a host-side
///    WIT method that works in WASM)
/// 2. usual macOS/Linux fallback paths (no existence check, kept in order)
/// 3. the bare name `node` (delegated to the host process's PATH)
fn resolve_node(worktree: &zed::Worktree) -> String {
    if let Some(node) = worktree.which("node") {
        return node;
    }
    match NODE_FALLBACKS.first() {
        Some(first) => (*first).to_string(),
        None => "node".to_string(),
    }
}

/// Resolves the language server command for Zed. Always succeeds:
///
/// 1. `worktree.which("idfkit-lsp")` — the wrapper created by `install.sh`
///    (`~/.local/bin/idfkit-lsp`) is preferred; it already embeds the
///    absolute path to `model-server/dist/main.js` and the `--stdio` flag.
/// 2. Otherwise, run the model-server directly with node from the default
///    data home (`$IDFKIT_LSP_HOME` > `$XDG_DATA_HOME/idfkit-lsp` >
///    `~/.local/share/idfkit-lsp`), without any existence check.
fn resolve_server_command(worktree: &zed::Worktree) -> zed::Command {
    // 1. Wrapper on the user's PATH (created by install.sh).
    if let Some(wrapper) = worktree.which("idfkit-lsp") {
        return zed::Command {
            command: wrapper,
            args: vec![],
            env: vec![],
        };
    }

    // 2. Fallback: direct node invocation, no existence check.
    let home = resolve_model_server_home(worktree);
    let entry = format!("{home}/model-server/dist/main.js");
    let node = resolve_node(worktree);

    zed::Command {
        command: node,
        args: vec![entry, "--stdio".to_string()],
        env: vec![],
    }
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
        Ok(resolve_server_command(worktree))
    }
}

zed::register_extension!(IdfkitExtension);
