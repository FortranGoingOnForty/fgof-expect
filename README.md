# fgof-expect

Expect-style PTY automation helpers for modern Fortran tools.

`fgof-expect` is intended to be a small, standalone library for scripting
interactive terminal programs by waiting for output, matching prompts, and
sending input predictably.

It is part of the [FortranGoingOnForty lib-modules](https://github.com/FortranGoingOnForty/lib-modules)
catalog, but it is intended to stand on its own as a normal `fpm` package.

Current v1 target:

- build on `fgof-pty` instead of re-implementing PTY transport
- expose a small expect session model with transcript capture
- support string matching, timeout handling, and send-or-wait flows
- stay focused on interactive process automation, not general test orchestration

Future scope:

- regex and richer matcher support
- transcript assertions and fixture helpers in a future `fgof-proc-test`
- higher-level scenario DSLs layered on top of the stable core

## Status

First real expect core is in place.

Tracked today:

- public `fgof_expect` and `fgof_expect_types` modules
- PTY-backed `spawn_expect()` and `close_expect()` session lifecycle
- transcript-backed `wait_for_string()` and `wait_for_match()` helpers
- `send_text()` and `send_line()` helpers for interactive request or response flows
- transcript and last-match helpers for diagnostics and incremental automation
- tracked examples for login-style prompts and simple REPL automation
- initial session, options, and match types
- stable status and error constants with naming helpers
- CI and `fpm test` baseline wiring

## Why Use It

- interactive process automation is still a real gap in the Fortran package space
- `fgof-process`, `fgof-pty`, `fgof-termios`, and `fgof-keys` now give us the
  right foundations to build something ergonomic
- expect-style workflows are useful for shells, REPLs, installers, and terminal
  integration tests
- current waits support multiple candidate patterns, default per-session timeouts,
  and case-sensitive or case-insensitive matching

## Public API Shape

Primary modules:

- `fgof_expect`
- `fgof_expect_types`

Public types:

- `expect_options`
- `expect_match`
- `expect_session`

Public constants:

- `FGOF_EXPECT_OK`
- `FGOF_EXPECT_ERR_INVALID_COMMAND`
- `FGOF_EXPECT_ERR_INVALID_OPTIONS`
- `FGOF_EXPECT_ERR_INVALID_PATTERN`
- `FGOF_EXPECT_ERR_SPAWN_FAILED`
- `FGOF_EXPECT_ERR_CLOSE_FAILED`
- `FGOF_EXPECT_ERR_SESSION_ENDED`
- `FGOF_EXPECT_ERR_INTERNAL`
- `FGOF_EXPECT_STATUS_IDLE`
- `FGOF_EXPECT_STATUS_MATCHED`
- `FGOF_EXPECT_STATUS_TIMEOUT`
- `FGOF_EXPECT_STATUS_ERROR`

Current public procedures:

- `clear_expect_match`
- `clear_expect_options`
- `clear_expect_session`
- `clear_transcript`
- `close_expect`
- `expect_backend_name`
- `expect_error_name`
- `expect_status_name`
- `last_expect_match`
- `send_line`
- `send_text`
- `spawn_expect`
- `transcript_text`
- `wait_for_match`
- `wait_for_string`

## Quick Start

```fortran
program demo_expect
  use fgof_expect, only : &
    close_expect, clear_expect_options, send_line, spawn_expect, transcript_text, wait_for_string
  use fgof_expect_types, only : FGOF_EXPECT_STATUS_MATCHED, expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_match) :: match
  type(expect_session) :: session
  character(len=48) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 500

  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'login:'"
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "login:")
  if (match%status == FGOF_EXPECT_STATUS_MATCHED) then
    if (.not. send_line(session, "guest")) then
      print *, session%error_message
    end if
  end if

  print *, transcript_text(session)

  if (.not. close_expect(session)) then
    print *, session%error_message
  end if
end program demo_expect
```

## Examples

Two tracked examples ship with the package:

- `shell_login`
  - waits for a login-style prompt, sends a line, and matches the greeting
- `repl_roundtrip`
  - drives a tiny shell-loop REPL, waits for a prompt, sends input, and matches
    the echoed result

They are compiled as part of the normal package build and test flow.

## Build And Test

```bash
fpm test
```

That is the baseline verification command locally and in CI.

## Supported Platforms

- macOS
- Linux

## Boundaries

- intended to stay independently versioned and releasable
- focused on expect-style PTY automation, not generic unit-test orchestration
- `fgof-proc-test` should sit above this package, not inside it
- `fgof-pty` remains the transport and lifecycle layer underneath this package
- current matching is string-based; richer regex or DSL layers should stay above
  this core
- transcripts record raw terminal output, so interactive children may echo input
  back into the transcript depending on their terminal mode

## License

MIT
