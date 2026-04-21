program test_failure_edges
  use fgof_expect, only : &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    FGOF_EXPECT_ERR_INVALID_PATTERN, &
    FGOF_EXPECT_ERR_SESSION_ENDED, &
    close_expect, &
    clear_expect_options, &
    clear_transcript, &
    send_text, &
    spawn_expect, &
    transcript_text, &
    wait_for_match, &
    wait_for_string
  use fgof_expect_types, only : FGOF_EXPECT_STATUS_ERROR, expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=64) :: argv(2)
  character(len=4) :: blank_patterns(1)

  options = clear_expect_options()
  options%timeout_ms = 200
  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'ready'"
  session = spawn_expect("sh", argv, options)

  blank_patterns = ""
  match = wait_for_match(session, blank_patterns)
  if (match%status /= FGOF_EXPECT_STATUS_ERROR) error stop "blank patterns should be rejected"
  if (session%error_code /= FGOF_EXPECT_ERR_INVALID_PATTERN) error stop "blank patterns should set invalid-pattern"

  match = wait_for_string(session, "ready", -1)
  if (match%status /= FGOF_EXPECT_STATUS_ERROR) error stop "negative timeout should be rejected"
  if (session%error_code /= FGOF_EXPECT_ERR_INVALID_OPTIONS) error stop "negative timeout should set invalid-options"

  call clear_transcript(session)
  if (transcript_text(session) /= "") error stop "clear_transcript should remain callable after errors"

  if (.not. close_expect(session)) error stop "session should close after validation failures"
  if (send_text(session, "again")) error stop "send_text should fail on a closed session"
  if (session%error_code /= FGOF_EXPECT_ERR_SESSION_ENDED) error stop "closed send should surface session-ended"
end program test_failure_edges
