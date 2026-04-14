# frozen_string_literal: true

module AnyCable
  module RPC
    module Handlers
      module Connect
        def connect(request)
          logger.debug("RPC Connect: #{request.inspect}") if AnyCable.config.log_rpc?

          socket = build_socket(env: request.env)

          connection = factory.call(socket)

          connection.handle_open

          if socket.closed?
            AnyCable::ConnectionResponse.new(
              status: AnyCable::Status::FAILURE,
              transmissions: socket.transmissions
            )
          else
            AnyCable::ConnectionResponse.new(
              status: AnyCable::Status::SUCCESS,
              identifiers: connection.identifiers_json,
              transmissions: socket.transmissions,
              env: build_env_response(socket)
            )
          end
        end
      end
    end
  end
end
