# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "heretic/version"

Gem::Specification.new do |s|
  s.name        = "heretic"
  s.version     = Heretic::VERSION
  s.authors     = ["Jack Chen (chendo)"]
  s.email       = ["heretic@chen.do"]
  s.homepage    = "http://github.com/chendo/heretic"
  s.summary     = %q{Heretic is a lightweight, no-frills framework for embedding other language runtimes.}
  s.description = %q{Heretic is a lightweight, no-frills framework for embedding other language runtimes.}

  s.rubyforge_project = "heretic"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("json", ">= 1.6.5")
end
