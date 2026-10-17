# Readiness evidence

Public contract: source-distributed Tern plugin 0.5.0, with full native acceptance recorded on macOS / Tern 0.8.3 (e2b8656), bounded 0.8.4 ID-selector smoke and current 0.9.1 (a309fbb) compatibility smoke below. The public [GitHub repository](https://github.com/yoyooyooo/tern-grid-layout) and initial fix PR were authorized on 2026-10-16. On 2026-10-17 the user explicitly authorized submitting the current compatibility fix as a PR, merging it and synchronizing local main. No tagged release is authorized. English and Chinese are maintained for external readers and current users.

## Acceptance ledger

Item identifiers follow each bullet's order in the supplied Open-Source Readiness Checklist. Each row covers all identifiers listed. Remaining remote checks are retained rather than counted as complete.

| Items | Status | Evidence / action |
| --- | --- | --- |
| A1–A2 | pass | README titles and package name identify `tern-grid-layout`; native manifest retains the installed host ID `grid-layout`. |
| A3 | pass | Public source, ordinary issues and PRs use `yoyooyooo/tern-grid-layout`; CONTRIBUTING and SECURITY distinguish public reports from the still-unconfigured private vulnerability route. |
| A4 | pass | MIT LICENSE and package license agree; no vendored third-party runtime code. |
| A5 | pass | Experimental status, historical macOS / Tern 0.8.3 acceptance, current 0.9.1 compatibility smoke and CLI requirements are explicit. |
| A6 | pass | The authorized public repository `yoyooyooo/tern-grid-layout` was created on 2026-10-16. |
| B1–B5 | pass | `npm run check` scans repository text for machine-home and credential patterns; explicit archive allowlist excludes config, logs, dependencies and Git metadata. Source review found no private URLs/session data. Manual CLI error toasts may contain paths; SECURITY requests redaction. This is a bounded scan, not a comprehensive secret audit. |
| B6 | pass | README/SECURITY describe config/environment reads, geometry queries, subprocesses and no plugin network/telemetry/log storage. |
| C1–C2 | pass | English/Chinese READMEs mutually link; CONTRIBUTING requires synchronized public facts. |
| C3 | not_verified | Both language READMEs were observed in a local Bun Markdown preview at desktop and 390px narrow widths. First-screen purpose, command, language links and section navigation render without page overflow. Actual hosted-platform rendering remains unverified; no centered heading or badges were requested. |
| C4–C7 | pass | Documented copy install ran from a clean extracted archive; actual shortcut and palette command exercised. Config, limits and links to deeper documents agree with source. |
| C8 | not_verified | All 44 local Markdown links and anchors resolve. Browser clicks exercised language switching, section jumps and reference navigation in local preview. Actual hosted-platform navigation remains unverified. |
| C9–C10 | pass | Both READMEs document the same version, commands, settings, limits and source distribution status. |
| D1–D3 | pass | Native manifest loads; explicit source archive contains runtime files, both READMEs, linked documents and reproducible check tooling. No node_modules, machine config or generated logs are distributed. |
| D4 | pass | npm lockfile pins `luau-web` 1.5.1; `npm ci --ignore-scripts` completed. |
| D5 | pass | Host/platform support is deliberately limited to the verified combination. Node 22+ and npm are development only. |
| D6–D8 | pass | Real tarball listing inspected, extracted into a fresh directory and installed with Tern's copy installer into an isolated config/daemon. Native smoke described below. |
| D9 | pass | No plugin runtime package dependencies. Development `npm audit --json` returned zero vulnerabilities. |
| D10 | pass | Both READMEs explain install/update/unlink/remove and data/config location. Destructive uninstall was documented from CLI help rather than exercised against the daily installation. |
| E1 | pass | `npm run check` is the documented local gate. |
| E2 | pass | Actual Luau source compiles; behavioral scenarios cover triggers, stale-query guards, high native IDs and queued manual execution. Manifest versions/links/privacy checks run with `npm run check`. No transpilation/build is needed; no separate formatter or static typechecker is adopted. |
| E3–E4 | not_verified | `.github/workflows/ci.yml` checks main/PR with Node 22, locked install, checks, packaging and checks from the extracted source. Local commands are exercised; current-head hosted results must be read separately and branch protection is unverified. |
| E5–E6 | pass | Regression scenarios cover baseline/manual/width/height/sidebar/zoom/single-pane/window-mismatch/focus/config/query-response boundaries using synthetic state. Real host smoke separately proves installed behavior; no native-host equivalence is claimed for the fixture. |
| E7 | pass | Runtime source is authored Luau; the archive is generated from an explicit allowlist with `npm run pack:plugin`. |
| F1 | needs_change | SECURITY describes supported 0.5.x/macOS host scope and no response-time commitment, but a usable private reporting channel must be selected before public release. |
| F2–F4 | pass | README/SECURITY describe local executable/control authority, data boundaries and errors. No credentials in examples. |
| F5 | pass | Zero runtime package dependencies; development audit separately returned zero vulnerabilities. |
| F6 | pass | Original MIT plugin; no third-party runtime code/assets bundled. Development verifier is installed through its lockfile, not vendored. |
| G1–G2 | pass | CONTRIBUTING covers checks/review/versioning; CHANGELOG distinguishes local iterations from hosted releases. |
| G3–G4 | not_applicable | Small local maintainer-reviewed project, no hosted issue workflow; no speculative issue templates, governance, code of conduct or response guarantees adopted. |
| G5 | pass | CONTRIBUTING defines pre-1.0 version policy and synchronized manifests/docs. |
| G6 | not_applicable | No dependency bot adopted without a maintainer workflow. |
| H1 | pass | Standalone Git history starts with the original source baseline; the ID-selector fix is a separate branch for review. |
| H2 | pass | The authorized repository is public and uses `main` as its base branch. |
| H3–H5 | not_applicable | No release commit/tag/publish trigger is claimed. CONTRIBUTING defines immutable version-matching tags for any later remote release. |
| H6–H12 | not_applicable | npm publication/OIDC/registry channels and GitHub Release automation do not apply to this local Tern source distribution. |
| H13 | pass | Public repository creation, initial pushes and PR creation were authorized on 2026-10-16. The user explicitly authorized the current 0.9.1 compatibility PR, its merge and local main synchronization on 2026-10-17; tagged release remains outside scope. |
| H14–H17 | not_verified | Read back remote branch and PR identities after push. No registry publication or GitHub Release is claimed. |
| H18 | pass | The source had no prior Git history; the source baseline and focused fix form the initial public history. |
| H19 | pass | CONTRIBUTING describes reinstalling retained known-good source and issuing a new patch version for fixes. |

## Exercised verification

- Initial conversion: `npm ci --ignore-scripts` and `npm run check` passed runtime compilation, 11 behavior scenarios and 14 links. After README alignment: `npm run check` passed the same behavior scenarios, 42 local documentation links and a bounded privacy scan of 19 files.
- `npm audit --json`: zero reported development vulnerabilities; no plugin runtime package dependencies.
- `npm run pack:plugin`: actual source tarball listing inspected. Extracted archive installed with `tern plugin install <extracted-directory> --json` into a fresh temporary config/daemon and a disposable native window with an explicit endpoint.
- Actual shortcut produced three columns, each 698 logical pixels wide. A real divider adjustment persisted across polling. Cmd+K search for `自适应` and Return rearranged the panes. Height-only resize rearranged; a 1000-wide viewport with `min_width: 540` stacked three panes in one column, each 994 by 270 logical pixels. At 1100 viewport width the available 1094 pixels correctly still fit two columns; the initial smoke assertion expecting one was corrected by using a narrower viewport.
- Native screenshot observed; not distributed because shell prompts contain local identity. No hosted README rendering, other OS, other Tern version or independent review is claimed.
- Daily Tern plugin link points to the standalone checkout; plugin list reports `grid-layout` 0.5.0 `ready` with no problems. Plugin ID, command ID and existing config location are unchanged.
- A read-only GitHub Actions check workflow is included; it has no publication step or secrets. Its constituent npm/archive commands are verified locally, but hosted workflow execution is not claimed.
- After the English-only command rename, reloaded the daily plugin and observed `Grid Layout: Arrange Responsive Panes` in the native Cmd+K palette by searching `Grid`. The earlier Chinese search above records the pre-rename smoke only.
- README alignment uses a bilingual overview → installation → first layout → common configuration path, with complete field definitions, routing, installation modes and troubleshooting in `docs/reference.md` and `docs/reference.zh-CN.md`. Both references are included in the archive and in the contribution synchronization policy. The English command name, runtime and configuration defaults are unchanged.
- Local browser smoke used Bun Markdown with a simple responsive stylesheet, not a hosted forge renderer. Observed both languages at desktop and 390px widths; clicked language links, English installation and Chinese configuration anchors, the reference link, reference translation and return link. No page-level horizontal overflow was observed in the checked narrow README views. Generated preview/scaffolding stays outside the repository.
- Repacked the aligned documentation, inspected the tarball whitelist, then extracted into a fresh directory and ran `npm ci --ignore-scripts` and `npm run check`: 11 behavior scenarios and all 42 links/anchors passed from the distribution itself. Both language references and their link targets are present.
- 2026-10-16 ID investigation on Tern 0.8.4 (`6b4535f`): the screenshot's SDK tab `11029476016218` matches native tab `186951336460378` after the bridge's low-44-bit mapping. A disposable window on the existing daemon reproduced `unknown tab 13778255085571 in session 418398534107137`; numeric session selection separately failed as `unknown session 13778255085569`. Passing string tab position `"1"` with the current session succeeded and preserved focus/tab metadata. Receipts are retained under `/tmp/tern-grid-debug.SyK6Rt/` (`high-tab-before.json`, `high-repro.json`, `high-after.json`). No daily session was rearranged.
- The new regression models the observed SDK/native ID pair in an unrelated tab; it fails with the previous numeric selectors. Updated source passes 12 behavioral scenarios. In a fresh native window using an isolated config/daemon, the actual plugin command changed two side-by-side terminal panes into equal-height rows, preserving focus and the other tabs' order; the split tree and screenshot were observed. This is bounded smoke on 0.8.4, not a repeat of all 0.8.3 acceptance. The focused high-ID pane still fails `tab_of()` in the controlled high-ID window; geometry/native-ID equality, move and even remain host limitations.
- 2026-10-17 Tern 0.9.1 (`a309fbb`): the daily focused native pane `432855394025479` is exposed as SDK `10642928959495`; `tab_of()` and the containing tab lookup return nil. CLI geometry is still available. This is the previously observed SDK bridge limitation affecting the focused pane, rather than missing command registration.
- Replaced numeric SDK layout lookup/mutations with `tern ls --json` topology and native `tern move` decimal string selectors; equalization uses the current window action. Queries verify the full focused ID and recheck the native split tree before mutation. Explicit daemon routing overrides an inherited pane socket. Manual requests arriving during automatic queries are retained. Moves are sequential, so interruption can leave a partial layout.
- An isolated native 0.9.1 window reproduced a native pane `20233590931458` exposed by SDK as `2641404887042`, with `tab_of()` nil. The actual plugin command changed three equal columns into three equal-height rows (994 × 226.67 logical pixels) while keeping that high-ID pane focused. A five-pane case produced three equal columns with 2/2/1 panes; widening the viewport produced four equal columns. Width resize, preserved manual divider ratios, unchanged background tab order/trees and surviving pane programs were observed. Evidence remains outside the source archive under `/tmp/tern-grid-091.5I3NaZ/`, including `high-id-evidence.json` and native screenshots. This is bounded compatibility smoke, not a repeat of every 0.8.3 acceptance case.
- Final local gate: `npm run check` passed Luau compilation, 14 behavioral scenarios, all 44 documentation links and the bounded 19-file scan. The actual Control+Option+Shift+G shortcut rearranged the high-ID five-pane tab; height-only resize restored equal widths and heights after a divider adjustment. Native receipts are in `shortcut-height-evidence.json`. The daily linked plugin was reloaded successfully (`grid-layout` 0.5.0 `ready`, `problems: []`); no daily tab was rearranged for acceptance. The disposable window exited normally.

## Decision

Readiness: `conditional`. Local migration, documentation and consumer installation/behavior are verified; the public source repository and ordinary reporting target are selected. A usable private vulnerability reporting route, hosted rendering and branch protection remain unverified. Hosted CI is evaluated per head; no tagged release or registry publication is claimed.
