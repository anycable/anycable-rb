# frozen_string_literal: true

require "spec_helper"

require "anycable/broadcast_adapters/postgres"

describe AnyCable::BroadcastAdapters::Postgres do
  let(:pg_conn) { instance_double("PG::Connection") }

  before do
    config.postgres_url = "postgres://postgres-1/anycable"
    config.postgres_broadcasts_table = "anycable_broadcasts"
    config.postgres_contract_table = "anycable_contracts"
    config.postgres_validate_contract = false

    allow(::PG).to receive(:connect) { pg_conn }
  end

  after { AnyCable.config.reload }

  let(:config) { AnyCable.config }

  it "uses config options by default" do
    adapter = described_class.new

    expect(adapter.table).to eq "\"anycable_broadcasts\""
    expect(PG).to have_received(:connect).with("postgres://postgres-1/anycable")
  end

  it "uses override config params" do
    adapter = described_class.new(url: "postgres://local.pg/anycable", broadcasts_table: "public.anycable_broadcasts")

    expect(adapter.table).to eq "\"public\".\"anycable_broadcasts\""
    expect(PG).to have_received(:connect).with("postgres://local.pg/anycable")
  end

  describe "#announce" do
    around do |ex|
      old_logger = AnyCable.logger
      AnyCable.remove_instance_variable(:@logger)
      ex.run
      AnyCable.logger = old_logger
      AnyCable.config.reload
    end

    specify do
      expect { described_class.new.announce! }.to output(/Broadcasting Postgres table: "anycable_broadcasts"/).to_stdout_from_any_process
    end
  end

  describe "#broadcast" do
    it "inserts stream data into the broadcast table" do
      allow(pg_conn).to receive(:exec_params)

      adapter = described_class.new
      adapter.broadcast("notification", "hello!")

      expect(pg_conn).to have_received(:exec_params).with(
        "INSERT INTO \"anycable_broadcasts\" (payload) VALUES ($1)",
        [{stream: "notification", data: "hello!"}.to_json]
      )
    end
  end

  describe "#broadcast_command" do
    it "inserts command data into the broadcast table" do
      allow(pg_conn).to receive(:exec_params)

      adapter = described_class.new
      adapter.broadcast_command("disconnect", identifier: "42")

      expect(pg_conn).to have_received(:exec_params).with(
        "INSERT INTO \"anycable_broadcasts\" (payload) VALUES ($1)",
        [{command: "disconnect", payload: {identifier: "42"}}.to_json]
      )
    end
  end

  describe "contract validation" do
    before do
      config.postgres_validate_contract = true
    end

    let(:version_result) do
      instance_double("PG::Result", ntuples: 1, getvalue: "1")
    end

    let(:columns_result) do
      [
        {"attname" => "id", "format_type" => "bigint", "attnotnull" => "t"},
        {"attname" => "payload", "format_type" => "text", "attnotnull" => "t"},
        {"attname" => "claimed_by", "format_type" => "text", "attnotnull" => "f"},
        {"attname" => "claimed_at", "format_type" => "timestamp with time zone", "attnotnull" => "f"},
        {"attname" => "attempts", "format_type" => "integer", "attnotnull" => "t"},
        {"attname" => "last_error", "format_type" => "text", "attnotnull" => "f"},
        {"attname" => "created_at", "format_type" => "timestamp with time zone", "attnotnull" => "t"}
      ]
    end

    let(:trigger_result) do
      instance_double("PG::Result", getvalue: "t")
    end

    it "checks contract version, columns, and trigger" do
      allow(pg_conn).to receive(:exec_params).and_return(version_result, columns_result, trigger_result)

      expect { described_class.new }.not_to raise_error
    end

    it "fails when the contract row is missing" do
      missing_version = instance_double("PG::Result", ntuples: 0)
      allow(pg_conn).to receive(:exec_params).and_return(missing_version)

      expect { described_class.new }.to raise_error(/contract version mismatch/)
    end
  end
end
