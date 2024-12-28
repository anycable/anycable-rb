# frozen_string_literal: true

require_relative "lib/anycable/version"

Gem::Specification.new do |spec|
  spec.name = "anycable"
  spec.version = AnyCable::VERSION
  spec.authors = ["Vladimir Dementyev"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "Ruby SDK for AnyCable, an open-source realtime server for reliable two-way communication"
  spec.description = "Ruby SDK for AnyCable, an open-source realtime server for reliable two-way communication"
  spec.homepage = "http://github.com/anycable/anycable-rb"
  spec.license = "MIT"
  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/anycable/anycable-rb/issues",
    "changelog_uri" => "https://github.com/anycable/anycable-rb/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://docs.anycable.io/",
    "homepage_uri" => "https://anycable.io/",
    "source_code_uri" => "http://github.com/anycable/anycable-rb",
    "funding_uri" => "https://github.com/sponsors/anycable"
  }

  spec.executables = []
  spec.files = %w[README.md MIT-LICENSE CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "anycable-core", AnyCable::VERSION
  spec.add_dependency "grpc", "~> 1.6"
end
