# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'agentx/version'

Gem::Specification.new do |spec|
  spec.name          = "agentx"
  spec.version       = AgentX::VERSION
  spec.authors       = ["Eric K Idema"]
  spec.email         = ["eki@vying.org"]
  spec.summary       = %q{...}
  spec.description   = %q{...}
  spec.homepage      = ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_dependency 'ethon'
  spec.add_dependency 'http-cookie'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'listen'
  spec.add_dependency 'oj'
  spec.add_dependency 'sqlite3'
end

