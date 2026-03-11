# frozen_string_literal: true

module LunchMoneyMcp
  class Client
    DEFAULT_BASE_URL = "https://dev.lunchmoney.app/v2"

    def initialize(api_token, base_url: ENV.fetch("LUNCHMONEY_API_BASE_URL", DEFAULT_BASE_URL))
      @api_token = api_token
      @base_url  = base_url.chomp("/")
    end

    def get(path, params = {})
      request(:get, path, params: compact(params))
    end

    def post(path, body = {})
      request(:post, path, body: body)
    end

    def put(path, body = {})
      request(:put, path, body: body)
    end

    def delete(path, body = {})
      request(:delete, path, body: compact(body))
    end

    private

    def compact(hash)
      hash.reject { |_, v| v.nil? }
    end

    def request(method, path, params: {}, body: nil)
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      req = build_request(method, uri)
      req["Authorization"] = "Bearer #{@api_token}"
      req["Content-Type"]  = "application/json"
      req["Accept"]        = "application/json"
      req.body = body.to_json if body && !body.empty?

      response = http.request(req)
      handle_response(response)
    end

    def build_request(method, uri)
      klass = { get: Net::HTTP::Get, post: Net::HTTP::Post,
                put: Net::HTTP::Put, delete: Net::HTTP::Delete }[method]
      raise ArgumentError, "Unknown HTTP method: #{method}" unless klass

      klass.new(uri)
    end

    def handle_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise "LunchMoney API error #{response.code}: #{response.body}"
      end

      return nil if response.body.nil? || response.body.strip.empty?

      JSON.parse(response.body)
    end
  end
end
