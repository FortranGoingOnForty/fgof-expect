program repl_roundtrip
  use fgof_expect, only : close_expect, clear_expect_options, send_line, spawn_expect, transcript_text, wait_for_string
  use fgof_expect_types, only : FGOF_EXPECT_STATUS_MATCHED, expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_match) :: match
  type(expect_session) :: session
  character(len=160) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 500

  argv = ""
  argv(1) = "-c"
  argv(2) = 'printf ''calc> ''; while IFS= read -r line; do [ "$line" = quit ] && break; printf ''out:%s\ncalc> '' "$line"; done'
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "calc>")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "repl prompt did not arrive"
  if (.not. send_line(session, "1+1")) error stop trim(session%error_message)

  match = wait_for_string(session, "out:1+1")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "repl output did not arrive"
  if (.not. send_line(session, "quit")) error stop trim(session%error_message)

  print "(A)", trim(transcript_text(session))

  if (.not. close_expect(session)) error stop trim(session%error_message)
end program repl_roundtrip
