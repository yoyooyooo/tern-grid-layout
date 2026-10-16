# Tern Grid Layout

[English](./README.md) | [简体中文](./README.zh-CN.md)

[Install](#installation) · [Quick start](#quick-start) · [Configure](#configuration) · [Reference](./docs/reference.md)

Keep a busy Tern tab readable: arrange its panes into equal-width columns when the window resizes or when you ask. Manual divider adjustments stay in place between window resizes.

**Cmd+K → Grid → Grid Layout: Arrange Responsive Panes**  
Shortcut: **Control + Option + Shift + G**.

Experimental **0.5.0**, verified on **macOS / Tern 0.8.3**. Source is hosted at [yoyooyooo/tern-grid-layout](https://github.com/yoyooyooo/tern-grid-layout); no tagged release is published yet.

## How it works

Repeated splits can leave one pane much smaller than its neighbors. Grid Layout reads the available tab width, chooses a column count and divides the panes across those columns. Columns have equal widths; panes within each column have equal heights. Existing pane programs keep running.

Automatic arrangement follows a change in the **window's width or height**. Loading the plugin, adding or closing panes, switching tabs, adjusting dividers or changing the sidebar does not itself request a new layout. Only the focused tab is arranged; single-pane and zoomed tabs update the size baseline without automatic arrangement.

## Installation

You need the Tern desktop app and a working CLI. Run this in a terminal first:

```sh
tern --version
```

The verified host is **Tern 0.8.3**. On macOS the plugin calls the CLI inside the standard app location, `/Applications/Tern.app/Contents/MacOS/tern`. For another location, set `executable` in the [configuration reference](./docs/reference.md#configuration). Other platforms and host versions are unverified. Node.js and npm are not needed to run the plugin.

Obtain the source directory or extract a source archive, then open a terminal **in that directory** (it contains `plugin.toml`). Run:

```sh
tern plugin install "$PWD" --json
tern plugin list --json
```

In the plugin list, confirm ID `grid-layout`, version `0.5.0` and status `ready`, with no plugin problems. No configuration is required for the standard macOS installation. Use a clean source archive: Tern copies the directory, so development dependencies should not be present. Contributors can [link a checkout instead](./CONTRIBUTING.md#local-checks).

## Quick start

1. In a disposable Tern tab, split right twice to create three panes.
2. Press **Control + Option + Shift + G**, or open **Cmd+K**, search **Grid** and choose **Grid Layout: Arrange Responsive Panes**.
3. Check the result: panes form equal-width columns, with panes stacked evenly when the window is narrower. At the default setting, three panes fit in three columns when the available tab area is at least 1920 logical pixels wide. Sidebar space is excluded.
4. Drag a divider to a custom position. It stays there across polling cycles. Resize the window or run the command again to restore an even layout.

The plugin observes window size every 500 ms and waits at least 200 ms after an observed change before arranging. Query latency adds to that delay. There is no plugin-provided undo; use a disposable tab for the first run.

## Configuration

To fit more columns in a narrower window, lower the column-width threshold. For example, use 540 logical pixels:

```json
{
  "min_width": 540
}
```

Save this as `plugin-data/grid-layout/config.json` under your Tern configuration directory: by default `~/Library/Application Support/Tern` on macOS, or the directory selected by `TERN_CONFIG_DIR`. The default threshold without a file is **640**.

Execute the command to apply the setting immediately, or resize the window. Editing config alone does not request arrangement. See the [full configuration and layout rules](./docs/reference.md#configuration) for valid values, custom CLI paths and multi-window routing.

## Update and uninstall

From a newly extracted source directory, update a copied installation with:

```sh
tern plugin install "$PWD" --force
```

Remove a copied installation with `tern plugin remove grid-layout`. For a linked checkout, reload changes with `tern plugin reload` and unlink with `tern plugin unlink grid-layout`. Tern refuses to overwrite linked plugins; [switch installation modes explicitly](./docs/reference.md#installation-modes).

## Limits and trust

This plugin uses Tern's developer control interface, which can change across host versions. Geometry queries can start up to two short-lived CLI processes per observation, even in single-pane or zoomed tabs. Multi-window routing may require an explicit control endpoint. Errors during automatic queries are quiet; run the command to inspect failures. See [operation and troubleshooting](./docs/reference.md#operation-and-troubleshooting).

Tern 0.8.3–0.8.4 has a large native-ID bridge limitation. Arrangement uses live tab positions to avoid an unrelated tab causing `unknown tab`; a focused pane/tab whose own ID cannot round-trip remains unsupported. See [troubleshooting](./docs/reference.md#operation-and-troubleshooting).

The plugin reads its config, selected Tern environment variables and window/pane geometry, and runs the configured CLI. It sends no network requests or telemetry and stores no pane contents or diagnostic logs. Treat the configured executable and control endpoint as trusted local authority. Details and the current reporting limitation are in [SECURITY.md](./SECURITY.md).

## Contributing

[CONTRIBUTING.md](./CONTRIBUTING.md) covers development checks, native smoke verification and version policy. [CHANGELOG.md](./CHANGELOG.md) records changes; [readiness evidence](./docs/readiness.md) distinguishes local verification from remaining public-release work.

Licensed under [MIT](./LICENSE).
