# Security

How Logaru handles untrusted input, and what it does not protect against.

Supported versions: `0.1.0` is a pre-`1.0.0` development release; security fixes are applied to the `develop` branch until `1.0.0` is published.

## Threat surface

* No runtime dependencies — only the Ruby standard library (`fileutils`, `pathname`).
* No `eval`, no dynamic dispatch of user input, no deserialization and no execution of external content.
* No network access and no telemetry: the library neither collects nor transmits data.
* Inputs are the logger options (`level`, `file`, `formatter`, `pattern`, `sync`), the messages and the progname; they affect only local formatting and writing.
* Paths are used as given: `file:` is opened in append mode and missing parent directories are created. Logaru does not restrict or sandbox paths, so never build a log path from untrusted input.

## Considerations

### Control characters in messages (not mitigated)

Messages are written exactly as received, so control characters (`\e`, `\r`, `\n`, `\b`) can forge log lines or manipulate the terminal of whoever reads the log — for example `"ok\rINFO: all good"`. Neither `Logaru::Formatter` nor `Logaru::Logger` sanitizes messages: sanitize at the source, or return an escaped message from a custom pattern.

### Sensitive content

Messages may contain personal data, credentials in URLs, tokens or payloads. The library does not mask, redact or filter anything: retention policy, masking and access control are the application's responsibility.

### File permissions and lifetime

The file is created with the process defaults (`umask`/ACLs apply) in append mode, and missing parent directories are created with default permissions. The handle stays open until `Logger#close`, so release it before archiving or removing the file — on Windows an open file cannot be renamed or deleted.

### Writing from several processes

Synchronization is per logger and per process. Two processes appending to the same file are not coordinated, so entries may interleave when writes are buffered: keep the default `sync: true`, use one writer per file, or send logs to an external collector.

## Reporting a vulnerability

* Report privately through GitHub: **Security → Advisories → Report a vulnerability** (<https://github.com/rpzerosixcode/logaru/security/advisories/new>).
* Do not open a public issue for something exploitable.
* Include the version or commit, Ruby version, operating system, reproduction steps, impact and, when possible, a suggested fix.
* There is no bug bounty program. Gem releases require MFA (`rubygems_mfa_required`) and fixes are noted in the changelog.
