# frozen_string_literal: true

require "thor"

module LunchMoneyApp
  module Cli
    class Server < Base
      default_command :start

      desc "start", "Start the MCP server (JSON-RPC over stdio)"
      def start
        LunchMoneyApp::Cli::Main.setup_from_config!(
          log_level: parent_options&.[](:log_level) || options[:log_level]
        )
        LunchMoneyApp::Server.run
      end

      desc "config", "Print MCP configuration snippets for Claude"
      option :claude, type: :boolean, default: false, desc: "Show Claude Desktop / Claude Code config"
      def config
        if options[:claude]
          print_claude_config
        else
          invoke :help, ["config"]
        end
      end

      private

      def print_claude_config
        project_root = LunchMoneyApp::Cli::Main.send(:project_root)

        puts "Add one of the following JSON snippets to configure Claude with this MCP server."
        puts

        print_section("Claude Code", "Add to .mcp.json in your project root, or ~/.claude/settings.json for global access:") do
          native_mcp_config(project_root)
        end

        print_section("Claude Desktop", "Add to claude_desktop_config.json:") do
          native_mcp_config(project_root)
        end

        print_section("Docker", "Add to claude_desktop_config.json or .mcp.json:") do
          docker_config(project_root)
        end
      end

      def print_section(title, description)
        if $stdout.tty?
          puts "\e[1m\e[33m#{title}\e[0m"
          puts "\e[2m#{description}\e[0m"
        else
          puts title
          puts description
        end
        puts
        puts JSON.pretty_generate(yield)
        puts
      end

      def native_mcp_config(project_root)
        cmd, args = detect_ruby_command
        bin_path = File.join(project_root, "bin", "lunchmoney")
        {
          mcpServers: {
            lunchmoney: {
              command: cmd,
              args: [*args, bin_path, "server"],
              env: {
                LUNCHMONEY_API_TOKEN: token_placeholder
              }
            }
          }
        }
      end

      def docker_config(project_root)
        {
          mcpServers: {
            lunchmoney: {
              command: "docker",
              args: ["compose", "-f", "#{project_root}/docker-compose.yml", "run", "--rm", "mcp"],
              env: {
                LUNCHMONEY_API_TOKEN: token_placeholder
              }
            }
          }
        }
      end

      # Detect the best way to invoke Ruby for MCP configs.
      # Claude Desktop has a limited PATH, so we must use full paths
      # and avoid shebangs that resolve via /usr/bin/env.
      # Detect the best way to invoke Ruby for MCP configs.
      # bin/lunchmoney sets BUNDLE_GEMFILE itself, so no bundle exec needed.
      def detect_ruby_command
        rv_path = `which rv 2>/dev/null`.strip
        unless rv_path.empty?
          return [rv_path, ["run", "--ruby", RUBY_VERSION, "ruby"]]
        end

        [RbConfig.ruby, []]
      end

      def token_placeholder
        config = LunchMoneyApp.configuration
        if config.token_present?
          config.api_token
        else
          "your_token_here"
        end
      end
    end
  end
end
