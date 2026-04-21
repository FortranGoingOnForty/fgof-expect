program shell_login
  use fgof_expect, only : close_expect, clear_expect_options, send_line, spawn_expect, transcript_text, wait_for_string
  use fgof_expect_types, only : FGOF_EXPECT_STATUS_MATCHED, expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_match) :: match
  type(expect_session) :: session
  character(len=96) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 500

  argv = ""
  argv(1) = "-c"
  argv(2) = 'printf ''login:''; read user; printf ''hello %s\n'' "$user"'
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "login:")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "login prompt did not arrive"
  if (.not. send_line(session, "guest")) error stop trim(session%error_message)

  match = wait_for_string(session, "hello guest")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "greeting did not arrive"

  print "(A)", trim(transcript_text(session))

  if (.not. close_expect(session)) error stop trim(session%error_message)
end program shell_login
