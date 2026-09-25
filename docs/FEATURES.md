# Features

What Logaru offers today. Current version: `0.1.0` (pre-`1.0.0` development release). Usage examples are in the [README](../README.md); internal design in [ARCHITECTURE.md](ARCHITECTURE.md).

## Severities and filtering

* Six severities: `debug`, `info`, `warn`, `error`, `fatal` and `unknown`, plus the generic `log(severity, message, progname:)`.
* A level can be given as a `Logaru::Level` constant, a name or a symbol, in any case.
* Entries below the configured level are discarded before formatting: they cost nothing and never create a log file. The default level is `debug`.

## Output

* Standard output by default (`$stdout`, resolved on every write).
* Log files through a `String` or a `Pathname`: created on first use, parent directories created automatically, append mode, handle reused, one flush per entry.
* Any object responding to `#write` (`File`, `StringIO`, `Tempfile`, custom devices) — streams Logaru did not open are never closed by it.
* `sync: false` for buffered writes, `#close` to release the file, `#device` and `#output` for introspection.

## Formatting

* Default pattern (`[<timestamp>] [<progname> ]<LEVEL>: <message>`) or a custom `pattern:`/block for each logger.
* A `Logaru::Formatter` instance can be built once and injected into several loggers.
* Patterns are validated when created: they must be callable and able to receive the four entry arguments (severity, datetime, progname, message). Lambdas, variadic blocks, optional parameters and callables without `#parameters` are supported.
* Optional `progname` per entry.

## Concurrency

* A logger can be shared between threads: entries are written atomically and the log file is opened exactly once.
* `#close` is safe while other threads are logging.

## Operations

* External rotation (rename or replace the file) works through `#close` and the automatic reopen on the next write.
* Invalid configuration (formatter, level, pattern, output) raises a `Logaru::Error` subclass at `Logger.new`.
* No runtime dependencies; Ruby >= 3.3.

## Not available yet

Log rotation by size or date, asynchronous logging, ANSI colors, message sanitization (see [SECURITY.md](SECURITY.md)) and cross-process locking are not implemented. The public API may still change until `1.0.0`.
