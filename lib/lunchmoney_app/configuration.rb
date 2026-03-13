# frozen_string_literal: true

module LunchMoneyApp
  class Configuration
    attr_accessor :api_token, :cache_db_path

    def initialize
      @api_token     = ENV["LUNCHMONEY_API_TOKEN"]
      @cache_db_path = ENV.fetch("LUNCHMONEY_CACHE_DB_PATH") {
        File.join(Dir.home, ".config", "lunchmoney", "cache.sqlite3")
      }
      @logger = Logger.new(
        level:  ENV["LUNCHMONEY_LOG_LEVEL"],
        output: ENV["LUNCHMONEY_LOG_OUTPUT"]
      )
    end

    def logger
      @logger
    end

    def log_level=(value)
      @logger.level = value
    end

    def log_output=(value)
      @logger.output = value
    end

    def debugging?
      @logger.debugging?
    end

    def token_present?
      api_token && !api_token.empty? && api_token != "your_token_here"
    end
  end
end
