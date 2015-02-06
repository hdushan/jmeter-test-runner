# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jmeter-test-runner/version'

Gem::Specification.new do |spec|
  spec.name          = "jmeter-test-runner"
  spec.version       = JmeterTestRunner::VERSION
  spec.author        = "Hans Dushanthakumar"
  spec.email         = "hansrd_98@yahoo.com"
  spec.description   = %q{Lets you run a jmeter Test plan}
  spec.summary       = %q{Lets you run a jmeter Test plan}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.post_install_message = "\nHappy load-tesing! - Hans Dushanthakumar\n"
  spec.required_ruby_version = '>= 1.8.6'
  spec.requirements << 'java should be installed and available in your path'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "rubyzip"
  spec.add_development_dependency "progressbar"

  spec.add_runtime_dependency "bundler", "~> 1.3"
  spec.add_runtime_dependency "rake"
  spec.add_runtime_dependency "nokogiri"
  spec.add_runtime_dependency "rubyzip"
  spec.add_runtime_dependency "progressbar"
end
