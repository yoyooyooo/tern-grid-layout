# Configuration and operation

[English](./reference.md) | [简体中文](./reference.zh-CN.md) · [README](../README.md)

## Configuration

Read `plugin-data/grid-layout/config.json` relative to Tern's configuration directory. On macOS that directory defaults to `~/Library/Application Support/Tern`; `TERN_CONFIG_DIR` takes precedence. No file is needed for defaults.

| Key | Requirement | Default / meaning |
| --- | --- | --- |
| `min_width` | Required whenever the file exists; positive finite number | 640 logical pixels. Threshold for choosing the number of columns. |
| `executable` | Optional nonempty string | `/Applications/Tern.app/Contents/MacOS/tern` on macOS; `tern` elsewhere. Use an absolute path when a desktop launch has a different PATH. Other platforms are unverified. |
| `control` | Optional nonempty string | No explicit override. Set the control endpoint for the target window if default routing reaches another window. |

To set a CLI path explicitly:

```json
{
  "min_width": 640,
  "executable": "/Applications/Tern.app/Contents/MacOS/tern"
}
```

The example shows the standard path; replace it with the actual absolute CLI path in your installation. Shell variables and `~` are not expanded inside JSON values. The config read is limited to 16 KiB. Invalid JSON or invalid field values pause arrangement; explicit execution displays an error toast.

Configuration is read on every observation. Invoke the command or resize the window to apply a layout setting; editing the file alone does not request arrangement.

### Layout rules

The column count is:

```text
max(1, min(pane_count, floor(available_stage_width / min_width)))
```

Available width excludes the sidebar. Panes are collected in split-tree traversal order, with extra panes assigned to the leftmost columns. Columns have equal widths and panes within each column have equal heights. A window narrower than `min_width` still uses one column: the threshold is not a strict minimum pane size. No minimum-height limit or overflow-to-new-tab behavior is provided.

The first automatic observation establishes a baseline. A change to the window viewport's width or height requests arrangement of the focused tab. Single-pane and zoomed tabs only update the automatic baseline, so leaving zoom alone does not replay a resize. Split-tree edits, pane creation/removal, tab changes, sidebar changes and config edits do not themselves request arrangement. The explicit command arranges immediately when geometry is available.

### Multiple windows

The plugin queries `tern ctl state` and `dump .tn-stage`. It forwards selected Tern routing variables and on macOS can derive the pane daemon socket from the config directory. It rejects a state query whose focused pane does not match and cancels if focus or the split tree changes during the query.

If the explicit command reports that geometry reached a different window, launch the intended window with `tern --control <endpoint>`, where `<endpoint>` is a local control endpoint you choose, and set `control` to that same endpoint. Keep `min_width` in the config. Do not expose endpoints to untrusted users. Automatic discovery of per-window endpoints is not provided; multiple windows sharing one config but using different endpoints need deliberate routing. A shared `control` value should not be assumed to target each window independently.

## Installation modes

From the root of a clean source directory:

```sh
tern plugin install "$PWD" --json
```

This copies the directory into Tern's plugin area. It does not create a live connection to the checkout. Update that copy from a new source directory with `tern plugin install "$PWD" --force` and remove it with `tern plugin remove grid-layout`.

For development, use `tern plugin link "$PWD"` and reload edits with `tern plugin reload`. Unlink with `tern plugin unlink grid-layout`; this removes the registration rather than the source checkout. Tern will not overwrite a linked plugin with an installed copy. To change from a link to a copy, unlink first, then install. To change from a copy to a link, remove the installed copy first, then link. Keep a known-good archive and your configuration before changing installations.

Plugin configuration is stored separately from the source checkout. Uninstall/config cleanup behavior belongs to Tern; do not assume an uninstall erases or preserves all host-owned data without checking the host version.

## Operation and troubleshooting

The plugin observes every 500 ms, with up to two short-lived CLI processes per observation, including single-pane and zoomed tabs. Each CLI call has a 3-second timeout. A size change must remain stable for at least 200 ms before arranging; polling and query time add to the delay. The observation rate is not a guaranteed end-to-end latency.

| Symptom | Check |
| --- | --- |
| Command is missing | Run `tern plugin list --json`; confirm `grid-layout` is `ready`. Reload with `tern plugin reload` and search `Grid` in Cmd+K. |
| Automatic layout appears inactive | Run the explicit command to see an error. Check config validity, CLI path and control routing. Loading or splitting alone should not arrange. |
| Fewer columns than expected | Compare the available tab width, excluding sidebar space, with `min_width`. Run the command after editing config. |
| Custom proportions changed | Window width or height changes intentionally restore an even layout. The plugin has no undo. |
| `unknown tab … in session …` | Tern's SDK ID bridge can truncate large native IDs. This source uses live string positions for all arrangement tabs, so an unrelated high-ID tab no longer blocks the focused layout. Reload an updated linked checkout, or reinstall an updated copy. |
| Current high-ID pane does not arrange, or reports a different window | The focused pane/tab can itself fail SDK lookup or differ from the CLI's native ID. This host limitation remains; the positional tab fix does not repair pane lookup/move/equalization. Do not mask IDs or restart the daemon as a workaround. |
| Host upgrade breaks queries | Full acceptance was recorded on Tern 0.8.3; 0.8.4 has bounded ID-selector and terminal-layout smoke only. The developer control format may change. Retain a known-good source archive. |

The plugin reads config, selected Tern environment variables and geometry, then rearranges existing panes without restarting their programs. It does not make network requests, send telemetry or store pane content/logs. Error toasts can contain local paths from CLI stderr; redact them before sharing. See [SECURITY.md](../SECURITY.md) for executable/control authority and current reporting limits, and [readiness evidence](./readiness.md) for what was exercised.
