# Logaru

[![CI](https://github.com/rpzerosixcode/logaru/actions/workflows/ci.yml/badge.svg)](https://github.com/rpzerosixcode/logaru/actions/workflows/ci.yml)

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D_3.3-ruby.svg)](https://www.ruby-lang.org)

[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Ruby library focused on clear, organized, and configurable log output.

> **Note:** This project is currently under development (`0.1.0`). Official version history and stability guarantees will start with version `1.0.0`. The current codebase provides the gem skeleton and core logging functionality on top of which the project will continue to evolve.

## Installation

Add Logaru to your Gemfile:

```ruby
gem "logaru"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install logaru
```

## Usage

```ruby
require "logaru"

Logaru::VERSION # => "0.1.0"

Logaru.root # => absolute path to the gem root
```

The logger supports `debug`, `info`, `warn`, `error`, `fatal`, and `unknown` messages. Levels can be configured with a `Logaru::Level` constant, a level name, or a symbol:

```ruby
logger = Logaru::Logger.new(level: :info)

logger.debug("This message is ignored")

logger.info("Application started", progname: "web")

logger.error("An unexpected error occurred")
```

Pass `file:` to append messages to a file. Log files are opened on the first write, reused afterwards, and their parent directories are created automatically:

```ruby
logger = Logaru::Logger.new(file: "log/application.log")

logger.info("Application started")

logger.output  # => "log/application.log"

logger.device  # => the File object used for writing

logger.close   # closes the file; it is reopened on the next write
```

A `Pathname` or any object responding to `#write` (such as `StringIO` or an already open `File`) is accepted as well. Writes are flushed by default (`sync: true`) so the file is always up to date, and the logger only closes files it opened itself — streams provided through `file:` remain the caller's responsibility.

### Formatters

Every logger builds its own `Logaru::Formatter`, so customizing the output never requires injecting one:

```ruby
logger = Logaru::Logger.new(level: :debug, file: "log/application.log") do |severity, datetime, progname, message|
  "[#{datetime}] #{progname || "app"} #{Logaru::Level.name_for(severity).upcase}: #{message}\n"
end
```

The same pattern can be passed as an option, and a formatter instance can still be injected to share one configuration between loggers (`formatter:` and `pattern:` are mutually exclusive):

```ruby
pattern = proc { |severity, datetime, progname, message| "#{severity} #{message}\n" }

Logaru::Logger.new(pattern: pattern)

formatter = Logaru::Formatter.new(pattern: pattern)

Logaru::Logger.new(formatter: formatter)

Logaru::Logger.new(formatter: formatter, pattern: pattern)

# => Logaru::InvalidFormatterError: pass either formatter or pattern, not both
```

Formatters keep no global state, so each logger can use its own pattern. A pattern must be able to receive the four arguments (`severity`, `datetime`, `progname`, `message`); variadic patterns such as `|*arguments|` are accepted too:

```ruby
Logaru::Formatter.new { |message| "#{message}\n" }

# => Logaru::InvalidPatternError: pattern must accept 4 arguments
```

### Thread safety

A logger can be shared between threads: writes — including opening and closing the log file — are serialized by a mutex, so entries are never interleaved and the file is opened only once, even when several threads start together. The formatter pattern is called outside the lock, so it must not depend on mutable shared state.

### Errors

Every error raised by Logaru inherits from `Logaru::Error`:

* `Logaru::InvalidFormatterError` — the formatter does not respond to `#format`.
* `Logaru::InvalidLevelError` — the configured severity is not supported.
* `Logaru::InvalidPatternError` — the formatter pattern is not callable or cannot receive the log arguments.
* `Logaru::InvalidOutputError` — the logger output is neither a path nor an object responding to `#write`.

## Development

```bash
git clone https://github.com/rpzerosixcode/logaru.git

cd logaru

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
gem build logaru.gemspec --strict
```

## Project structure

```text
lib/
  logaru.rb            # Entry point — Logaru namespace
  logaru/version.rb    # Logaru::VERSION
  logaru/errors.rb     # Logaru::Error and the specific errors
  logaru/level.rb      # Logaru::Level severities
  logaru/formatter.rb  # Logaru::Formatter — patterns and arity validation
  logaru/logger.rb     # Logaru::Logger — levels, output and file management

spec/
  spec_helper.rb       # RSpec configuration (loads spec/support)
  unit/                # Unit tests
  integration/         # Integration tests
  e2e/                 # End-to-end tests
  support/              # Helpers / shared examples

docs/                   # Guides and additional documentation

.github/workflows/
  ci.yml                # CI: RSpec + RuboCop + gem build (Ruby 3.3/3.4/4.0)

Rakefile                # default: spec + rubocop
logaru.gemspec          # Gem metadata and dependencies
Gemfile                 # source + gemspec
.rubocop.yml            # Style rules
.rspec                  # --require spec_helper
```

## CI

Workflow: `.github/workflows/ci.yml`

* Triggers on `push` and `pull_request` to `main` and `develop`.
* Matrix: `ubuntu-latest` × Ruby `3.3`, `3.4`, `4.0`.
* Steps: checkout → `ruby/setup-ruby` (`bundler-cache: true`) → `bundle exec rspec` → `bundle exec rubocop --parallel` → `gem build logaru.gemspec --strict`.

## Documentation

Documentation will be expanded as the project approaches its `1.0.0` release.

## Requirements

* Ruby >= 3.3.0 (see `logaru.gemspec`).

## License

Logaru is available under the MIT License — see [LICENSE](LICENSE).

## Links

* Homepage: https://github.com/rpzerosixcode/logaru
* Changelog: https://github.com/rpzerosixcode/logaru/blob/main/CHANGELOG.md
