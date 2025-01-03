# frozen_string_literal: true

require "anycable/rpc/handlers/connect"
require "anycable/rpc/handlers/disconnect"
require "anycable/rpc/handlers/command"

module AnyCable
  module RPC
    # Generic RPC handler
    class Handler
      include Handlers::Connect
      include Handlers::Disconnect
      include Handlers::Command

      def initialize(middleware: AnyCable.middleware)
        @middleware = middleware
        @commands = {}
      end

      def handle(cmd, data, meta = {})
        middleware.call(cmd, data, meta) do
          send(cmd, data)
        end
      end

      def supported?(cmd)
        %i[connect disconnect command].include?(cmd)
      end

      private

      attr_reader :commands, :middleware

      def build_socket(env:)
        AnyCable::Socket.new(env: env)
      end

      def build_env_response(socket)
        AnyCable::EnvResponse.new(
          cstate: socket.cstate.changed_fields,
          istate: socket.istate.changed_fields
        )
      end

      def build_presence_response(socket)
        return unless socket.presence

        info = socket.presence[:info]
        info = info.to_json if info && !info.is_a?(String)

        AnyCable::PresenceResponse.new(
          type: socket.presence.fetch(:type),
          id: socket.presence.fetch(:id),
          info: info
        )
      end

      def logger
        AnyCable.logger
      end

      def factory
        AnyCable.connection_factory
      end
    end
  end
end
