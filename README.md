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

Initial scaffold is in place.

Tracked today:

- public `fgof_expect` and `fgof_expect_types` modules
- PTY-backed `spawn_expect()` and `close_expect()` session lifecycle
- initial session, options, and match types
- stable status and error constants with naming helpers
- CI and `fpm test` baseline wiring

## Why Use It

- interactive process automation is still a real gap in the Fortran package space
- `fgof-process`, `fgof-pty`, `fgof-termios`, and `fgof-keys` now give us the
  right foundations to build something ergonomic
- expect-style workflows are useful for shells, REPLs, installers, and terminal
  integration tests

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
- `FGOF_EXPECT_ERR_SPAWN_FAILED`
- `FGOF_EXPECT_ERR_CLOSE_FAILED`
- `FGOF_EXPECT_ERR_INTERNAL`
- `FGOF_EXPECT_STATUS_IDLE`
- `FGOF_EXPECT_STATUS_MATCHED`
- `FGOF_EXPECT_STATUS_TIMEOUT`
- `FGOF_EXPECT_STATUS_ERROR`

Current public procedures:

- `clear_expect_match`
- `clear_expect_options`
- `clear_expect_session`
- `close_expect`
- `expect_backend_name`
- `expect_error_name`
- `expect_status_name`
- `spawn_expect`

## Quick Start

```fortran
program demo_expect
  use fgof_expect, only : close_expect, spawn_expect
  use fgof_expect_types, only : expect_session
  implicit none

  type(expect_session) :: session

  session = spawn_expect("cat")
  if (session%active) then
    print *, "session ready"
  end if

  if (.not. close_expect(session)) then
    print *, session%error_message
  end if
end program demo_expect
```

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

## License

MIT
