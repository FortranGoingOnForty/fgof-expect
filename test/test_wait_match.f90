program test_wait_match
  use fgof_expect, only : &
    FGOF_EXPECT_STATUS_MATCHED, &
    close_expect, &
    clear_expect_options, &
    exact_pattern, &
    wait_for_match, &
    wait_for_string, &
    spawn_expect
  use fgof_expect_types, only : expect_match, expect_options, expect_pattern, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=16) :: patterns(2)
  character(len=32) :: argv(2)
  type(expect_pattern) :: exact_patterns(1)

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

  patterns = " "
  patterns(2) = "four"
  match = wait_for_match(session, patterns)
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "second wait should match later transcript text"
  if (match%pattern_index /= 2) error stop "pattern index should reflect the matched candidate"
  if (match%text /= "four") error stop "later match should not rematch old transcript text"

  if (.not. close_expect(session)) error stop "session should close cleanly after wait tests"

  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'login: '"
  session = spawn_expect("sh", argv, options)
  match = wait_for_string(session, "login: ")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "wait_for_string should preserve trailing-space prompts"
  if (match%text /= "login: ") error stop "exact string waits should preserve trailing spaces"
  if (.not. close_expect(session)) error stop "exact string wait session should close cleanly"

  argv = ""
  argv(1) = "-c"
  argv(2) = "printf 'guest> '"
  session = spawn_expect("sh", argv, options)
  exact_patterns(1) = exact_pattern("guest> ")
  match = wait_for_match(session, exact_patterns)
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "exact pattern helpers should match trailing-space prompts"
  if (match%text /= "guest> ") error stop "exact pattern helpers should preserve trailing spaces"
  if (.not. close_expect(session)) error stop "exact pattern helper session should close cleanly"
end program test_wait_match
