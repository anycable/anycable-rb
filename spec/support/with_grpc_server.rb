# frozen_string_literal: true

RSpec.shared_context "anycable:grpc:server" do
  before(:all) do
    @server = AnyCable.server_builder.call(AnyCable.config)

    @server.start

    sock = nil

    health_service = if GRPC_KIT
      sock = TCPSocket.new("127.0.0.1", AnyCable.config.rpc_host.split(":").last, connect_timeout: 0.1)
      ::Grpc::Health::V1::Health::Stub.new(sock, timeout: 1)
    else
      ::Grpc::Health::V1::Health::Stub.new(AnyCable.config.rpc_host, :this_channel_is_insecure)
    end

    time = 2.0
    loop do
      begin
        break if health_service.check(Grpc::Health::V1::HealthCheckRequest.new({service: "anycable.RPC"})).status == :SERVING
      rescue GrpcKit::Errors::DeadlineExceeded
      end

      time -= 0.1
      raise "Server is not ready" if time < 0

      sleep 0.1
    end
  ensure
    sock&.close
  end

  after(:all) { @server.stop }
end
