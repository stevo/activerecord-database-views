# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'activerecord-database-views/version'

Gem::Specification.new do |s|
  s.name          = "activerecord-database-views"
  s.version       = Activerecord::Database::Views::VERSION
  s.authors       = ["stevo"]
  s.email         = ["blazej.kosmowski@selleo.com"]
  s.homepage      = "https://github.com/stevo/activerecord-database-views"
  s.summary       = "Facilitates reloading of DB views"
  s.description   = "Facilitates storing and reloading of DB views within Rails applications"

  s.files         = `git ls-files app lib`.split("\n")
  s.platform      = Gem::Platform::RUBY
  s.require_paths = ['lib']
  s.rubyforge_project = '[none]'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'pg'
  s.add_runtime_dependency 'activerecord', '~> 4.0', '<= 5.0'
end
