# Architecture

How Logaru is built internally. Installation and usage live in the [README](../README.md); the capability checklist is in [FEATURES.md](FEATURES.md).

## Design goals

* **Formatting without global state:** each logger owns its formatter, so changing the output of one logger never changes another.
* **Fail fast:** level, formatter, pattern and output are validated in `Logger.new` instead of failing on the first write.
* **Cheap writes:** entries below the configured level are discarded before formatting, and the log file is opened once and reused.
* **Safe sharing:** one logger can be used by several threads without interleaved or lost entries.
* **No runtime dependencies:** standard library only (`fileutils`, `pathname`).

## Components

| Component | File | Responsibility |
| --- | --- | --- |
| `Logaru` | `lib/logaru.rb` | Loads the components and exposes `Logaru.root`. |
| `Logaru::VERSION` | `lib/logaru/version.rb` | Gem version. |
| `Logaru::Level` | `lib/logaru/level.rb` | Numeric severities (`DEBUG`…`UNKNOWN`), `coerce` (constant, name or symbol) and `name_for`. |
| `Logaru::Formatter` | `lib/logaru/formatter.rb` | Owns the pattern, validates its arity and turns an entry into text (`#format`). |
| `Logaru::Logger` | `lib/logaru/logger.rb` | Filters by level, resolves the output, manages the log file and serializes writes with a mutex. |
| `Logaru::Error` | `lib/logaru/errors.rb` | Error hierarchy: `InvalidFormatterError`, `InvalidLevelError`, `InvalidPatternError`, `InvalidOutputError`. |

## Entry lifecycle

```text
logger.info("message", progname: "web")
  -> severity = Level.coerce(INFO)
  -> return if severity < @level                                 # no formatting, no write, no file created
  -> @formatter.format(severity, Time.now, progname, message)     # outside the lock
  -> @mutex.synchronize { resolved_device.write(text) }
```

## Output resolution

| `file:` value | Device used | Owner |
| --- | --- | --- |
| omitted or `nil` | `$stdout`, resolved on every write | process |
| `String`, `Pathname`, or an object with `to_path` and without `write` | file opened in append mode | the logger (`#close` releases it) |
| object responding to `#write` (`File`, `StringIO`, `Tempfile`, custom device) | the object itself | the caller, never closed by Logaru |

`Pathname` is classified explicitly: it responds to `#write`, but that call replaces the whole file, so treating it as a stream would overwrite the log on every entry. Path-like values are therefore detected before the `#write` check, and `#output` always returns the value given to `file:`.

## Log file lifecycle

1. Opened on the first write that passes the level, so a logger that logs nothing creates neither the file nor its directories.
2. Parent directories are created with `FileUtils.mkdir_p`.
3. Opened in append mode with `sync` (default `true`), so every entry is flushed on write.
4. The handle is reused between writes and exposed by `#device`.
5. `#close` releases only the file the logger opened, and the next write reopens the path in append mode — the supported path for external rotation (close, rename, keep logging).

## Concurrency

* A single `Mutex` per logger serializes device resolution, writing and `#close`, so entries never interleave, none is lost and the file is opened exactly once even when threads start together.
* Formatting runs outside the lock (it is the expensive step), so patterns must not depend on mutable shared state — keep them pure.
* Locking is per logger and per process: Logaru does not use `flock`, so independent processes writing to the same file are not synchronized.

## Repository layout

```text
lib/
  logaru.rb            # entry point — Logaru namespace
  logaru/version.rb    # Logaru::VERSION
  logaru/errors.rb     # Logaru::Error and the specific errors
  logaru/level.rb      # Logaru::Level severities
  logaru/formatter.rb  # Logaru::Formatter — patterns and arity validation
  logaru/logger.rb     # Logaru::Logger — levels, output and file management

spec/
  spec_helper.rb       # RSpec configuration (loads spec/support)
  unit/                # Unit tests
  integration/         # Integration tests
  e2e/                 # End-to-end tests (placeholder)
  support/             # Helpers / shared examples

docs/                   # User documentation (README + this file, FEATURES, SECURITY)

.github/workflows/      # ci.yml — RSpec + RuboCop + gem build
.github/dependabot.yml  # weekly dependency updates

Rakefile                # default task: spec + rubocop
logaru.gemspec          # Gem metadata and dependencies
Gemfile                 # source + gemspec
.rubocop.yml            # Style rules
.rspec                  # --require spec_helper
```

## Automated checks

CI (`.github/workflows/ci.yml`) runs on every push and pull request to `main` and `develop`:

* RSpec suite and `bundle exec rubocop --parallel` on `ubuntu-latest` with Ruby `3.3`, `3.4` and `4.0` (fail-fast disabled);
* `gem build logaru.gemspec --strict` as a packaging sanity check;
* Dependabot opens weekly pull requests for Bundler and GitHub Actions dependencies.

Locally, `bundle exec rake` runs the same checks available in the development environment.
