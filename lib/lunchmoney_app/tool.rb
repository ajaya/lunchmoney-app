# frozen_string_literal: true

require "mcp"

module LunchMoneyApp
  # Base class for tool modules. Subclasses use the .tool DSL to declare MCP tools,
  # then call .register(server) to register them on an MCP::Server.
  #
  # Example:
  #   class MyTools < LunchMoneyApp::Tool
  #     tool "my_tool", description: "Does something" do |args|
  #       text_response(LunchMoneyApp::Api::SomeResource.some_method(args))
  #     end
  #   end
  class Tool
    class << self
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@tools, [])
      end

      def tools
        @tools ||= []
      end

      def tool(name, description:, input_schema: {}, &handler)
        tools << {
          name:,
          description:,
          input_schema: normalize_schema(input_schema),
          handler:
        }
      end

      # Returns an array of MCP::Tool classes for server initialization
      def mcp_tools
        tools.map { |t| build_mcp_tool(t) }
      end

      # Register tools on an MCP::Server instance
      def register(server)
        tools.each do |t|
          mcp_tool = build_mcp_tool(t)
          server.tools[mcp_tool.name_value] = mcp_tool
        end
      end

      private

      def normalize_schema(schema)
        result = {
          type: "object",
          properties: schema[:properties] || {}
        }
        required = schema[:required]
        result[:required] = required if required && !required.empty?
        result
      end

      def build_mcp_tool(t)
        handler = t[:handler]
        MCP::Tool.define(
          name: t[:name],
          description: t[:description],
          input_schema: t[:input_schema]
        ) do |**kwargs|
          arguments = kwargs.reject { |k, _| k == :server_context }
          arguments = arguments.transform_keys(&:to_s)
          result = handler.call(arguments)
          if result.is_a?(Hash) && result[:content]
            MCP::Tool::Response.new(result[:content])
          else
            MCP::Tool::Response.new([{ type: "text", text: result.to_s }])
          end
        end
      end
    end

    # Convenience helper: wraps data as an MCP text response.
    def self.text_response(data)
      { content: [{ type: "text", text: JSON.pretty_generate(serialize(data)) }] }
    end

    # Converts SDK model objects (or arrays/hashes of them) to plain hashes.
    def self.serialize(obj)
      case obj
      when Array
        obj.map { |item| serialize(item) }
      when Hash
        obj.each_with_object({}) { |(k, v), h| h[k.to_s] = serialize(v) }
      else
        obj.respond_to?(:to_hash) ? serialize(obj.to_hash) : obj
      end
    end
  end
end
