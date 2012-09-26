# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "list_editor/version"

Gem::Specification.new do |s|
  s.name        = "list_editor"
  s.version     = ListEditor::VERSION
  s.authors     = ["Michael Kovacs"]
  s.email       = ["kovacs@mkovacs.com"]
  s.homepage    = ""
  s.summary     = %q{Allows for the easy insertion of AJAX CRUD into a controller for a given model}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "list_editor"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
