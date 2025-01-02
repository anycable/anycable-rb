# frozen_string_literal: true

require "rack"
require "anycable"
require "anycable/cli"

require_relative "../support/test_factory"

AnyCable.connection_factory = AnyCable::TestFactory

AnyCable::CLI.embed!(["--version-check-enabled=false"])

p "Server started"

loop {
  # Make sure we're not holding the GLV forever
  sleep 0.1
}
