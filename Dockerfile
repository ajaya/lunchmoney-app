FROM ruby:4.0.1-slim

WORKDIR /app

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle install --without development test

# Copy application code
COPY bin/ bin/
COPY lib/ lib/
COPY .env .env

RUN chmod +x bin/server

# MCP servers communicate via stdio — no port needed
CMD ["ruby", "bin/server"]
