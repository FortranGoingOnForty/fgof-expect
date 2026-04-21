program test_wait_casefold
  use fgof_expect, only : close_expect, clear_expect_options, wait_for_string, spawn_expect
  use fgof_expect_types, only : FGOF_EXPECT_STATUS_MATCHED, expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=32) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 300
  options%case_sensitive = .false.
  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'HELLO prompt'"
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "hello")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "case-insensitive waits should match folded text"
  if (match%text /= "HELLO") error stop "match text should preserve original transcript casing"

  if (.not. close_expect(session)) error stop "case-fold session should close cleanly"
end program test_wait_casefold
