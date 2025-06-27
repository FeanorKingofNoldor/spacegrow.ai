# -*- encoding: utf-8 -*-
# stub: stripe_event 2.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "stripe_event".freeze
  s.version = "2.12.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Danny Whalen".freeze]
  s.date = "2025-04-21"
  s.description = "Stripe webhook integration for Rails applications.".freeze
  s.email = "daniel.r.whalen@gmail.com".freeze
  s.homepage = "https://github.com/integrallis/stripe_event".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.6.3".freeze
  s.summary = "Stripe webhook integration for Rails applications.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.1".freeze])
  s.add_runtime_dependency(%q<stripe>.freeze, [">= 2.8".freeze, "< 16".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 3.1".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
end
