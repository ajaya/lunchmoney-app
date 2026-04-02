# frozen_string_literal: true

require "mcp"

module LunchMoneyApp
  # Factory that builds an MCP::Server with all Lunch Money tools registered.
  module Server
    DEFAULT_HTTP_PORT = 9292

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

    def self.run(http: false, port: DEFAULT_HTTP_PORT)
      server = build
      print_banner(server, http:, port:)

      if http
        start_http(server, port)
      else
        start_stdio(server)
      end
    end

    def self.start_stdio(server)
      transport = MCP::Server::Transports::StdioTransport.new(server)
      transport.open
    end

    def self.start_http(server, port)
      require "rack"
      require "webrick"

      transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
      server.transport = transport

      app = ->(env) { transport.handle_request(Rack::Request.new(env)) }

      require "rackup/handler/webrick"
      Rackup::Handler::WEBrick.run(
        Rack::Builder.new { map("/mcp") { run app } },
        Host: "127.0.0.1",
        Port: port,
        Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
        AccessLog: []
      )
    end

    private_class_method :start_stdio, :start_http

    def self.color?
      $stderr.tty?
    end

    def self.c(code)
      color? ? code : ""
    end

    def self.print_banner(server, http: false, port: DEFAULT_HTTP_PORT)
      bold = c("\e[1m")
      dim = c("\e[2m")
      reset = c("\e[0m")
      green = c("\e[32m")
      cyan = c("\e[36m")
      yellow = c("\e[33m")

      total = server.tools.size
      transport_label = http ? "http (port #{port})" : "stdio"

      warn "#{green}#{bold}lunchmoney#{reset} MCP server #{dim}v#{LunchMoneyApp::VERSION}#{reset}"
      warn ""
      print_config
      warn ""
      warn "#{dim}Transport:#{reset} #{transport_label}"
      warn "#{dim}Tools:#{reset}     #{total}"

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
        warn prefix + rows.shift
        rows.each { |row| warn indent + row }
      end

      warn ""
      if http
        warn "#{green}Ready#{reset} #{dim}— listening on http://127.0.0.1:#{port}/mcp#{reset}"
      else
        warn "#{green}Ready#{reset} #{dim}— waiting for JSON-RPC requests on stdin...#{reset}"
      end
    end

    def self.print_config
      dim = c("\e[2m")
      reset = c("\e[0m")
      green = c("\e[32m")
      red = c("\e[31m")

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

      warn "#{dim}Token:#{reset}      #{token_display}"
      warn "#{dim}Cache:#{reset}      #{cache_path}"
      warn "#{dim}Log level:#{reset}  #{log_level}"
      warn "#{dim}Log output:#{reset} #{log_output}"
      warn ""
      warn "#{dim}Ruby:#{reset}       #{RbConfig.ruby}"
      warn "#{dim}Version:#{reset}    #{RUBY_VERSION}"
      warn "#{dim}Gem path:#{reset}   #{Gem.dir}"
      warn "#{dim}Bundle:#{reset}     #{ENV.fetch("BUNDLE_GEMFILE", "#{Bundler.root}/Gemfile")}"
    end
  end
end
