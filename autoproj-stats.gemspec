# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'autoproj/stats/version'

Gem::Specification.new do |spec|
  spec.name          = "autoproj-stats"
  spec.version       = Autoproj::Stats::VERSION
  spec.authors       = ["Sylvain Joyeux"]
  spec.email         = ["sylvain.joyeux@m4x.org"]

  spec.summary       = "authorship and copyright statistics for an autoproj workspace"
  spec.description   =<<-EOD
This autoproj plugin adds the 'stats' subcommand to autoproj, which allows to
compute per-package and aggregated statistics information about authorship, for
all packages within an autoproj workspace
EOD
  spec.homepage      = "https://github.com/doudou/autoproj-stats"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "autoproj", "~> 2.0"
  spec.add_dependency "tty-table"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", '>= 5.0', '~> 5.0'
end
