# lunchmoney-ruby

MCP server and CLI for the [Lunch Money](https://lunchmoney.app) personal finance API.

- **CLI** — human-friendly Thor commands for managing transactions, categories, accounts, and more
- **MCP server** — expose the same operations as [Model Context Protocol](https://modelcontextprotocol.io) tools for use with AI assistants

Both interfaces share a common backend, so every operation is available in both modes.

## Requirements

- Ruby >= 3.4
- A [Lunch Money API token](https://my.lunchmoney.app/developers)

## Installation

```bash
git clone https://github.com/ajaya/lunchmoney-ruby.git
cd lunchmoney-ruby
```

### Installing Ruby

Install Ruby 3.4.8 with [rv](https://github.com/jdx/rv):

```bash
brew install rv
rv install 3.4.8
ruby -v                  # verify
bundle install
```

## Configuration

```bash
cp .env .env.local
# Edit .env.local and set LUNCHMONEY_API_TOKEN
```

Or authenticate via the CLI:

```bash
bundle exec ruby bin/lunchmoney login <TOKEN>
```

### Environment variables

| Variable                    | Default                                | Description                              |
| --------------------------- | -------------------------------------- | ---------------------------------------- |
| `LUNCHMONEY_API_TOKEN`      | —                                      | API access token (required)              |
| `LUNCHMONEY_CACHE_DB_PATH`  | `~/.config/lunchmoney/cache.sqlite3`   | SQLite cache location                    |
| `LUNCHMONEY_LOG_LEVEL`      | off                                    | `debug`, `info`, `warn`, `error`, `fatal` |
| `LUNCHMONEY_LOG_OUTPUT`     | `stderr`                               | `stderr`, `stdout`, or an absolute file path |

## CLI usage

Set up an alias for convenience:

```bash
alias lunchmoney='rv run --ruby 3.4.8 ruby /path/to/lunchmoney-ruby/bin/lunchmoney'
```

```bash
# Help
lunchmoney help                        # list all commands
lunchmoney tree                        # show full command tree
lunchmoney transactions help list      # show all parameters for a subcommand

# Examples
lunchmoney transactions list           # last 30 days of transactions
lunchmoney transactions show 123       # single transaction
lunchmoney categories list
lunchmoney plaid_accounts list
lunchmoney user me

# JSON output (useful for scripting / AI agents)
lunchmoney transactions list --json

# Resolve foreign key IDs to full objects (requires --json)
lunchmoney transactions list --json --resolve
```

Without `--resolve`, transactions contain bare IDs like `"category_id": 42`. With `--resolve`, these are expanded to full objects (`"category": { "id": 42, "name": "Groceries", ... }`).

### Commands

| Command | Description |
| --- | --- |
| `help [COMMAND]` | Describe available commands |
| `tree` | Print a tree of all available commands |
| `login TOKEN` | Save your Lunch Money API token |
| `logout` | Remove saved API token |
| **transactions** | |
| `transactions list` | List transactions |
| `transactions show ID` | Show a single transaction |
| `transactions create` | Create transactions from JSON (stdin or `--data`) |
| `transactions update ID` | Update a transaction |
| `transactions update_bulk` | Bulk update transactions from JSON (stdin or `--data`) |
| `transactions delete ID` | Delete a transaction |
| `transactions delete_bulk ID1 ID2 ...` | Delete multiple transactions |
| `transactions split ID` | Split a transaction (stdin or `--data`) |
| `transactions unsplit ID` | Unsplit a transaction |
| `transactions group` | Group transactions (stdin or `--data`) |
| `transactions ungroup ID` | Ungroup a transaction group |
| **categories** | |
| `categories list` | List categories |
| `categories show ID` | Show a single category |
| `categories create --name=NAME` | Create a category |
| `categories update ID` | Update a category |
| `categories delete ID` | Delete a category |
| **plaid_accounts** | |
| `plaid_accounts list` | List all Plaid-connected accounts |
| `plaid_accounts show ID` | Show a single Plaid account |
| `plaid_accounts fetch` | Trigger a Plaid data sync |
| **manual_accounts** | |
| `manual_accounts list` | List all manually-managed accounts |
| `manual_accounts show ID` | Show a single manual account |
| `manual_accounts create` | Create a new manual account |
| `manual_accounts update ID` | Update a manual account |
| `manual_accounts delete ID` | Delete a manual account |
| **recurring_items** | |
| `recurring_items list` | List all recurring items |
| `recurring_items show ID` | Show a single recurring item |
| **tags** | |
| `tags list` | List all tags |
| `tags show ID` | Show a single tag |
| `tags create --name=NAME` | Create a new tag |
| `tags update ID` | Update a tag |
| `tags delete ID` | Delete a tag |
| **summary** | |
| `summary budget` | Get budget summary for a date range |
| **user** | |
| `user me` | Show the current authenticated user |
| **server** | |
| `server start` | Start the MCP server (JSON-RPC over stdio) |
| `server config` | Print MCP configuration snippets for Claude |

## MCP server

Start the server over stdio:

```bash
bundle exec ruby bin/lunchmoney server

# Or with rv:
rv run --ruby 3.4.8 ruby bin/lunchmoney server
```

### Claude Code / Claude Desktop

Generate a ready-to-paste config snippet with resolved paths and your current token:

```bash
bundle exec ruby bin/lunchmoney server config --claude

# Or with rv:
rv run --ruby 3.4.8 ruby bin/lunchmoney server config --claude
```

This outputs JSON blocks for Claude Code, Claude Desktop, and Docker. Copy the relevant snippet into:

- **Claude Code** — `.mcp.json` in your project root, or `~/.claude/settings.json` for global access
- **Claude Desktop** — `claude_desktop_config.json`

If you prefer to configure manually, here is a minimal example:

```json
{
  "mcpServers": {
    "lunchmoney": {
      "command": "/opt/homebrew/bin/rv",
      "args": [
        "run",
        "--ruby",
        "3.4.8",
        "ruby",
        "/path/to/lunchmoney-ruby/bin/lunchmoney",
        "server"
      ],
      "cwd": "/path/to/lunchmoney-ruby",
      "env": {
        "LUNCHMONEY_API_TOKEN": "your_token_here"
      }
    }
  }
}
```

Adjust `command` and `args` for your Ruby version manager. The `server config --claude` command detects your local setup and generates the correct paths.

## Development

```bash
bundle exec rake test                # Run all tests
bundle exec ruby -Ilib -Itest test/tools/transactions_test.rb  # Single test file
```

## Architecture

```text
CLI (Thor)  ─┐
             ├──▶  Api::* (shared backend)  ──▶  lunchmoney-sdk-ruby  ──▶  Lunch Money API
MCP server  ─┘
```

The shared backend in `lib/lunchmoney_app/api/` contains all business logic. MCP tool handlers (`lib/lunchmoney_app/tools/`) and CLI commands (`lib/lunchmoney_app/cli/`) are thin wrappers that delegate to `Api::*` classes.

## License

MIT
