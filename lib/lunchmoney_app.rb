# frozen_string_literal: true

# This file is the root namespace. Zeitwerk is set up by entry points
# (bin/lunchmoney and test/test_helper.rb), not here.

module LunchMoneyApp
  VERSION = "2.9.0"

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
      configuration
    end

    def logger
      configuration.logger
    end

    def log_level
      configuration.logger.resolved_level
    end
  end
end
