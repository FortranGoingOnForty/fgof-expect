program test_session_options
  use fgof_expect, only : &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    clear_expect_options, &
    spawn_expect
  use fgof_expect_types, only : expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session

  session = spawn_expect("")
  if (session%error_code /= FGOF_EXPECT_ERR_INVALID_COMMAND) error stop "empty program should be rejected"
  if (session%active) error stop "invalid spawn should not activate the session"

  options = clear_expect_options()
  options%size%rows = 0
  session = spawn_expect("cat", options=options)
  if (session%error_code /= FGOF_EXPECT_ERR_INVALID_OPTIONS) error stop "invalid size should be rejected"
  if (session%active) error stop "invalid options should not activate the session"
end program test_session_options
