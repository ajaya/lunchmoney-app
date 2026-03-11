# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle install          # Install dependencies
bundle exec rake test   # Run all tests
bundle exec ruby bin/server  # Run the MCP server (requires LUNCHMONEY_API_TOKEN)

# Run a single test file
bundle exec ruby -Ilib -Itest test/tools/transactions_test.rb

# Docker
docker compose up --build
```

## Environment

Copy `.env.local` from `.env` and set `LUNCHMONEY_API_TOKEN` (obtain from https://my.lunchmoney.app/developers). `.env.local` is gitignored and loaded last, overriding `.env` defaults. The only other configurable variable is `LUNCHMONEY_API_BASE_URL` (defaults to `https://dev.lunchmoney.app/v2`).

## Architecture

This is a **Model Context Protocol (MCP) server** for the Lunch Money personal finance API, exposing 40 tools across 8 resource categories. It communicates via stdio using JSON-RPC 2.0.

**Data flow:** AI assistant → JSON-RPC over stdio → `bin/server` → `LunchMoneyMcp::Server` → tool handlers → `LunchMoneyMcp::Client` → Lunch Money API

**Zeitwerk note:** The module is `LunchMoneyMcp` but the root file is `lunchmoney_mcp.rb`. Zeitwerk cannot infer this capitalization, so both `bin/server` and `test/test_helper.rb` register a custom inflection: `loader.inflector.inflect("lunchmoney_mcp" => "LunchMoneyMcp")`.

**Key files:**

| File | Role |
|------|------|
| `bin/server` | Entry point: loads env, wires client + server + tool classes, calls `server.run` |
| `lib/lunchmoney_mcp.rb` | Zeitwerk loader setup; defines the `LunchMoneyMcp` module |
| `lib/lunchmoney_mcp/server.rb` | JSON-RPC dispatcher: handles `initialize`, `tools/list`, `tools/call` |
| `lib/lunchmoney_mcp/client.rb` | HTTP wrapper over `Net::HTTP`; methods: `get`, `post`, `put`, `delete` |
| `lib/lunchmoney_mcp/tool.rb` | Base class with `.tool` DSL and `.register(server)` |
| `lib/lunchmoney_mcp/tools/*.rb` | One class per resource (User, Categories, Transactions, ManualAccounts, PlaidAccounts, Tags, RecurringItems, Summary) |

**Tool DSL pattern** — every tool class inherits `LunchMoneyMcp::Tool` and declares tools with:
```ruby
tool "tool_name",
     description: "...",
     input_schema: { properties: { field: { type: "string", description: "..." } }, required: ["field"] } do |args, client|
  result = client.get("/endpoint")
  text_response(result)   # returns { content: [{ type: "text", text: result.to_json }] }
end
```

**Testing** — MiniTest + Mocha. Each test file creates a mock client, registers one tool class onto a fresh server, and calls `server.call_tool(name, args)` directly. No HTTP is made (WebMock blocks all real requests).

## API endpoint mapping

The client talks to the Lunch Money v2 REST API. Key non-obvious mappings:
- Manual accounts → `/assets` (not `/manual_accounts`)
- Recurring items → `/recurring_expenses`
- Budget summary → `/budgets`
- Bulk delete transactions → `DELETE /transactions` with JSON body `{ ids: [...] }`
