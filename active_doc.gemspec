# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "active_doc"

Gem::Specification.new do |s|
  s.name        = 'active_doc'
  s.version     = ActiveDoc::VERSION
  s.authors     = ["Ivan Nečas"]
  s.description = 'DSL for executable documentation of your code.'
  s.summary     = "active_doc-#{s.version}"
  s.email       = 'necasik@gmail.com'
  s.homepage    = "http://github.com/necasik/active_doc"

  s.post_install_message = %{
(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)

Thank you for installing active_doc-#{ActiveDoc::VERSION}.
(::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::) (::)

}

  s.add_development_dependency 'rake', '~> 0.8.7'
  s.add_development_dependency 'rspec', '~> 2.3.0'

  s.rubygems_version   = "1.3.7"
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = ["LICENSE", "README.rdoc", "History.txt"]
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"
end
