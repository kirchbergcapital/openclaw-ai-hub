# Changelog

## [1.1.0] — 2026-03-29

### Changed
- **Model upgrade:** Replaced `mistral-small:22b` (Q4_0) with `mistral-small:latest` (Q4_K_M) as recommended 24 GB model
  - Q4_K_M uses more precise quantization → better output quality
  - 16K context window (vs 32K previously) frees ~3 GB VRAM on 24 GB machines
  - Warmup script updated to use `num_ctx: 16384` with `keep_alive: -1`
- **Model table in README:** Updated to reflect real-world production model choices
- **SETUP.md:** Updated Ollama model pull instructions for 24 GB+ machines

### Added
- **Security hardening guide updates:** SSH key-only auth, AllowUsers, pf firewall for VNC via Tailscale
- **Prompt injection detection:** Whitelist for known OpenClaw startup phrases to prevent false positives
- **Session watchdog:** Whitelist for security audit sessions to suppress expected sensitive-file access alerts

### Fixed
- `boot-warmup.sh`: Now references `mistral-small:latest` instead of stale `mistral-small:22b-32k` tag
- Model routing: Removed Qwen 2.5 72B from fallback chain on 24 GB machines (RAM conflict)

---

## [1.0.0] — 2026-03-17

### Added
- Initial release
- Complete setup guide for macOS (native installation via Homebrew)
- Security hardening guide (firewall, FileVault, network isolation)
- Architecture documentation with Mermaid diagrams
- Cost optimization guide (model routing, heartbeat tuning, session hygiene)
- Troubleshooting guide with common issues and solutions
- Installation script with prerequisite checking
- Health check script
- Session cleanup script
- Update script
- LaunchAgent templates (session cleanup, health check, caffeinate)
- Configuration templates (openclaw.json, SOUL.md, HEARTBEAT.md)
