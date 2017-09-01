# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-splunkapi"
  gem.version       = "0.2.0"
  gem.authors       = ["Keisuke Nishida"]
  gem.email         = ["keisuke.nishida@gmail.com"]
  gem.summary       = %q{Splunk output plugin (REST API / Storm API) for Fluentd event collector}
  gem.description   = %q{Splunk output plugin (REST API / Storm API) for Fluentd event collector}
  gem.homepage      = "https://github.com/k24d/fluent-plugin-splunkapi"
  gem.license       = 'Apache License, Version 2.0'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.rubyforge_project = "fluent-plugin-splunkapi"
  gem.add_development_dependency "fluentd"
  gem.add_development_dependency "net-http-persistent", "~> 3.0"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "net-http-persistent", "~> 3.0"
end
