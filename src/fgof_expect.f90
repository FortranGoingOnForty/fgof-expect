module fgof_expect
  use fgof_expect_types, only : &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_MATCHED, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    expect_match, &
    expect_options, &
    expect_session
  implicit none
  private

  public :: &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_MATCHED, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    clear_expect_match, &
    clear_expect_options, &
    clear_expect_session, &
    expect_match, &
    expect_options, &
    expect_session, &
    expect_status_name

contains

  function clear_expect_options() result(options)
    type(expect_options) :: options

    options%timeout_ms = 1000
    options%case_sensitive = .true.
  end function clear_expect_options

  function clear_expect_match() result(match)
    type(expect_match) :: match

    match%status = FGOF_EXPECT_STATUS_IDLE
    match%pattern_index = 0
    match%text = ""
  end function clear_expect_match

  function clear_expect_session() result(session)
    type(expect_session) :: session

    session%active = .false.
    session%transcript = ""
  end function clear_expect_session

  function expect_status_name(status) result(name)
    integer, intent(in) :: status
    character(len=:), allocatable :: name

    select case (status)
    case (FGOF_EXPECT_STATUS_IDLE)
      name = "idle"
    case (FGOF_EXPECT_STATUS_MATCHED)
      name = "matched"
    case (FGOF_EXPECT_STATUS_TIMEOUT)
      name = "timeout"
    case (FGOF_EXPECT_STATUS_ERROR)
      name = "error"
    case default
      name = "unknown"
    end select
  end function expect_status_name

end module fgof_expect
