# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-splunk"
  gem.version       = "0.0.1"
  gem.authors       = ["Keisuke Nishida"]
  gem.email         = ["knishida@bizmobile.co.jp"]
  gem.description   = %q{Fluent plugin for splunk output}
  gem.summary       = %q{Fluent plugin for splunk output}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.rubyforge_project = "fluent-plugin-splunk"
# ...
  gem.add_development_dependency "fluentd"
  gem.add_development_dependency "net-http-persistent"
  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "net-http-persistent"
end
