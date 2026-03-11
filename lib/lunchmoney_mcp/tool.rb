# frozen_string_literal: true

module LunchMoneyMcp
  # Base class for tool modules. Subclasses use the .tool DSL to declare MCP tools,
  # then call .register(server) to register them all.
  #
  # Example:
  #   class MyTools < LunchMoneyMcp::Tool
  #     tool "my_tool", description: "Does something" do |args, client|
  #       result = client.get("/something")
  #       text_response(result)
  #     end
  #   end
  class Tool
    class << self
      def inherited(subclass)
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

      def register(server)
        tools.each { |t| server.register_tool(t) }
      end

      private

      def normalize_schema(schema)
        {
          type: "object",
          properties: schema[:properties] || {},
          required: schema[:required] || []
        }
      end
    end

    # Convenience helper available inside handler blocks via the class.
    def self.text_response(data)
      { content: [{ type: "text", text: JSON.pretty_generate(data) }] }
    end
  end
end
