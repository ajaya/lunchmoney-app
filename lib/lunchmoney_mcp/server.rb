# frozen_string_literal: true

module LunchMoneyMcp
  class Server
    PROTOCOL_VERSION = "2024-11-05"
    SERVER_INFO      = { name: "lunchmoney-mcp", version: "1.0.0" }.freeze

    def initialize(client)
      @client = client
      @tools  = {}
    end

    def register_tool(tool_def)
      @tools[tool_def[:name]] = tool_def
    end

    def tool_registered?(name)
      @tools.key?(name)
    end

    def call_tool(name, arguments = {})
      tool = @tools[name] or raise KeyError, "Unknown tool: #{name}"
      tool[:handler].call(arguments, @client)
    end

    def run
      $stdout.sync = true
      $stderr.sync = true

      $stdin.each_line do |line|
        line = line.strip
        next if line.empty?

        begin
          request  = JSON.parse(line)
          response = handle_request(request)
          $stdout.puts(response.to_json) if response
        rescue JSON::ParserError => e
          $stderr.puts "JSON parse error: #{e.message}"
        rescue => e
          $stderr.puts "Unhandled error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
        end
      end
    end

    private

    def handle_request(request)
      id     = request["id"]
      method = request["method"]
      params = request["params"] || {}

      # Notifications have no id and expect no response.
      return nil if id.nil?

      case method
      when "initialize"        then handle_initialize(id)
      when "tools/list"        then handle_tools_list(id)
      when "tools/call"        then handle_tool_call(id, params)
      when "ping"              then success(id, {})
      else error(id, -32_601, "Method not found: #{method}")
      end
    end

    def handle_initialize(id)
      success(id, {
        protocolVersion: PROTOCOL_VERSION,
        capabilities:    { tools: {} },
        serverInfo:      SERVER_INFO
      })
    end

    def handle_tools_list(id)
      tool_list = @tools.values.map do |t|
        { name: t[:name], description: t[:description], inputSchema: t[:input_schema] }
      end
      success(id, { tools: tool_list })
    end

    def handle_tool_call(id, params)
      name      = params["name"]
      arguments = params["arguments"] || {}

      tool = @tools[name]
      unless tool
        return success(id, {
          content: [{ type: "text", text: "Unknown tool: #{name}" }],
          isError: true
        })
      end

      result = tool[:handler].call(arguments, @client)
      success(id, result)
    rescue => e
      $stderr.puts "Tool '#{name}' error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
      success(id, { content: [{ type: "text", text: "Error: #{e.message}" }], isError: true })
    end

    def success(id, result)
      { jsonrpc: "2.0", id:, result: }
    end

    def error(id, code, message)
      { jsonrpc: "2.0", id:, error: { code:, message: } }
    end
  end
end
