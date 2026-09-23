# logstyout

[![CI](https://github.com/rpzerosixcode/logstyout/actions/workflows/ci.yml/badge.svg)](https://github.com/rpzerosixcode/logstyout/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D_3.3-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Ruby library focused on clear, organized, and visually appealing log output.

> **Note:** This project is currently under development (`0.1.0`). Official version history and stability guarantees will start with version `1.0.0`. The current codebase provides the gem skeleton (`LSO` namespace, version, test/lint/CI setup) on top of which the logging features will be built.

## Installation

Add Logstyout to your Gemfile:

```ruby
gem "logstyout"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install logstyout
```

## Usage

```ruby
require "lso"

LSO::VERSION # => "0.1.0"
LSO.root     # => absolute path to the gem root
```

That is the whole public API in `0.1.0`. The stylish logging API is not implemented yet — follow the repository for upcoming releases.

## Development

```bash
git clone https://github.com/rpzerosixcode/logstyout.git
cd logstyout
bundle install
```

Run the test suite:

```bash
bundle exec rspec
```

Run the linter (must be clean — CI fails on offenses):

```bash
bundle exec rubocop
```

Run both (default Rake task):

```bash
bundle exec rake
```

Sanity-check the gem build (also run in CI):

```bash
gem build logstyout.gemspec --strict
```

## Project structure

```text
lib/
  lso.rb               # Entry point — LSO namespace
  lso/version.rb       # LSO::VERSION
spec/
  spec_helper.rb       # RSpec configuration
  unit/                # Unit tests
  integration/         # Integration tests
  e2e/                 # End-to-end tests
  support/             # Helpers / shared examples
docs/                  # Guides and additional documentation
.github/workflows/
  ci.yml               # CI: RSpec + RuboCop + gem build (Ruby 3.3/3.4/4.0)
Rakefile               # default: spec + rubocop
logstyout.gemspec      # Gem metadata and dependencies
Gemfile                # source + gemspec
.rubocop.yml           # Style rules
.rspec                 # --require spec_helper
```

## CI

Workflow: `.github/workflows/ci.yml`

- Triggers on `push` and `pull_request` to `main` and `develop`.
- Matrix: `ubuntu-latest` × Ruby `3.3`, `3.4`, `4.0`.
- Steps: checkout → `ruby/setup-ruby` (`bundler-cache: true`) → `bundle exec rspec` → `bundle exec rubocop --parallel` → `gem build logstyout.gemspec --strict`.

## Documentation

Documentation will be expanded as the project approaches its `1.0.0` release.

## Requirements

- Ruby >= 3.3.0 (see `logstyout.gemspec`).

## License

Logstyout is available under the MIT License — see [LICENSE](LICENSE).

## Links

- Homepage: <https://github.com/rpzerosixcode/logstyout>
- Changelog: <https://github.com/rpzerosixcode/logstyout/blob/main/CHANGELOG.md>
