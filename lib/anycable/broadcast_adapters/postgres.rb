# frozen_string_literal: true

begin
  require "pg"
rescue LoadError
  raise "Please, install the pg gem to use Postgres broadcast adapter"
end

require "json"

module AnyCable
  module BroadcastAdapters
    # Postgres adapter for broadcasting.
    #
    # It writes the full AnyCable broadcast JSON envelope through the SQL
    # functions owned by anycable-go. The payload is stored as opaque text in
    # Postgres; routing metadata is handled by the server-owned schema.
    class Postgres < Base
      PUBLISH_FUNCTION = "anycable_publish"
      REMOTE_COMMAND_FUNCTION = "anycable_remote_command"

      attr_reader :pg_conn

      def initialize(**options)
        options = AnyCable.config.to_postgres_params.merge(options)

        @pg_conn = options.delete(:connection) || ::PG.connect(options.fetch(:url))
      end

      def raw_broadcast(payload)
        message = JSON.parse(payload)

        if message.is_a?(Array)
          message.each { |item| publish_message(item, JSON.generate(item)) }
        else
          publish_message(message, payload)
        end
      end

      def announce!
        logger.info "Broadcasting Postgres functions: #{PUBLISH_FUNCTION}, #{REMOTE_COMMAND_FUNCTION}"
      end

      private

      def publish_message(message, payload)
        unless message.is_a?(Hash)
          raise ArgumentError, "Postgres broadcast payload must be a JSON object or array of objects"
        end

        if message.key?("stream")
          pg_conn.exec_params(
            "SELECT #{PUBLISH_FUNCTION}($1, $2, $3)",
            [message.fetch("stream"), payload, JSON.generate(message.fetch("meta", {}))]
          )
        elsif message.key?("command")
          pg_conn.exec_params(
            "SELECT #{REMOTE_COMMAND_FUNCTION}($1, $2)",
            [payload, JSON.generate(message.fetch("meta", {}))]
          )
        else
          raise ArgumentError, "Postgres broadcast payload must include stream or command"
        end
      end
    end
  end
end
