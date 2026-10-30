# idfkit — Zed extension for the IDF language (EnergyPlus)

Zed extension providing IDF / epJSON language support via the **idfkit-lsp
model-server** language server (`--stdio`).

> English summary — full documentation below (French).

## Install (English)

Requirements: [Zed](https://zed.dev), Node.js >= 18, and Rust with
`wasm32-wasip2` (`rustup target add wasm32-wasip2`) to compile the extension.

```sh
git clone https://github.com/bbrangeo/zed-idfkit
cd zed-idfkit
./install.sh
```

`install.sh` clones the [idfkit-lsp](https://github.com/idfkit/idfkit-lsp)
sources, builds the model-server, installs it into
`~/.local/share/idfkit-lsp/model-server/dist/`, and creates an executable
`idfkit-lsp` wrapper in `~/.local/bin` (overridable with `IDFKIT_LSP_BIN`).
The script is idempotent.

The wrapper embeds the absolute path to `dist/main.js` and to `node`. The
extension finds the language server through the user's `PATH` via
`Worktree::which` — Zed extensions run as WASM and only see the worktree, so
they cannot stat absolute paths themselves. Make sure `~/.local/bin` is in
your `PATH` (most shells include it by default).

Then in Zed: **Extensions → Install Dev Extension**, and select the
`zed-idfkit` directory. Opening an `.idf` / `.epJSON` file starts the language
server automatically (hover, completion, diagnostics, semantic highlighting).

The model-server data directory is resolved in this order: `$IDFKIT_LSP_HOME`,
`$XDG_DATA_HOME/idfkit-lsp`, `~/.local/share/idfkit-lsp`. If no wrapper is
found on the `PATH`, the extension falls back to launching `node` directly on
`<data home>/model-server/dist/main.js` (no existence check — a missing file
shows a clear `ERR_MODULE_NOT_FOUND` in Zed's LSP log).

---

# idfkit — extension Zed pour le langage IDF (EnergyPlus)

Extension [Zed](https://zed.dev) fournissant le support du langage IDF / epJSON
via le language server **idfkit-lsp model-server** (`--stdio`).

## Prérequis

- **Zed** (macOS ou Linux)
- **Node.js >= 18** (`node` doit être dans le `PATH` ; fallbacks :
  `/opt/homebrew/bin/node`, `/usr/local/bin/node`)
- **Rust** avec la cible `wasm32-wasip2` (uniquement pour compiler l'extension) :
  ```sh
  rustup target add wasm32-wasip2
  ```

## Installation

```sh
git clone https://github.com/bbrangeo/zed-idfkit
cd zed-idfkit
./install.sh
```

`install.sh` :
1. vérifie que `node >= 18` est disponible (échoue avec un message clair sinon) ;
2. clone les sources de [idfkit-lsp](https://github.com/idfkit/idfkit-lsp)
   dans `~/.local/share/idfkit-lsp/src` ;
3. build le model-server (`npm ci && npm run build`) ;
4. installe le résultat dans `~/.local/share/idfkit-lsp/model-server/dist/`
   (+ `capabilities.json` et `node_modules` à côté, requis par le
   model-server au démarrage) ;
5. crée un wrapper exécutable `idfkit-lsp` dans `~/.local/bin`
   (surchargable avec `IDFKIT_LSP_BIN`).

Le script est **idempotent** : relançable sans risque (wrapper et destination
écrasés à chaque exécution).

Le wrapper embarque le chemin absolu de `dist/main.js` et de `node`.
L'extension trouve le language server via le `PATH` de l'utilisateur
(`Worktree::which`) — les extensions Zed tournent en WASM et ne voient que le
worktree, elles ne peuvent pas tester l'existence de chemins absolus.
Vérifiez que `~/.local/bin` est dans votre `PATH` (la plupart des shells
l'incluent par défaut ; le script logue un avertissement sinon).

Ensuite, dans Zed : **Extensions → Install Dev Extension** (cmd-shift-P →
`extensions: install dev extension`) et sélectionnez le répertoire
`zed-idfkit-extension`.

Au premier fichier `.idf` / `.epJSON` ouvert, l'extension lance
automatiquement le language server.

### Résolution du language server

Dans l'ordre :

1. `worktree.which("idfkit-lsp")` — le wrapper créé par `install.sh`
   (`~/.local/bin/idfkit-lsp`), qui embarque déjà `--stdio` ;
2. repli : `node <répertoire de données>/model-server/dist/main.js --stdio`,
   où le répertoire de données est résolu ainsi : `$IDFKIT_LSP_HOME` >
   `$XDG_DATA_HOME/idfkit-lsp` > `~/.local/share/idfkit-lsp`. Aucune
   vérification d'existence : si le fichier est absent, node affiche un
   `ERR_MODULE_NOT_FOUND` clair dans le log LSP de Zed.

## Dépannage

### Erreur « language server idfkit-lsp introuvable »

Le wrapper n'est pas sur le `PATH` ou `install.sh` n'a pas été lancé. Lancez
`./install.sh` puis rechargez Zed (`workspace: reload`). Vérifiez que
`~/.local/bin` est dans le `PATH` (`which idfkit-lsp`). Vous pouvez
surcharger l'emplacement des données avec `IDFKIT_LSP_HOME` et celui du
wrapper avec `IDFKIT_LSP_BIN`.

### Erreur rustc / wasm32-wasip2 au build

```
error: the target triple wasm32-wasip2 is not installed
```

Installez la cible :

```sh
rustup target add wasm32-wasip2
```

> Note macOS (machine de dev) : si cargo/rustup et rustc proviennent de
> distributions différentes (ex. rustc Homebrew), un `.cargo/config.toml`
> local (non commité, voir `.gitignore`) peut pointer vers le rustc rustup :
> ```toml
> [build]
> rustc = "/path/vers/rustup/toolchains/stable-aarch64-apple-darwin/bin/rustc"
> ```

### Node introuvable

Vérifiez `node --version` (>= 18). Si node est installé hors `PATH`, ajoutez-le
ou installez-le via [nodejs.org](https://nodejs.org) / Homebrew / nvm.

## Développement

```sh
cargo build --target wasm32-wasip2 --release
```

Structure :

- `src/lib.rs` — résolution dynamique du model-server et de node, lancement LSP
- `install.sh` — installation du language server idfkit-lsp
- `languages/idf/config.toml` — configuration du langage IDF (suffixes
  `.idf`, `.epJSON`)
- `extension.toml` — manifeste de l'extension (`[language_servers.idfkit-model]`)
