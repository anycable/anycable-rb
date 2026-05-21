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
    # It writes the full AnyCable broadcast JSON envelope into the shared
    # signalling table. The database trigger emits a tiny NOTIFY wake-up, while
    # anycable-go reads the actual payload back from Postgres.
    class Postgres < Base
      CONTRACT_NAME = "postgres_signalling"
      CONTRACT_VERSION = 1
      BROADCASTS_TRIGGER_NAME = "anycable_broadcasts_notify_insert"

      attr_reader :pg_conn, :table, :contract_table

      def initialize(**options)
        options = AnyCable.config.to_postgres_params.merge(options)

        @pg_conn = options.delete(:connection) || ::PG.connect(options.fetch(:url))
        @broadcasts_table_name = options.fetch(:broadcasts_table)
        @contract_table_name = options.fetch(:contract_table)
        @table = quote_table_name(@broadcasts_table_name)
        @contract_table = quote_table_name(@contract_table_name)

        validate_contract! if options.fetch(:validate_contract)
      end

      def raw_broadcast(payload)
        pg_conn.exec_params("INSERT INTO #{table} (payload) VALUES ($1)", [payload])
      end

      def announce!
        logger.info "Broadcasting Postgres table: #{table}"
      end

      private

      def validate_contract!
        result = pg_conn.exec_params("SELECT version FROM #{contract_table} WHERE name = $1", [CONTRACT_NAME])
        version = result.ntuples.positive? ? result.getvalue(0, 0).to_i : nil

        unless version == CONTRACT_VERSION
          raise "Postgres signalling contract version mismatch: expected #{CONTRACT_VERSION}, got #{version || "missing"}"
        end

        validate_columns!
        validate_trigger!
      end

      def validate_columns!
        result = pg_conn.exec_params(<<~SQL, [@broadcasts_table_name])
          SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull
          FROM pg_catalog.pg_attribute a
          WHERE a.attrelid = to_regclass($1)
            AND a.attnum > 0
            AND NOT a.attisdropped
        SQL

        columns = result.each_with_object({}) do |row, memo|
          memo[row["attname"]] = row
        end

        expected_columns.each do |name, type, required|
          column = columns[name]
          raise "Postgres signalling table #{table} is missing required column #{name}" unless column
          raise "Postgres signalling table #{table} column #{name} has type #{column["format_type"]}; expected #{type}" unless column["format_type"] == type

          next unless required
          next if column["attnotnull"].to_s == "t" || column["attnotnull"] == true

          raise "Postgres signalling table #{table} column #{name} must be NOT NULL"
        end
      end

      def validate_trigger!
        result = pg_conn.exec_params(<<~SQL, [@broadcasts_table_name, BROADCASTS_TRIGGER_NAME])
          SELECT EXISTS (
            SELECT 1
            FROM pg_catalog.pg_trigger
            WHERE tgrelid = to_regclass($1)
              AND tgname = $2
              AND NOT tgisinternal
          )
        SQL

        return if result.getvalue(0, 0) == "t"

        raise "Postgres signalling table #{table} is missing trigger #{BROADCASTS_TRIGGER_NAME}"
      end

      def expected_columns
        [
          ["id", "bigint", true],
          ["payload", "text", true],
          ["claimed_by", "text", false],
          ["claimed_at", "timestamp with time zone", false],
          ["attempts", "integer", true],
          ["last_error", "text", false],
          ["created_at", "timestamp with time zone", true]
        ]
      end

      def quote_table_name(name)
        parts = name.to_s.split(".")
        raise ArgumentError, "Postgres table name cannot be empty" if parts.empty? || parts.any?(&:empty?)
        raise ArgumentError, "Postgres table name must be table or schema.table" if parts.size > 2

        parts.map { |part| ::PG::Connection.quote_ident(part) }.join(".")
      end
    end
  end
end
