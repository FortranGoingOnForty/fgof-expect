program test_session_spawn
  use fgof_expect, only : &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_OK, &
    close_expect, &
    clear_expect_options, &
    expect_backend_name, &
    expect_error_name, &
    spawn_expect
  use fgof_expect_types, only : expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session

  options = clear_expect_options()
  session = spawn_expect("cat", options=options)
  if (.not. session%active) error stop "spawned session should be active"
  if (.not. session%pty%is_open) error stop "spawned session should own an open PTY"
  if (.not. session%pty%child_running) error stop "spawned session child should be running"
  if (session%error_code /= FGOF_EXPECT_OK) error stop "spawned session should not report an error"
  if (session%program /= "cat") error stop "spawned session should track the program name"
  if (expect_backend_name() /= "fgof-pty/posix") error stop "backend name should compose through fgof-pty"
  if (expect_error_name(FGOF_EXPECT_ERR_INVALID_COMMAND) /= "invalid-command") then
    error stop "error helper should name known errors"
  end if
  if (.not. close_expect(session)) error stop "spawned session should close cleanly"
  if (session%active) error stop "closed session should not stay active"
end program test_session_spawn
