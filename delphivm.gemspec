# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "version_info"
require "delphivm/version"

Gem::Specification.new do |s|
	s.name        = "delphivm"
	s.version     = Delphivm::VERSION
	s.platform    = Gem::Platform::RUBY
	s.authors     = ["Jorge L. Cangas"]
	s.email       = ["jorge.cangas@gmail.com"]
	s.homepage    = "http://github.com/jcangas/delphivm"
	s.summary     = %q{A Ruby gem to manage your multi-IDE delphi projects: build, genenrate docs, and any custom task you want}
	s.description = %q{Easy way to invoke tasks for all your IDE versions from the command line}

	s.rubyforge_project = "delphivm"

	s.files         = `git ls-files`.split("\n")
	s.test_files    = `git ls-files -- {test, spec, features}/*`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
	s.require_paths = ["lib","templates"]

	s.add_runtime_dependency "thor"
	s.add_runtime_dependency "version_info"
	s.add_runtime_dependency "dnote"
	s.add_runtime_dependency "json"
	s.add_runtime_dependency "nokogiri", '>=1.6.3.1'
	s.add_runtime_dependency "psych"
	s.add_runtime_dependency "mini_portile"
	s.add_runtime_dependency "ruby-progressbar"
	s.add_runtime_dependency "rubyzip", '>=1.0.0'
	s.add_runtime_dependency "bundler"

	s.add_development_dependency "rake"
	s.add_development_dependency "minitest"
	s.add_development_dependency "minitest-rg"
	s.add_development_dependency "ocra"
end
