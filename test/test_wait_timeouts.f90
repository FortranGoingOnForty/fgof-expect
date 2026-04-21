program test_wait_timeouts
  use fgof_expect, only : &
    FGOF_EXPECT_ERR_SESSION_ENDED, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    close_expect, &
    clear_expect_options, &
    last_expect_match, &
    wait_for_string, &
    spawn_expect
  use fgof_expect_types, only : expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=64) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 100
  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'nope'; sleep 1"
  session = spawn_expect("sh", argv, options)
  match = wait_for_string(session, "yes")
  if (match%status /= FGOF_EXPECT_STATUS_TIMEOUT) error stop "missing pattern before deadline should time out"
  if (.not. session%active) error stop "timeout should leave a running session active"
  match = last_expect_match(session)
  if (match%status /= FGOF_EXPECT_STATUS_IDLE) error stop "timeout should clear stale last-match state"
  if (.not. close_expect(session)) error stop "timed out session should still close cleanly"

  options = clear_expect_options()
  options%timeout_ms = 200
  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'done'"
  session = spawn_expect("sh", argv, options)
  match = wait_for_string(session, "never")
  if (match%status /= FGOF_EXPECT_STATUS_ERROR) error stop "ended session without a match should be an error"
  if (session%error_code /= FGOF_EXPECT_ERR_SESSION_ENDED) error stop "session-ended waits should set the session-ended error"
  if (session%active) error stop "ended session should not remain active"
  match = last_expect_match(session)
  if (match%status /= FGOF_EXPECT_STATUS_IDLE) error stop "session-ended waits should clear stale last-match state"
  if (.not. close_expect(session)) error stop "ended session should still close cleanly"
end program test_wait_timeouts
