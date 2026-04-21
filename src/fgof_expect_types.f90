module fgof_expect_types
  implicit none
  private

  integer, parameter, public :: FGOF_EXPECT_STATUS_IDLE = 0
  integer, parameter, public :: FGOF_EXPECT_STATUS_MATCHED = 1
  integer, parameter, public :: FGOF_EXPECT_STATUS_TIMEOUT = 2
  integer, parameter, public :: FGOF_EXPECT_STATUS_ERROR = 3

  type, public :: expect_options
    integer :: timeout_ms = 1000
    logical :: case_sensitive = .true.
  end type expect_options

  type, public :: expect_match
    integer :: status = FGOF_EXPECT_STATUS_IDLE
    integer :: pattern_index = 0
    character(len=:), allocatable :: text
  end type expect_match

  type, public :: expect_session
    logical :: active = .false.
    character(len=:), allocatable :: transcript
  end type expect_session

end module fgof_expect_types
