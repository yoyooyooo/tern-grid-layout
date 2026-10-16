# Changelog

Versions below describe local plugin iterations. They do not imply hosted releases or published tags.

## Unreleased

- Move development into the standalone `tern-grid-layout` source repository, retaining plugin ID `grid-layout`, existing data paths and command ID.
- Add MIT licensing, English and Chinese installation documentation, contribution and security boundaries, behavioral checks and a source archive packer.
- Runtime behavior remains at 0.5.0.
- Document the isolated native window's **Not Now** update preference so fresh test configs do not repeatedly offer to manage OMP.
- Rename the command palette entry to English: `Grid Layout: Arrange Responsive Panes`. The command ID and shortcut are unchanged.
- Align English and Chinese READMEs around installation and first use, add section navigation, and move complete configuration, layout rules and troubleshooting into bilingual references included in the source archive.

## 0.5.0

- Arrange automatically only after a window viewport width or height change. Observe every 500 ms and wait at least 200 ms after an observed change.
- Preserve manual divider proportions, pane creation/removal, tab switches and sidebar adjustments between window resizes.
- Establish a baseline on first observation; automatic observations of zoomed or single-pane tabs update the baseline without arranging.
- Expose `Grid Layout: 自适应均分布局 (Arrange Responsive Panes)` in the command palette. Keep `plugin.grid-layout.grid` and Control+Option+Shift+G.

## 0.4.1

- Use the default macOS app executable without relying on a desktop shell PATH, with an `executable` override.
- Pass daemon routing variables to geometry-query subprocesses and derive the macOS pane socket when needed.
- Reconcile modified split trees during automatic observation. Superseded by the window-only triggers in 0.5.0.

## 0.4.0

- Add automatic observation and resize settling. Initial automatic behavior also initialized layouts and reacted to stage/column changes; superseded by 0.5.0.

## 0.3.0

- Select columns from available stage width and a configurable `min_width`, defaulting to 640 logical pixels.
- Query geometry through Tern's local developer control interface; cancel stale focus or split-tree observations.
- Preserve tab order and focus, equalize column widths and stack surplus panes in the leftmost columns.

## 0.2.0

- Arrange panes in two equal-width columns with equal heights inside each column.

## 0.1.0

- Add an explicit native grid command for Tern 0.8.3 with Control+Option+Shift+G.
