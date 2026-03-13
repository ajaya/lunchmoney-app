# frozen_string_literal: true

require "mcp"

module LunchMoneyApp
  # Factory that builds an MCP::Server with all Lunch Money tools registered.
  module Server
    TOOL_CLASSES = [
      -> { Tools::User },
      -> { Tools::Categories },
      -> { Tools::Transactions },
      -> { Tools::ManualAccounts },
      -> { Tools::PlaidAccounts },
      -> { Tools::Tags },
      -> { Tools::RecurringItems },
      -> { Tools::Summary }
    ].freeze

    def self.build
      all_tools = TOOL_CLASSES.flat_map { |tc| tc.call.mcp_tools }
      MCP::Server.new(
        name: "lunchmoney",
        version: LunchMoneyApp::VERSION,
        tools: all_tools
      )
    end

    def self.run
      server = build
      print_banner(server)
      transport = MCP::Server::Transports::StdioTransport.new(server)
      transport.open
    end

    def self.color?
      $stderr.tty?
    end

    def self.c(code)
      color? ? code : ""
    end

    def self.print_banner(server)
      bold  = c("\e[1m"); dim = c("\e[2m"); reset = c("\e[0m")
      green = c("\e[32m"); cyan = c("\e[36m"); yellow = c("\e[33m")

      total = server.tools.size
      $stderr.puts "#{green}#{bold}lunchmoney#{reset} MCP server #{dim}v#{LunchMoneyApp::VERSION}#{reset}"
      $stderr.puts
      print_config
      $stderr.puts
      $stderr.puts "#{dim}Transport:#{reset} stdio"
      $stderr.puts "#{dim}Tools:#{reset}     #{total}"

      groups = TOOL_CLASSES.map do |tc|
        klass = tc.call
        label = klass.name.split("::").last
        names = klass.tools.map { |t| t[:name] }
        [label, names]
      end

      all_names = groups.flat_map { |_, names| names }
      col_width = all_names.map(&:size).max + 3
      label_width = groups.map { |label, _| label.size }.max
      indent = " " * (label_width + 4)

      groups.each do |label, names|
        padded = label.ljust(label_width)
        prefix = "  #{yellow}#{bold}#{padded}#{reset}  "
        visible_prefix = label_width + 4
        cols = [(78 - visible_prefix) / col_width, 1].max
        rows = names.each_slice(cols).map do |row|
          row.map { |n| "#{cyan}#{n}#{reset}#{" " * (col_width - n.size)}" }.join.rstrip
        end
        $stderr.puts prefix + rows.shift
        rows.each { |row| $stderr.puts indent + row }
      end

      $stderr.puts
      $stderr.puts "#{green}Ready#{reset} #{dim}— waiting for JSON-RPC requests on stdin...#{reset}"
    end

    def self.print_config
      bold = c("\e[1m"); dim = c("\e[2m"); reset = c("\e[0m")
      green = c("\e[32m"); red = c("\e[31m")

      config = LunchMoneyApp.configuration

      token_display = if config.token_present?
        masked = config.api_token[-4..]
        "#{green}***#{masked}#{reset}"
      else
        "#{red}not set#{reset}"
      end

      log_level = config.logger.level || "off"
      log_output = config.logger.output || "stderr"
      cache_path = config.cache_db_path.sub(Dir.home, "~")

      $stderr.puts "#{dim}Token:#{reset}      #{token_display}"
      $stderr.puts "#{dim}Cache:#{reset}      #{cache_path}"
      $stderr.puts "#{dim}Log level:#{reset}  #{log_level}"
      $stderr.puts "#{dim}Log output:#{reset} #{log_output}"
      $stderr.puts
      $stderr.puts "#{dim}Ruby:#{reset}       #{RbConfig.ruby}"
      $stderr.puts "#{dim}Version:#{reset}    #{RUBY_VERSION}"
      $stderr.puts "#{dim}Gem path:#{reset}   #{Gem.dir}"
      $stderr.puts "#{dim}Bundle:#{reset}     #{ENV.fetch("BUNDLE_GEMFILE", "#{Bundler.root}/Gemfile")}"
    end
  end
end
