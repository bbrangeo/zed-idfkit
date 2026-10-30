# zed-idfkit

IDF / EnergyPlus language support for [Zed](https://zed.dev), powered by the
[idfkit-lsp model-server](https://github.com/idfkit/idfkit-lsp) language
server.

## Features

The language server (idfkit-lsp model-server v0.3.0) provides:

- **Completion** — auto-completion for IDF objects and fields
- **Hover** — documentation on hover
- **Signature help** — parameter hints
- **Versions** — served via the idfkit-lsp `versions` capability
- **Syntax highlighting** — custom Tree-sitter grammar for IDF (`grammars/idf/`),
  with colors for object types, numbers, keyword values (`Yes`, `Autosize`, ...),
  field values and `!-` comments

Automatic `.idf` / `.epJSON` file detection: opening such a file in Zed starts
the language server automatically.

> Note: diagnostics and semantic tokens are **not** provided by the
> model-server — they are not part of its capability set.

## Installation

Install from Zed's extensions page (search for **idfkit**).

For local development: clone this repository, then run the Zed command
`zed: install dev extension` and select the `zed-idfkit-extension` directory.

Requirements: Node.js >= 18 in your `PATH`. The language server itself is
installed by `install.sh` (see below).

## Language Server

`install.sh` builds the idfkit-lsp model-server from source and creates an
executable wrapper `~/.local/bin/idfkit-lsp`. The wrapper embeds the absolute
path to `model-server/dist/main.js` and runs it with `--stdio`.

The extension resolves the language server in this order:

1. `worktree.which("idfkit-lsp")` — the wrapper created by `install.sh`
   (Zed extensions run as WASM and only see the worktree, so they cannot stat
   absolute paths themselves; `Worktree::which` queries the user's `PATH` on
   the host side);
2. fallback: run the model-server directly with `node` from the default data
   home (`$IDFKIT_LSP_HOME` > `$XDG_DATA_HOME/idfkit-lsp` >
   `~/.local/share/idfkit-lsp`).

`uninstall.sh` removes the wrapper and the installed model-server
(`--purge` also removes the cloned sources and the whole idfkit-lsp home).
The `IDFKIT_LSP_HOME` environment variable overrides the model-server data
directory.

## Sibling MCP extension

An optional Model Context Protocol extension exposing idfkit-lsp to Zed's
agent is available at
[bbrangeo/zed-idfkit-mcp](https://github.com/bbrangeo/zed-idfkit-mcp).
