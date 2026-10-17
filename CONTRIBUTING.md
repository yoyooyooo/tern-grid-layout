# Contributing

This repository is a source-distributed Tern plugin. Keep runtime dependencies at zero and preserve the plugin ID `grid-layout` and command ID `plugin.grid-layout.grid`.

## Local checks

Requires Node.js 22+, npm, and macOS with Tern for native verification. Full historical acceptance used 0.8.3; current compatibility smoke uses 0.9.1.

```sh
npm ci
npm run check
npm run pack:plugin
```

The check compiles the actual plugin with Luau, exercises trigger/guard behavior, checks manifest/version consistency and local documentation links, and scans distributable text for machine paths and credential patterns. It is not a complete static type checker or native host emulator. No build step is needed for the plugin.

The GitHub Actions check workflow runs the same commands for main and pull requests, then checks an extracted archive. It does not run a graphical Tern window or publish releases; native acceptance remains a separate host check. Check the current head's hosted result before relying on CI.

For live development run `tern plugin link "$PWD"`, then `tern plugin reload` after edits. Never run an experimental plugin against important sessions without first checking an isolated window.

## Native acceptance

Use a fresh temporary Tern config and daemon socket, and start a disposable window with an explicit control endpoint. Install the extracted archive with `tern plugin install <directory> --json` and provide that control endpoint in the isolated plugin config. Use the CLI location appropriate to your host.

Before starting the window, create `omp/state.json` under the temporary `TERN_CONFIG_DIR` with `{"managed":false,"checked":0,"no_build":false,"offered":true}`. This remembers **Not Now** and suppresses the first-run **Manage omp** dialog for that isolated run. Keep the daily configuration and its update preference intact; each new temporary config needs its own state.

Check all of these on the real window:

- First observation keeps a custom split tree unchanged.
- Three panes become equal columns at sufficient stage width when the shortcut or Cmd+K command is executed.
- Divider changes remain intact across several polling cycles; pane creation, tab switches and sidebar changes alone do not arrange.
- Width-only and height-only window resize arrange after settling; narrower stages stack panes.
- Focus and other tabs survive arrangement; programs remain running.
- Zoomed and single-pane tabs do not automatically arrange.
- A wrong control endpoint or focus/tree changes during a query cancel the operation.
- A focused pane whose native ID exceeds 44 bits still arranges; record its native CLI ID and truncated SDK ID. Other tabs and their split trees remain unchanged.

Quit the disposable window after checking. Do not include screenshots with session content, local config, sockets or logs in commits.

## Changes and review

Describe the user-visible trigger and before/after behavior. Include the relevant check output and native evidence; report untested host versions explicitly. Add regression cases for changed behavior, not copies of implementation wiring. Keep both READMEs and both configuration references (`docs/reference.md` and `docs/reference.zh-CN.md`) synchronized for commands, defaults, supported hosts, security boundaries and version changes. When adding linked documentation, include it in the archive allowlist and check navigation from the extracted archive.

This is a small maintainer-reviewed project. A code of conduct, issue templates, automated dependency PRs and response-time promises are not adopted. Use [GitHub issues](https://github.com/yoyooyooo/tern-grid-layout/issues) for ordinary reports and pull requests for contributions; follow SECURITY.md for vulnerabilities.

## Versioning and distribution

Pre-1.0 versions may change configuration or behavior in a minor release; patch releases correct compatible bugs. Record breaking changes explicitly, migrate callers, and avoid compatibility shims.

Update `plugin.toml`, `package.json`, the lockfile, both READMEs and CHANGELOG together. Run checks and inspect the generated tarball before distribution. `npm run pack:plugin` creates `dist/tern-grid-layout-<version>.tar.gz` containing runtime source, public documentation and the tooling needed to reproduce the checks. Installed plugins do not need Node or npm; development dependencies and machine config are excluded. It is a Tern source bundle, not an npm package. Failed local packaging can be rerun after repair. No automatic publish workflow, registry channel or tag trigger exists.

If remote releases are introduced, require explicit publication authorization, immutable annotated `v<version>` tags matching the manifest, and remote commit/tag/archive readback. Never move a published tag; fix a bad release with a new version. Do not call an uploaded archive verified until it has been downloaded, installed and exercised. For a faulty local version, unlink/remove it and reinstall a retained known-good archive; urgent security fixes receive a new patch version.
