# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "graph_model/version"

Gem::Specification.new do |s|
  s.name        = "graph_model"
  s.version     = GraphModel::VERSION
  s.authors     = ["nickflux"]
  s.email       = ["nick@bolsovernetworks.com"]
  s.homepage    = "http://github.com/nickflux/graph_model"
  s.summary     = %q{Thin layer on top of neography for creating models for a Neo4j database in rails}
  s.description = %q{Tying together the neography and active_attr gems to create basic models for a Rails app using a Neo4j database}

  s.rubyforge_project = "graph_model"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  
  s.add_dependency 'active_attr'
  # uncomment this once neography is stable
  s.add_dependency 'neography'
  
end
