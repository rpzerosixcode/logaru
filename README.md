# Logaru

![Logaru](docs/assets/logaru-logo.png)

[![CI](https://github.com/rpzerosixcode/logaru/actions/workflows/ci.yml/badge.svg)](https://github.com/rpzerosixcode/logaru/actions/workflows/ci.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D_3.3-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A Ruby library focused on clear, organized, and configurable log output.

> 🇧🇷 **Made in Brazil.**
>
> Logaru is a Brazilian Ruby gem, developed in Brazil.

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

Logaru::VERSION # => "1.0.0"

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

Rotating the log is left to your tooling: call `logger.close`, rename or replace the file, and the next entry reopens the path (see [Architecture](docs/ARCHITECTURE.md#log-file-lifecycle)).

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

A logger can be shared between threads: writes are serialized, so entries are never interleaved and the log file is opened only once, even when several threads start together. Patterns run outside that lock, so they should not depend on mutable shared state — see [Concurrency](docs/ARCHITECTURE.md#concurrency).

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

## Releasing

Release by pushing a tag that matches `Logaru::VERSION` (see `lib/logaru/version.rb`):

```bash
git tag v0.1.0

git push origin v0.1.0
```

`.github/workflows/release.yml` then runs the same checks as CI (RSpec, RuboCop and a strict gem build on Ruby 3.3, 3.4 and 4.0), checks the tag against `Logaru::VERSION`, publishes the gem to RubyGems and opens a GitHub release with the gem attached. Publishing uses RubyGems trusted publishing (OIDC), so no API token is stored in the repository — configure a trusted publisher for `logaru` on RubyGems.org (workflow file `.github/workflows/release.yml`) before the first tag.

## Documentation

* [Architecture](docs/ARCHITECTURE.md) — components, entry lifecycle, output resolution and concurrency model.
* [Features](docs/FEATURES.md) — what the library does today and what is still missing.
* [Security](docs/SECURITY.md) — threat surface, known limitations and how to report a vulnerability.

The repository layout, the CI matrix and the Dependabot setup are documented in [Architecture](docs/ARCHITECTURE.md#repository-layout).

## Requirements

* Ruby >= 3.3.0 (see `logaru.gemspec`).

## License

Logaru is available under the MIT License — see [LICENSE](LICENSE).

## Links

* Homepage: https://github.com/rpzerosixcode/logaru
* Changelog: https://github.com/rpzerosixcode/logaru/blob/main/CHANGELOG.md
