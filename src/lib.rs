use std::path::Path;

use zed_extension_api as zed;

/// Dépôt de l'extension (contient `install.sh`, qui installe idfkit-lsp).
const EXTENSION_REPO: &str = "https://github.com/bbrangeo/zed-idfkit";

/// Fallbacks usuels pour node si absent du `$PATH` transmis par Zed.
const NODE_FALLBACKS: &[&str] = &["/opt/homebrew/bin/node", "/usr/local/bin/node"];

struct IdfkitExtension;

/// Construit une vue clé/valeur de l'environnement shell courant
/// (Zed transmet l'env du shell utilisateur au worktree).
fn shell_env_map(worktree: &zed::Worktree) -> impl Iterator<Item = (String, String)> {
    worktree.shell_env().into_iter()
}

fn env_lookup(worktree: &zed::Worktree, key: &str) -> Option<String> {
    shell_env_map(worktree)
        .find(|(k, _)| k == key)
        .map(|(_, v)| v)
        .filter(|v| !v.trim().is_empty())
}

/// Résout le point d'entrée du model-server idfkit-lsp :
/// `<home>/model-server/dist/main.js`.
///
/// Ordre de recherche :
/// 1. variable d'environnement `IDFKIT_LSP_HOME`
/// 2. `$XDG_DATA_HOME/idfkit-lsp`, puis `~/.local/share/idfkit-lsp`
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

/// Résout le binaire `node` :
/// 1. `$PATH` transmis par Zed (via `Worktree::which`)
/// 2. fallbacks macOS/Linux usuels
/// 3. nom simple `node` (délegué au PATH du processus hôte)
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
        "idfkit: language server idfkit-lsp introuvable \
(model-server/dist/main.js non trouvé dans $IDFKIT_LSP_HOME, \
$XDG_DATA_HOME/idfkit-lsp, ~/.local/share/idfkit-lsp ou ~/idfkit-lsp).\n\n\
Installez-le avec :\n  \
git clone {EXTENSION_REPO} && cd zed-idfkit && ./install.sh\n\n\
Puis rechargez Zed (cmd-shift-P → \"workspace: reload\")."
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
