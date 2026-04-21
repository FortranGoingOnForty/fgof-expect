program test_scaffold
  use fgof_expect, only : &
    FGOF_EXPECT_STATUS_ERROR, &
    clear_expect_match, &
    clear_expect_options, &
    clear_expect_session, &
    expect_status_name
  use fgof_expect_types, only : expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_match) :: match
  type(expect_session) :: session

  options = clear_expect_options()
  if (options%timeout_ms /= 1000) error stop "default timeout should be 1000 ms"
  if (.not. options%case_sensitive) error stop "default matches should be case sensitive"

  match = clear_expect_match()
  if (match%status /= 0) error stop "default match status should be idle"
  if (match%pattern_index /= 0) error stop "default pattern index should be zero"
  if (match%text /= "") error stop "default match text should be empty"

  session = clear_expect_session()
  if (session%active) error stop "default session should be inactive"
  if (session%transcript /= "") error stop "default transcript should be empty"

  if (expect_status_name(FGOF_EXPECT_STATUS_ERROR) /= "error") then
    error stop "status helper should name known statuses"
  end if

  if (expect_status_name(999) /= "unknown") then
    error stop "status helper should name unknown statuses"
  end if
end program test_scaffold
