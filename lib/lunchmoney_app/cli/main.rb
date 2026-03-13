# frozen_string_literal: true

require "thor"

module LunchMoneyApp
  module Cli
    class Main < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"
      class_option :log_level, type: :string, default: nil, desc: "Log level (debug, info, warn, error, fatal)",
                               enum: LunchMoneyApp::Logger::LEVELS

      desc "login TOKEN", "Save your Lunch Money API token"
      long_desc <<~DESC
        Save your Lunch Money API token for future CLI use.
        Get your token from https://my.lunchmoney.app/developers

        The token is written to .env.local in the project root.
      DESC
      def login(token)
        LunchMoney.configure { |c| c.access_token = token }
        ensure_db!
        user = Api::User.get_me
        write_env_local(token)
        name  = user.to_hash[:name]
        email = user.to_hash[:email]
        out.render({ name: name, email: email },
               "Logged in as #{name} (#{email}). Token saved to .env.local")
      rescue => e
        abort "Login failed: #{e.message}"
      end

      desc "logout", "Remove saved API token"
      def logout
        if File.exist?(env_local_path) && File.read(env_local_path).match?(/^LUNCHMONEY_API_TOKEN=(?!your_token_here)/)
          contents = File.read(env_local_path)
          contents.sub!(/^LUNCHMONEY_API_TOKEN=.*$/, "LUNCHMONEY_API_TOKEN=your_token_here")
          File.write(env_local_path, contents)
          puts "Token removed from .env.local"
        else
          puts "No saved token found."
        end
      end

      desc "server SUBCOMMAND", "MCP server commands"
      subcommand "server", LunchMoneyApp::Cli::Server

      desc "transactions SUBCOMMAND", "Manage transactions"
      subcommand "transactions", LunchMoneyApp::Cli::Transactions

      desc "categories SUBCOMMAND", "Manage categories"
      subcommand "categories", LunchMoneyApp::Cli::Categories

      desc "plaid_accounts SUBCOMMAND", "Manage Plaid-connected accounts"
      subcommand "plaid_accounts", LunchMoneyApp::Cli::PlaidAccounts

      desc "manual_accounts SUBCOMMAND", "Manage manually-managed accounts"
      subcommand "manual_accounts", LunchMoneyApp::Cli::ManualAccounts

      desc "recurring_items SUBCOMMAND", "Manage recurring items"
      subcommand "recurring_items", LunchMoneyApp::Cli::RecurringItems

      desc "tags SUBCOMMAND", "Manage tags"
      subcommand "tags", LunchMoneyApp::Cli::Tags

      desc "summary SUBCOMMAND", "Budget summary"
      subcommand "summary", LunchMoneyApp::Cli::Summary

      desc "user SUBCOMMAND", "User information"
      subcommand "user", LunchMoneyApp::Cli::User

      private

      def out
        @out ||= Output.new(json: options[:json])
      end

      def ensure_db!
        self.class.ensure_db!
      end

      def setup_from_config!
        self.class.setup_from_config!(log_level: options[:log_level])
      end

      def env_local_path
        self.class.env_local_path
      end

      def write_env_local(token)
        path = env_local_path
        line = "LUNCHMONEY_API_TOKEN=#{token}"
        if File.exist?(path)
          contents = File.read(path)
          if contents.sub!(/^LUNCHMONEY_API_TOKEN=.*$/, line)
            File.write(path, contents)
          else
            File.write(path, contents.chomp + "\n#{line}\n")
          end
        else
          File.write(path, "#{line}\n")
        end
        File.chmod(0o600, path)
      end

      def self.env_local_path
        File.join(project_root, ".env.local")
      end

      def self.project_root
        File.expand_path("../../..", __dir__)
      end

      def self.resolve_token
        config = LunchMoneyApp.configuration
        return config.api_token if config.token_present?

        abort "Not logged in. Run: lunchmoney login <TOKEN>"
      end

      def self.setup_from_config!(log_level: nil)
        config = LunchMoneyApp.configuration
        config.log_level = log_level if log_level
        ensure_db!
        token = resolve_token
        LunchMoney.configure do |c|
          c.access_token = token
          c.logger = config.logger
          c.debugging = config.debugging?
        end
      end

      def self.ensure_db!
        @cache ||= LunchMoneyApp::Cache.new
      end
    end
  end
end
