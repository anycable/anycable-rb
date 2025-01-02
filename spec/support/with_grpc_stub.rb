# frozen_string_literal: true

RSpec.shared_context "anycable:grpc:stub" do
  include_context "rpc_command"

  before(:all) do
    @service =
      if GRPC_KIT
        @sock = TCPSocket.new("127.0.0.1", AnyCable.config.rpc_host.split(":").last, connect_timeout: 0.1)
        AnyCable::GRPC::Stub.new(@sock, timeout: 1)
      else
        AnyCable::GRPC::Stub.new(AnyCable.config.rpc_host, :this_channel_is_insecure)
      end
    # ignore failed connections
    # (happens when using grpc_kit and launching server after setting up a service)
  rescue Errno::ECONNREFUSED
  end

  let(:service) do
    @service || begin
      if GRPC_KIT
        sock = TCPSocket.new("0.0.0.0", AnyCable.config.rpc_host.split(":").last, connect_timeout: 0.1)
        AnyCable::GRPC::Stub.new(sock, timeout: 1)
      else
        AnyCable::GRPC::Stub.new(AnyCable.config.rpc_host, :this_channel_is_insecure)
      end
    end
  end
end
