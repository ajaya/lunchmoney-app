FROM ruby:3.4.8-slim

WORKDIR /app

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock* lunchmoney-ruby.gemspec ./
COPY lib/lunchmoney_app.rb lib/lunchmoney_app.rb
RUN bundle config set --local without 'development test' && bundle install

# Copy application code
COPY bin/ bin/
COPY lib/ lib/
COPY .env .env

RUN chmod +x bin/lunchmoney

# MCP servers communicate via stdio — no port needed
CMD ["ruby", "bin/lunchmoney", "server"]
