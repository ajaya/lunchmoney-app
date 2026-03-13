# frozen_string_literal: true

require "logger"
require "fileutils"

module LunchMoneyApp
  # Configurable logger that supports stderr, stdout, or file output.
  # Log level defaults to off (FATAL) unless explicitly set.
  class Logger
    LEVELS = %w[debug info warn error fatal].freeze

    attr_reader :level, :output

    def initialize(level: nil, output: nil)
      @level  = level
      @output = output
      @logger = build
    end

    def level=(value)
      @level = value
      rebuild!
    end

    def output=(value)
      @output = value
      rebuild!
    end

    def debugging?
      resolved_level <= ::Logger::DEBUG
    end

    def resolved_level
      return ::Logger::FATAL unless @level

      idx = LEVELS.index(@level.downcase)
      idx || ::Logger::FATAL
    end

    # Delegate standard logger methods
    %i[debug info warn error fatal unknown].each do |m|
      define_method(m) { |*args, &block| @logger.send(m, *args, &block) }
    end

    private

    def rebuild!
      @logger = build
    end

    def build
      io = resolve_output
      l = ::Logger.new(io)
      l.level = resolved_level
      l.formatter = proc { |sev, time, _, msg| "#{time.strftime("%Y-%m-%d %H:%M:%S")} [#{sev}] #{msg}\n" }
      l
    end

    def resolve_output
      case @output&.downcase
      when nil, "", "stderr" then $stderr
      when "stdout"          then $stdout
      else
        FileUtils.mkdir_p(File.dirname(@output))
        File.open(@output, "a")
      end
    end
  end
end
