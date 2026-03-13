# frozen_string_literal: true

require "terminal-table"
require "tty-pager"

module LunchMoneyApp
  module Cli
    class Output
      def initialize(json: false, resolve: false)
        @json = json
        @resolve = resolve
      end

      def render(data, human_message = nil, &block)
        data = LunchMoneyApp::Tool.serialize(data)
        data = LunchMoneyApp::Resolver.resolve(data) if @resolve

        text = if @json
                 JSON.pretty_generate(data)
               elsif human_message
                 human_message
               elsif block
                 yield data
               else
                 JSON.pretty_generate(data)
               end

        paginate(text) if text
      end

      private

      def paginate(text)
        if $stdout.tty?
          pager = TTY::Pager.new
          pager.page(text)
        else
          puts text
        end
      end
    end
  end
end
