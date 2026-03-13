# frozen_string_literal: true

require_relative "lib/lunchmoney_app"

Gem::Specification.new do |spec|
  spec.name          = "lunchmoney-ruby"
  spec.version       = LunchMoneyApp::VERSION
  spec.authors       = ["Ajaya Agrawalla"]
  spec.summary       = "MCP server and CLI for the Lunch Money API"
  spec.description   = "A Model Context Protocol server and Thor CLI for the Lunch Money personal finance API."
  spec.homepage      = "https://github.com/ajaya/lunchmoney-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.4"

  spec.metadata = {
    "homepage_uri"    => spec.homepage,
    "source_code_uri" => "https://github.com/ajaya/lunchmoney-ruby",
    "changelog_uri"   => "https://github.com/ajaya/lunchmoney-ruby/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/ajaya/lunchmoney-ruby/issues"
  }

  spec.files         = Dir["lib/**/*.rb", "bin/*", "LICENSE", "README.md", "CHANGELOG.md", "CLAUDE.md"]
  spec.bindir        = "bin"
  spec.executables   = ["lunchmoney"]

  spec.add_dependency "zeitwerk", "~> 2.7"
  spec.add_dependency "dotenv",   "~> 3.1"
  spec.add_dependency "thor",     "~> 1.3"
  spec.add_dependency "sequel",   "~> 5.87"
  spec.add_dependency "sqlite3",  "~> 2.6"
  spec.add_dependency "terminal-table", "~> 3.0"
  spec.add_dependency "tty-pager",      "~> 0.14"
  spec.add_dependency "mcp",    ">= 0.8.0"
  spec.add_dependency "lunchmoney-sdk-ruby"

  spec.add_development_dependency "minitest",           "~> 5.25"
  spec.add_development_dependency "minitest-reporters", "~> 1.7"
  spec.add_development_dependency "mocha",              "~> 2.7"
  spec.add_development_dependency "webmock",            "~> 3.24"
  spec.add_development_dependency "rake",               "~> 13.2"
  spec.add_development_dependency "pry"

end
