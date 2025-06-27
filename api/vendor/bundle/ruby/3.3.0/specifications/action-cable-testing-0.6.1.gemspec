# -*- encoding: utf-8 -*-
# stub: action-cable-testing 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "action-cable-testing".freeze
  s.version = "0.6.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Vladimir Dementyev".freeze]
  s.date = "2020-03-03"
  s.description = "Testing utils for Action Cable".freeze
  s.email = ["dementiev.vm@gmail.com".freeze]
  s.homepage = "http://github.com/palkan/action-cable-testing".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.6".freeze
  s.summary = "Testing utils for Action Cable".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<actioncable>.freeze, [">= 5.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.10".freeze])
  s.add_development_dependency(%q<cucumber>.freeze, ["~> 3.1.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, ["~> 3.5".freeze])
  s.add_development_dependency(%q<aruba>.freeze, ["~> 0.14.6".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.9".freeze])
  s.add_development_dependency(%q<ammeter>.freeze, ["~> 1.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.68.0".freeze])
end
