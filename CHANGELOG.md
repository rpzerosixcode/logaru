# Changelog

All notable changes to this project will be documented in this file.

> **Note:** This changelog will be maintained starting from version `1.0.0`.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Logaru::Formatter` instances with a configurable pattern (`pattern:` or a block) and pattern arity validation.
- `Logaru::Logger#formatter`, `#level`, `#output` and `#device` readers, plus `Logaru::Logger#close`.
- `Logaru::Logger` accepts `String` and `Pathname` log files, creates their parent directories, reuses the open file between writes and flushes every write (`sync: true`).
- `Logaru::InvalidPatternError` and `Logaru::InvalidOutputError`.

### Changed

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