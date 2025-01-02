# frozen_string_literal: true

RSpec.shared_context "anycable:grpc:server" do
  before(:all) do
    @server = AnyCable.server_builder.call(AnyCable.config)

    @server.start

    health_service = if GRPC_KIT
      sock = TCPSocket.new(*AnyCable.config.rpc_host.split(":"))
      ::Grpc::Health::V1::Health::Stub.new(sock)
    else
      ::Grpc::Health::V1::Health::Stub.new(AnyCable.config.rpc_host, :this_channel_is_insecure)
    end

    time = 2.0
    loop do
      break if health_service.check(Grpc::Health::V1::HealthCheckRequest.new({service: "anycable.RPC"})).status == :SERVING
      raise "Server is not ready" if (time -= 0.1) < 0
      sleep 0.1
    end
  end

  after(:all) { @server.stop }
end
