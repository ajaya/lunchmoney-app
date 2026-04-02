# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install          # Install dependencies
bundle exec rake test   # Run all tests
bundle exec ruby bin/lunchmoney help    # Run the CLI
bundle exec ruby bin/lunchmoney server              # Start MCP server (stdio, requires LUNCHMONEY_API_TOKEN)
bundle exec ruby bin/lunchmoney server --http       # Start MCP server (HTTP on port 9292)
bundle exec ruby bin/lunchmoney server --http --port 8080  # Custom HTTP port

# Run a single test file
bundle exec ruby -Ilib -Itest test/tools/transactions_test.rb

# Docker
docker compose up --build
```

## Environment

Copy `.env.local` from `.env` and set `LUNCHMONEY_API_TOKEN` (obtain from https://my.lunchmoney.app/developers). `.env.local` is gitignored and loaded last, overriding `.env` defaults. Other configurable variables: `LUNCHMONEY_API_BASE_URL` (defaults to `https://dev.lunchmoney.app/v2`), `LUNCHMONEY_CACHE_DB_PATH`, `LUNCHMONEY_LOG_LEVEL`, `LUNCHMONEY_LOG_OUTPUT`.

The CLI can also authenticate via `lunchmoney login <TOKEN>`, which writes the token to `.env.local` in the project root. `lunchmoney logout` resets it to the placeholder value.

## Architecture

This project provides a single `bin/lunchmoney` CLI (Thor) that includes both human-friendly commands and an MCP server (`lunchmoney server`). Both share the same backend code.

**Naming conventions:**

- **Repo/gem:** `lunchmoney-ruby`
- **Ruby module:** `LunchMoneyApp` (avoids collision with `LunchMoney` module from the SDK gem)
- **File root:** `lib/lunchmoney_app.rb` / `lib/lunchmoney_app/`
- **SDK dependency:** `lunchmoney-sdk-ruby` (defines `LunchMoney::*Api` classes, `LunchMoney.configure`, `LunchMoney::VERSION`)

**Three-layer design:**
```
Interface:     bin/lunchmoney (Thor CLI + `server` subcommand for MCP)
                              ↓
Backend:           lib/lunchmoney_app/api/*.rb
                              ↓
SDK:               lunchmoney-sdk-ruby (LunchMoney::*Api classes) → Lunch Money REST API
```

**Shared backend** (`LunchMoneyApp::Api::*` classes) — contains all business logic. Both MCP tool handlers and CLI commands delegate to `Api::*` classes which call SDK API classes (`LunchMoney::TransactionsApi`, etc.). When adding new operations, add the method to the `Api` class first, then wire it into both MCP and CLI.

**Zeitwerk note:** The module is `LunchMoneyApp` but the root file is `lunchmoney_app.rb`. Zeitwerk cannot infer this capitalization, so `lib/lunchmoney_app.rb` registers a custom inflection: `loader.inflector.inflect("lunchmoney_app" => "LunchMoneyApp")`. The loader is centralized in the root module — entry points call `LunchMoneyApp.eager_load!` after Sequel DB setup.

**Key files:**

| File | Role |
|------|------|
| `bin/lunchmoney` | CLI entry point: loads env, starts Thor (`lunchmoney server` starts the MCP server) |
| `lib/lunchmoney_app.rb` | Root namespace, Zeitwerk loader, `LunchMoneyApp::VERSION` |
| `lib/lunchmoney_app/cli/base.rb` | Thor base class (`exit_on_failure? = true`) |
| `lib/lunchmoney_app/cli/main.rb` | Thor CLI root: login/logout/server + subcommands |
| `lib/lunchmoney_app/cli/output.rb` | CLI output helper: serialization, resolve, JSON/human routing, pagination (`terminal-table` + `tty-pager`) |
| `lib/lunchmoney_app/cli/*.rb` | CLI subcommands (transactions, categories, plaid_accounts, manual_accounts, tags, recurring_items, summary, user, server) |
| `lib/lunchmoney_app/api/*.rb` | Shared backend: one class per resource (inherits `Base`), used by both MCP and CLI |
| `lib/lunchmoney_app/configuration.rb` | App configuration (env vars, logger setup) |
| `lib/lunchmoney_app/logger.rb` | Logger with configurable level and output |
| `lib/lunchmoney_app/resolver.rb` | Resolves foreign key IDs to full objects for `--resolve` flag |
| `lib/lunchmoney_app/server.rb` | MCP server factory: builds `MCP::Server` with all tools via `mcp` gem |
| `lib/lunchmoney_app/tool.rb` | Base class with `.tool` DSL, `.register(server)`, and `.serialize` helper (wraps `mcp` gem) |
| `lib/lunchmoney_app/tools/*.rb` | MCP tool definitions (thin wrappers over `Api::*`) |
| `lib/lunchmoney_app/cache.rb` | Sequel SQLite cache for API responses |

**Tool DSL pattern** — every MCP tool class inherits `LunchMoneyApp::Tool` and delegates to the shared API:
```ruby
tool "tool_name",
     description: "...",
     input_schema: { properties: { field: { type: "string" } }, required: ["field"] } do |args|
  api_result = LunchMoneyApp::Api::SomeResource.some_method(args["field"])
  text_response(api_result)
end
```

**Serialization** — `LunchMoneyApp::Tool.serialize` converts SDK model objects to plain hashes with **string keys**. This is used by both MCP tool handlers (via `text_response`) and CLI output formatting.

**MCP server** — uses the official `mcp` gem (`modelcontextprotocol/ruby-sdk`). `LunchMoneyApp::Server.build` creates an `MCP::Server` with all tools. `LunchMoneyApp::Server.run` supports two transports: **stdio** (default, JSON-RPC over stdin/stdout) and **HTTP** (`--http` flag, StreamableHTTPTransport via Rack/WEBrick on `/mcp`). The `LunchMoneyApp::Tool` base class provides a `.tool` DSL that internally creates `MCP::Tool.define` instances.

**CLI output** — all CLI commands use `Cli::Output` for rendering. It handles serialization, optional `--resolve` expansion, JSON vs human-readable routing, and pagination via `tty-pager` (when stdout is a TTY). Human-readable output uses `terminal-table` for tabular data. All commands support `--json` for agent-friendly output. Transaction list defaults to last 30 days, sorted by date descending. Use `::Terminal::Table` (root scope) inside Thor subclasses to avoid collision with `Thor::Shell::Terminal`.

**API caching** — `Api::Base` provides `cached(id, *path, fetch: false)` for looking up cached records. The `path` args drill into the cached data (e.g. `cached(42, "name")`). With `fetch: true`, a cache miss triggers an API call to populate the cache. Used by CLI formatters to resolve foreign keys (category names, account names) inline.

**Testing** — MiniTest + Mocha. Tests exist at three levels:
- `test/api/*` — tests the shared backend with a mock client
- `test/tools/*` — tests MCP tool handlers via `MCP::Server.handle` (JSON-RPC)
- `test/cli/*` — tests CLI commands with `Thor.start` and captured stdout

No HTTP is made in tests (WebMock blocks all real requests).

## API endpoint mapping

The client talks to the Lunch Money v2 REST API via the `lunchmoney-sdk-ruby` gem. Key non-obvious mappings:
- Manual accounts → `/assets` (not `/manual_accounts`)
- Recurring items → `/recurring_expenses`
- Budget summary → `/budgets`
- Bulk delete transactions → `DELETE /transactions` with JSON body `{ ids: [...] }`

## SDK dependency

The `lunchmoney-sdk-ruby` gem (GitHub: `ajaya/lunchmoney-sdk-ruby`) provides auto-generated API client classes under the `LunchMoney::` namespace. This project's `LunchMoneyApp::Api::*` classes wrap them. The Gemfile points to GitHub: `gem "lunchmoney-sdk-ruby", github: "ajaya/lunchmoney-sdk-ruby"`. For local SDK development, temporarily switch to `path: "../lunchmoney-sdk-ruby"`.
