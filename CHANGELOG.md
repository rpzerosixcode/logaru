# Changelog

All notable changes to this project will be documented in this file.

> **Note:** This changelog will be maintained starting from version `1.0.0`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Logaru::Logger` accepts `pattern:` or a block and builds its formatter with it, so customizing the output no longer requires injecting a formatter.
- `Logaru::Formatter` instances with a configurable pattern (`pattern:` or a block) and pattern arity validation.
- `Logaru::Logger#formatter`, `#level`, `#output` and `#device` readers, plus `Logaru::Logger#close`.
- `Logaru::Logger` accepts `String` and `Pathname` log files, creates their parent directories, reuses the open file between writes and flushes every write (`sync: true`).
- `Logaru::InvalidPatternError` and `Logaru::InvalidOutputError`.

### Fixed

- `Logaru::Logger` treats a `Pathname` as a file path instead of a stream: `Pathname` responds to `#write`, so it used to be used as the device itself and every entry overwrote the log file instead of appending.

### Changed

- Writes — including opening and closing the log file — are serialized by a mutex, so a logger can be shared between threads and the file is opened only once; `#close` waits for the write in progress.
- `Logaru::Formatter` no longer keeps mutable global state: patterns belong to instances instead of the class.
- `Logaru::Logger` writes through a `Logaru::Formatter` instance instead of the formatter class.
- Invalid logger outputs now fail immediately with `Logaru::InvalidOutputError` instead of later while writing.

### Removed

- `Logaru::Formatter.pattern` and `Logaru::Formatter.format` class methods — use `Logaru::Formatter.new(pattern: ...)` and `#format` instead.

## [1.0.0] - YYYY-MM-DD

### Added

- Initial release.

[Unreleased]: https://github.com/rpzerosixcode/logaru/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/rpzerosixcode/logaru/releases/tag/v1.0.0