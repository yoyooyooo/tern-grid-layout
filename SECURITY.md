# Security

## Scope

This is an experimental local Tern plugin. Only the current 0.5.x line is considered for fixes, on the verified macOS / Tern 0.8.3 combination. There is no response-time or long-term support commitment.

The plugin executes the configured Tern CLI, reads its config and selected Tern environment variables, inspects window geometry through the local developer control endpoint, and rearranges panes. It does not send network requests, telemetry or pane contents. Tern itself is outside this plugin's security boundary.

Only install source you trust. Treat plugin files, `config.json` (especially `executable`), daemon sockets and control endpoints as local executable authority. Do not expose control endpoints to untrusted users. Subprocess environment inheritance is controlled by Tern; this plugin forwards selected routing variables explicitly but does not promise an empty environment. CLI errors may contain local paths in manual error toasts; redact them before sharing.

## Reporting

No public repository or dedicated private vulnerability inbox is configured yet. Do not post exploit details, tokens, pane output or machine configuration in public. Request a private reporting channel from the person who supplied the source, then share the affected version, reproduction and impact privately. Availability of that channel is a release prerequisite; this local conversion does not claim a public security reporting service.

No third-party runtime code is bundled. The pinned `luau-web` package is used only for development verification. Review development audit findings separately from the installed plugin.
