# frozen_string_literal: true

require "spec_helper"

require "anycable/broadcast_adapters/postgres"

describe AnyCable::BroadcastAdapters::Postgres do
  let(:pg_conn) { instance_double("PG::Connection") }

  before do
    config.postgres_url = "postgres://postgres-1/anycable"

    allow(::PG).to receive(:connect) { pg_conn }
  end

  after { AnyCable.config.reload }

  let(:config) { AnyCable.config }

  it "uses config options by default" do
    described_class.new

    expect(PG).to have_received(:connect).with("postgres://postgres-1/anycable")
  end

  it "uses override config params" do
    described_class.new(url: "postgres://local.pg/anycable")

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
      expect { described_class.new.announce! }.to output(/Broadcasting Postgres functions: anycable_publish, anycable_remote_command/).to_stdout_from_any_process
    end
  end

  describe "#broadcast" do
    it "publishes stream data through the Postgres function" do
      allow(pg_conn).to receive(:exec_params)

      adapter = described_class.new
      adapter.broadcast("notification", "hello!")

      expect(pg_conn).to have_received(:exec_params).with(
        "SELECT anycable_publish($1, $2, $3)",
        [
          "notification",
          {stream: "notification", data: "hello!"}.to_json,
          "{}"
        ]
      )
    end

    it "publishes each batched message through the Postgres function" do
      allow(pg_conn).to receive(:exec_params)

      adapter = described_class.new
      adapter.batching do
        adapter.broadcast("notification", "hello!")
        adapter.broadcast("chat", "hi!", exclude_socket: "42")
      end

      expect(pg_conn).to have_received(:exec_params).with(
        "SELECT anycable_publish($1, $2, $3)",
        [
          "notification",
          {stream: "notification", data: "hello!"}.to_json,
          "{}"
        ]
      )

      expect(pg_conn).to have_received(:exec_params).with(
        "SELECT anycable_publish($1, $2, $3)",
        [
          "chat",
          {stream: "chat", data: "hi!", meta: {exclude_socket: "42"}}.to_json,
          {exclude_socket: "42"}.to_json
        ]
      )
    end
  end

  describe "#broadcast_command" do
    it "publishes command data through the Postgres function" do
      allow(pg_conn).to receive(:exec_params)

      adapter = described_class.new
      adapter.broadcast_command("disconnect", identifier: "42")

      expect(pg_conn).to have_received(:exec_params).with(
        "SELECT anycable_remote_command($1, $2)",
        [
          {command: "disconnect", payload: {identifier: "42"}}.to_json,
          "{}"
        ]
      )
    end
  end

  describe "#raw_broadcast" do
    it "rejects payloads without stream or command" do
      adapter = described_class.new

      expect { adapter.raw_broadcast({data: "hello!"}.to_json) }.to raise_error(ArgumentError, /stream or command/)
    end
  end
end
