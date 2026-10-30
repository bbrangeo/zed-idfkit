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
sources, builds the model-server, and installs it into
`~/.local/share/idfkit-lsp/model-server/dist/`. The script is idempotent.

Then in Zed: **Extensions → Install Dev Extension**, and select the
`zed-idfkit` directory. Opening an `.idf` / `.epJSON` file starts the language
server automatically (hover, completion, diagnostics, semantic highlighting).

The model-server entry is resolved in this order: `$IDFKIT_LSP_HOME`,
`$XDG_DATA_HOME/idfkit-lsp`, `~/.local/share/idfkit-lsp`, `~/idfkit-lsp`.

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
4. installe le résultat dans `~/.local/share/idfkit-lsp/model-server/dist/`.

Le script est **idempotent** : relançable sans risque.

Ensuite, dans Zed : **Extensions → Install Dev Extension** (cmd-shift-P →
`extensions: install dev extension`) et sélectionnez le répertoire
`zed-idfkit-extension`.

Au premier fichier `.idf` / `.epJSON` ouvert, l'extension résout
automatiquement le model-server et le lance avec `node … --stdio`.

### Répertoires de recherche du model-server

Dans l'ordre :

1. `$IDFKIT_LSP_HOME/model-server/dist/main.js`
2. `$XDG_DATA_HOME/idfkit-lsp/model-server/dist/main.js`
3. `~/.local/share/idfkit-lsp/model-server/dist/main.js`
4. `~/idfkit-lsp/model-server/dist/main.js`

## Dépannage

### Erreur « language server idfkit-lsp introuvable »

Le model-server n'est pas installé. Lancez `./install.sh` puis rechargez
Zed (`workspace: reload`). Vous pouvez surcharger l'emplacement avec
`IDFKIT_LSP_HOME`.

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
