# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class User < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "me", "Show the current authenticated user"
      def me
        ensure_setup!
        result = Api::User.get_me
        out.render(result) do |data|
          rows = []
          rows << ["Name", data["name"] || "Unknown"]
          rows << ["Email", data["email"]] if data["email"]
          rows << ["Budget", data["budget_name"]] if data["budget_name"] && !data["budget_name"].empty?
          rows << ["Currency", data["primary_currency"]&.upcase] if data["primary_currency"]
          rows << ["API Key", data["api_key_label"]] if data["api_key_label"]
          ::Terminal::Table.new(rows: rows).to_s
        end
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end
    end
  end
end
