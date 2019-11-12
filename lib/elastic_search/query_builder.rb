# frozen_string_literal: true
require 'elastic_search/query_builder/version'
require_relative '../core_extensions/core_extensions.rb'

module ElasticSearch
  class QueryBuilder
    attr_accessor :function_score

    METHODS = {
      must: %i[query bool must],
      must_not: %i[query bool must_not],
      should: %i[query bool should],
      functions: %i[functions],
      ids: %i[query terms _id],
      size: [:size],
      fields: %i[_source],
      range: %i[query bool must range],
      sort: %i[sort],
      aggs: [:aggs]
    }.freeze
    METHODS.each do |method, path|
      define_method(method) do |body|
        return self if body.not_present?

        internal_path = path
        internal_path = %i[query function_score] + path if @function_score &&
                                                           %i[functions query].any?(path.first)

        init_path(internal_path)
        exclude_opposite(internal_path, body)
        add_clause(internal_path, body)
        self
      end
    end

    def initialize(opts: {}, client: nil, function_score: false)
      @opts = opts
      @function_score = function_score
      @client = client
    end

    def to_json(*_args)
      @opts.to_h
    end

    def results
      raise 'client: should be set in order to fetch results' unless client

      client&.search(opts)&.results
    end

    private

    attr_accessor :opts, :client

    def init_path(path)
      return if path.size == 1 || initialized?(path)

      path_minus_one = path.first(path.size - 1)
      @opts = opts.merge((path_minus_one + [{}]).reverse.reduce { |a, b| { b => a } })
    end

    def initialized?(path)
      opts.dig(*path.first(path.size - 1)).present?
    end

    def root_path?(path)
      path.size == 1
    end

    def exclusive_path?(path)
      %i[must must_not].any? { |item| path.last == item }
    end

    def exclude_opposite(path, body)
      return if root_path?(path) || !exclusive_path?(path)

      context = path.last
      opposite = context == :must ? :must_not : :must
      path_minus_one = path.first(path.size - 1)
      opposite_array = opts.dig(*(path_minus_one + [opposite]))
      opts.dig(*path_minus_one).store(opposite, opposite_array.reject { |item| item == body.first }) if opposite_array
    end

    def added?(path, body)
      return if root_path?(path) || !exclusive_path?(path)

      clause = opts.dig(*path)
      clause.any? { |item| item == body.first } if clause.is_a?(Array)
    end

    def add_clause(path, body)
      return if added?(path, body)

      if !root_path?(path) && body.is_a?(Array)
        existing_content = opts.dig(*path) || []
        opts.dig(*path.first(path.size - 1)).store(path.last, body + existing_content)
      elsif root_path?(path)
        opts[path.first] = body
      else
        path_minus_one = path.first(path.size - 1)
        opts.dig(*path_minus_one).store(path.last, body)
      end
    end
  end
end
