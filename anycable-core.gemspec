# frozen_string_literal: true

require_relative "lib/anycable/version"

Gem::Specification.new do |spec|
  spec.name = "anycable-core"
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

  spec.executables = %w[anycable anycabled]
  spec.files = Dir.glob("lib/**/*") + Dir.glob("bin/*") + %w[README.md MIT-LICENSE CHANGELOG.md] +
    Dir.glob("sig/anycable/**/*.rbs") + %w[sig/anycable.rbs] + %w[sig/manifest.yml]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "anyway_config", "~> 2.2"
  spec.add_dependency "base64", ">= 0.2"
  spec.add_dependency "google-protobuf", "~> 4"
  spec.add_dependency "stringio", "~> 3"

  spec.add_development_dependency "redis", ">= 4.0"
  spec.add_development_dependency "nats-pure", "~> 2"

  spec.add_development_dependency "bundler", ">= 1"
  spec.add_development_dependency "rake", ">= 13.0"

  if ENV["RACK_VERSION"] && ENV["RACK_VERSION"] != ""
    spec.add_development_dependency "rack", ENV["RACK_VERSION"]
  else
    spec.add_development_dependency "rack", "~> 3.0"
  end

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec", ">= 3.5"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
  spec.add_development_dependency "webmock", "~> 3.8"
  spec.add_development_dependency "webrick", ">= 1.9.1"
end
