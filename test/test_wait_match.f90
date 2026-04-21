program test_wait_match
  use fgof_expect, only : &
    FGOF_EXPECT_STATUS_MATCHED, &
    close_expect, &
    clear_expect_options, &
    wait_for_match, &
    wait_for_string, &
    spawn_expect
  use fgof_expect_types, only : expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=4) :: patterns(2)
  character(len=32) :: argv(2)

  options = clear_expect_options()
  options%timeout_ms = 500
  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'one four'"
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "one")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "first pattern should match"
  if (match%pattern_index /= 1) error stop "single-pattern waits should report pattern one"
  if (match%text /= "one") error stop "matched text should preserve transcript bytes"
  if (match%start_index /= 1 .or. match%end_index /= 3) error stop "match offsets should be tracked"

  patterns = ""
  patterns(1) = "zero"
  patterns(2) = "four"
  match = wait_for_match(session, patterns)
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "second wait should match later transcript text"
  if (match%pattern_index /= 2) error stop "pattern index should reflect the matched candidate"
  if (match%text /= "four") error stop "later match should not rematch old transcript text"

  if (.not. close_expect(session)) error stop "session should close cleanly after wait tests"
end program test_wait_match
