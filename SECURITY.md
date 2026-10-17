# Security

## Scope

This is an experimental local Tern plugin. Only the current 0.5.x line is considered for fixes, on macOS with native acceptance recorded on Tern 0.8.3 and compatibility smoke on 0.9.1. There is no response-time or long-term support commitment.

The plugin executes the configured Tern CLI, reads its config and selected Tern environment variables, inspects session/tab/pane metadata and window geometry through local daemon/control endpoints, and rearranges panes. It does not send network requests, telemetry or pane contents. Tern itself is outside this plugin's security boundary.

Only install source you trust. Treat plugin files, `config.json` (especially `executable`), daemon sockets and control endpoints as local executable authority. Do not expose control endpoints to untrusted users. Subprocess environment inheritance is controlled by Tern; this plugin forwards selected routing variables explicitly but does not promise an empty environment. CLI errors may contain local paths in manual error toasts; redact them before sharing.

## Reporting

The [public repository](https://github.com/yoyooyooo/tern-grid-layout) accepts ordinary issues, but no dedicated private vulnerability inbox is configured. Do not post exploit details, tokens, pane output or machine configuration in public. Request a private reporting channel from the maintainer without disclosing vulnerability details, then share the affected version, reproduction and impact privately. A verified private reporting route remains a release prerequisite; public source hosting does not establish that service.

No third-party runtime code is bundled. The pinned `luau-web` package is used only for development verification. Review development audit findings separately from the installed plugin.
