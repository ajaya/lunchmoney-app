# frozen_string_literal: true

require "zeitwerk"

module LunchMoneyApp
  VERSION = "2.9.0"

  class << self
    def loader
      @loader ||= begin
        loader = Zeitwerk::Loader.new
        loader.inflector.inflect("lunchmoney_app" => "LunchMoneyApp")
        loader.push_dir(File.expand_path("..", __FILE__))
        loader.setup
        loader
      end
    end

    def eager_load!
      loader.eager_load
    end

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

LunchMoneyApp.loader
