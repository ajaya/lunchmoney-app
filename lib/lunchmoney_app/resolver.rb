# frozen_string_literal: true

module LunchMoneyApp
  # Resolves foreign key IDs in serialized data to human-readable names.
  # Checks local SQLite cache first, falls back to API fetch.
  class Resolver
    RESOLVERS = {
      "category_id"       => { model: -> { Api::Categories },     embed_key: "category" },
      "group_id"          => { model: -> { Api::Categories },     embed_key: "group" },
      "plaid_account_id"  => { model: -> { Api::PlaidAccounts },  embed_key: "plaid_account" },
      "manual_account_id" => { model: -> { Api::ManualAccounts }, embed_key: "manual_account" }
    }.freeze

    ARRAY_RESOLVERS = {
      "tag_ids" => { model: -> { Api::Tags }, embed_key: "tags" }
    }.freeze

    def self.resolve(data)
      new.resolve(data)
    end

    def resolve(data)
      case data
      when Array
        prefetch_ids(data)
        data.map { |item| resolve_hash(item) }
      when Hash
        resolve_envelope(data)
      else
        data
      end
    end

    private

    def resolve_envelope(hash)
      result = hash.dup
      result.each do |k, v|
        if v.is_a?(Array) && v.all? { |i| i.is_a?(Hash) }
          prefetch_ids(v)
          result[k] = v.map { |item| resolve_hash(item) }
        elsif v.is_a?(Hash)
          result[k] = resolve_envelope(v)
        end
      end
      resolve_fields(result)
    end

    def resolve_hash(hash)
      return hash unless hash.is_a?(Hash)

      resolve_fields(hash.dup)
    end

    def resolve_fields(hash, depth: 0)
      RESOLVERS.each do |key, config|
        id = hash[key]
        next unless id

        record = lookup(config[:model].call, id)
        next unless record

        record = resolve_fields(record.dup, depth: depth + 1) if depth < 2
        hash[config[:embed_key]] = record
      end

      ARRAY_RESOLVERS.each do |key, config|
        ids = hash[key]
        next unless ids.is_a?(Array) && !ids.empty?

        model = config[:model].call
        hash[config[:embed_key]] = ids.filter_map { |id| lookup(model, id) }
      end

      hash
    end

    def prefetch_ids(items)
      return unless items.is_a?(Array) && items.all? { |i| i.is_a?(Hash) }

      all_configs = RESOLVERS.merge(ARRAY_RESOLVERS)
      models_to_prefetch = []

      all_configs.each do |key, config|
        model = config[:model].call
        ids = items.flat_map { |item| Array(item[key]) }.compact.uniq
        next if ids.empty?

        uncached = ids.reject { |id| model.cached(id) }
        models_to_prefetch << model if uncached.any?
      end

      models_to_prefetch.uniq.each do |model|
        LunchMoneyApp.logger.info { "Resolver prefetch #{model.name}" }
        model.list
      rescue StandardError => e
        LunchMoneyApp.logger.warn { "Resolver prefetch #{model.name} failed: #{e.message}" }
        nil
      end
    end

    def lookup(model, id)
      cached = model.cached(id)
      return cached if cached

      LunchMoneyApp.logger.info { "Resolver API fallback #{model.name} id=#{id}" }
      record = model.get(id)
      Tool.serialize(record)
    rescue StandardError => e
      LunchMoneyApp.logger.warn { "Resolver lookup #{model.name} id=#{id} failed: #{e.message}" }
      nil
    end
  end
end
