# zed-idfkit

IDF / EnergyPlus language support for [Zed](https://zed.dev), powered by the
[idfkit-lsp model-server](https://github.com/idfkit/idfkit-lsp) language
server.

## Features

The language server (idfkit-lsp model-server v0.3.0) provides:

- **Completion** — auto-completion for IDF objects and fields
- **Hover** — documentation on hover
- **Diagnostics** — inline errors and warnings
- **Semantic tokens** — theme-aware token highlighting
- **Go-to-definition** — jump between referenced IDF objects
- **Versions** — served via the idfkit-lsp `versions` capability
- **Syntax highlighting** — custom Tree-sitter grammar for IDF (`grammars/idf/`),
  with colors for object types, numbers, keyword values (`Yes`, `Autosize`, ...),
  field values and `!-` comments

Automatic `.idf` file detection: opening such a file in Zed starts the
language server automatically.

> Note: signature help is **not** provided by the model-server — it is
> `absent_permanent` for model text. `.epJSON` files are left to Zed's
> built-in JSON support. See `capabilities.json` in the
> [idfkit-lsp repository](https://github.com/idfkit/idfkit-lsp) for the
> authoritative capability list.

## Installation

### 1. Install the extension

In Zed: open the extensions page (`cmd-shift-x`), search for **idfkit**, and
click **Install**.

> Not yet published to the registry? Install it as a dev extension: clone this
> repository, run the Zed command `zed: install dev extension`, and select the
> `zed-idfkit-extension/` directory.

### 2. Install the language server (one-time, required)

The extension only knows how to *start* the language server — the server
itself must be installed on your machine. Run:

```sh
curl -fsSL https://raw.githubusercontent.com/bbrangeo/zed-idfkit/main/install.sh | bash
```

or, if you cloned this repository:

```sh
cd zed-idfkit-extension
./install.sh
```

What it does (idempotent — safe to re-run):

1. checks that Node.js >= 18 is in your `PATH`
2. clones [idfkit/idfkit-lsp](https://github.com/idfkit/idfkit-lsp) into
   `~/.local/share/idfkit-lsp/src`
3. builds the model-server (`npm ci && npm run build`)
4. installs it into `~/.local/share/idfkit-lsp/model-server/dist/`
5. creates an `~/.local/bin/idfkit-lsp` wrapper (on your `PATH`) that the
   extension finds via `Worktree::which`

### 3. Reload Zed

`cmd-shift-p` → `workspace: reload`. Open an `.idf` file — the language server
starts automatically and syntax highlighting is applied.

### Verify

- `cmd-shift-p` → `editor: restart language server` / check the LSP logs
- `~/.local/bin/idfkit-lsp` should exist and be executable

### Troubleshooting

**"the idfkit-lsp language server was not found"** — the model-server is not
installed: run `install.sh` (step 2 above), then reload Zed.

**No syntax highlighting** — make sure the file is detected as IDF (bottom bar
shows `IDF`). If it shows plain text, close and reopen the file after the
extension is installed.

**`node` not found by Zed** — the extension looks for `node` via the user's
`PATH`, with fallbacks to `/opt/homebrew/bin/node` and `/usr/local/bin/node`.
Install Node.js >= 18 (<https://nodejs.org>).

**Custom install location** — set `IDFKIT_LSP_HOME` before installing, and the
extension picks it up automatically (resolution order: `$IDFKIT_LSP_HOME` >
`$XDG_DATA_HOME/idfkit-lsp` > `~/.local/share/idfkit-lsp`).

### Uninstall

```sh
./uninstall.sh          # removes the wrapper + installed model-server
./uninstall.sh --purge  # also removes cloned sources and the idfkit-lsp home
```

Then remove the extension from Zed's extensions page.

## How the extension resolves the language server

Zed extensions run as WASM components and cannot stat absolute paths
themselves. The extension therefore resolves the server in this order:

1. `worktree.which("idfkit-lsp")` — the wrapper created by `install.sh`
   (`Worktree::which` queries the user's `PATH` on the host side);
2. fallback: run the model-server directly with `node` from the default data
   home (`$IDFKIT_LSP_HOME` > `$XDG_DATA_HOME/idfkit-lsp` >
   `~/.local/share/idfkit-lsp`).

## Platform support

- **macOS / Linux** — fully supported, as described above.
- **Windows** — the current install flow is POSIX-only (`install.sh`,
  the `/bin/sh`-based wrapper). It will be supported together with the
  npm-based install (see [Upcoming changes](#upcoming-changes)): the
  extension will switch to `zed::npm_install_package` +
  `zed::node_binary_path()`, which works on all platforms Zed supports.

## Local development

```sh
git clone https://github.com/bbrangeo/zed-idfkit
cd zed-idfkit/zed-idfkit-extension
git clone https://github.com/bbrangeo/tree-sitter-idf grammars/idf  # grammar clone required for dev installs
```

Then: `zed: install dev extension` → select `zed-idfkit-extension/`.

The grammar is **not committed** to this repository (the Zed extension builder
downloads it from its own repository); a local git clone is only needed for dev
extension installs.

## Upcoming changes

The current install flow (`install.sh` + wrapper + Node fallbacks) is
**temporary**. The idfkit model server has never been published as a package
(it's `private` in `model-server/package.json` and only ships inside the VS
Code extension), which is why the install script clones `main` and builds from
source.

Once the model server is [published to npm with a `bin`
entry](https://github.com/idfkit/idfkit-lsp/issues/32) (tracking issue on the
idfkit side), this extension will switch to:

- `zed::npm_install_package("...")` — version-pinned install managed by Zed,
  replacing `install.sh`, the wrapper script and the cloned sources;
- `zed::node_binary_path()` — Zed's own bundled Node, replacing the `PATH`
  lookup and the `/opt/homebrew/bin/node` / `/usr/local/bin/node` fallbacks.

The extension version will then track the server version directly. This
repository will be updated (and the extension re-released) as soon as the npm
package is available.

## Sibling MCP extension

An optional Model Context Protocol extension exposing `idfkit-mcp`
(EnergyPlus modeling tools: build, validate, simulate) to Zed's agent is
available at
[bbrangeo/zed-idfkit-mcp](https://github.com/bbrangeo/zed-idfkit-mcp).
