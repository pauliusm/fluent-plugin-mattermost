lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-mattermost"
  spec.version = "0.1.0"
  spec.authors = ["Pierluigi Minardi"]
  spec.email   = ["p.minardi@levigo.de"]

  spec.summary       = "fluent-plugin-mattemost"
  spec.description   = "This plugin allows you to send messages to mattermost in case of errors"
  spec.homepage      = "https://www.levigo.de"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2.31"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "test-unit", "~> 3.3.9"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
