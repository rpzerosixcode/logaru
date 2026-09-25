# frozen_string_literal: true

require_relative "lib/logaru/version"

Gem::Specification.new do |spec|
    spec.name        = "logaru"
    spec.version     = Logaru::VERSION
    spec.authors     = ["rpzerosixcode"]

    spec.summary     = "A Ruby library for clear, organized, and configurable log output."

    spec.description = "Ruby library focused on clear, organized, and configurable " \
                       "log output for applications."

    spec.homepage    = "https://github.com/rpzerosixcode/logaru"
    spec.license     = "MIT"

    spec.required_ruby_version = Gem::Requirement.new(">= 3.3.0")

    spec.files = Dir.chdir(__dir__) do
        Dir["lib/**/*", "docs/**/*", "CHANGELOG.md", "LICENSE", "README.md", "Rakefile"]
    end

    spec.require_paths = ["lib"]

    spec.add_development_dependency "rake", "~> 13.4"
    spec.add_development_dependency "rspec", "~> 3.13"
    spec.add_development_dependency "rubocop", "~> 1.90"
    spec.add_development_dependency "rubocop-rake", "~> 0.7"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
    spec.metadata["rubygems_mfa_required"] = "true"
    spec.metadata["keywords"] = "ruby, logger, logging, logs"

end