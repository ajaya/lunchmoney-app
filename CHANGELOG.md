# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.9.0] - 2026-03-12

### Added

- Thor CLI with subcommands for all Lunch Money resources (transactions, categories, accounts, tags, recurring items, summary, user)
- MCP server exposing all operations as Model Context Protocol tools
- Shared three-layer API backend used by both CLI and MCP interfaces
- SQLite caching for API responses
- Foreign key resolver (`--resolve`) for hydrating category, tag, and account references
- `--json` flag on all CLI commands for machine-readable output
- `--resolve` flag on transaction commands to expand foreign key IDs to full objects
- `login` / `logout` commands for token management
- `server config --claude` command to generate MCP configuration snippets
- Configurable logging (`LUNCHMONEY_LOG_LEVEL`, `LUNCHMONEY_LOG_OUTPUT`)
- Docker support with `docker compose`
- GitHub Actions CI and release workflows

[2.9.0]: https://github.com/ajaya/lunchmoney-ruby/releases/tag/v2.9.0
