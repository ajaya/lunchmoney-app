# frozen_string_literal: true

require "thor"

module LunchMoneyApp
  module Cli
    class Base < Thor
      def self.exit_on_failure? = true

      private

      def ensure_setup!
        log_level = (parent_options && parent_options[:log_level]) || options[:log_level]
        LunchMoneyApp::Cli::Main.setup_from_config!(log_level: log_level)
      end
    end
  end
end
