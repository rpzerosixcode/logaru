# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-24

First stable release. Requires Ruby >= 3.3 and has no runtime dependencies.

### Added

- `Logaru::Logger` with `debug`, `info`, `warn`, `error`, `fatal` and `unknown`, plus the generic `log(severity, message, progname:)`.
- Level filtering: a severity is accepted as a `Logaru::Level` constant, a name or a symbol, and entries below the configured level are discarded before formatting.
- `Logaru::Logger` writes to `$stdout` by default, to a log file (`String` or `Pathname`: parent directories created, append mode, handle reused, flushed on every write) or to any object responding to `#write`.
- `Logaru::Logger#formatter`, `#level`, `#output` and `#device` readers, plus `#close`, which releases the file opened by the logger so it can be rotated externally — the next write reopens it.
- `Logaru::Formatter` with a configurable pattern (`pattern:` or a block), pattern arity validation and `Logaru::Formatter::DEFAULT_PATTERN`.
- `Logaru::Level` severities, `coerce` and `name_for`.
- Error hierarchy under `Logaru::Error`: `InvalidFormatterError`, `InvalidLevelError`, `InvalidPatternError` and `InvalidOutputError`, all raised from `Logger.new`/`Formatter.new`.
- Thread safety: writes, device resolution and `#close` are serialized by a mutex and the log file is opened only once, so one logger can be shared between threads.

[Unreleased]: https://github.com/rpzerosixcode/logaru/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rpzerosixcode/logaru/releases/tag/v1.0.0