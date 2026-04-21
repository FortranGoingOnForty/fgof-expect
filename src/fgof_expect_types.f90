module fgof_expect_types
  use fgof_pty_types, only : pty_session, terminal_size
  implicit none
  private

  integer, parameter, public :: FGOF_EXPECT_OK = 0
  integer, parameter, public :: FGOF_EXPECT_ERR_INVALID_COMMAND = 10
  integer, parameter, public :: FGOF_EXPECT_ERR_INVALID_OPTIONS = 11
  integer, parameter, public :: FGOF_EXPECT_ERR_INVALID_PATTERN = 12
  integer, parameter, public :: FGOF_EXPECT_ERR_SPAWN_FAILED = 20
  integer, parameter, public :: FGOF_EXPECT_ERR_CLOSE_FAILED = 21
  integer, parameter, public :: FGOF_EXPECT_ERR_SESSION_ENDED = 22
  integer, parameter, public :: FGOF_EXPECT_ERR_INTERNAL = 99

  integer, parameter, public :: FGOF_EXPECT_STATUS_IDLE = 0
  integer, parameter, public :: FGOF_EXPECT_STATUS_MATCHED = 1
  integer, parameter, public :: FGOF_EXPECT_STATUS_TIMEOUT = 2
  integer, parameter, public :: FGOF_EXPECT_STATUS_ERROR = 3

  type, public :: expect_options
    integer :: timeout_ms = 1000
    logical :: case_sensitive = .true.
    type(terminal_size) :: size = terminal_size()
  end type expect_options

  type, public :: expect_match
    integer :: status = FGOF_EXPECT_STATUS_IDLE
    integer :: pattern_index = 0
    integer :: start_index = 0
    integer :: end_index = 0
    character(len=:), allocatable :: text
  end type expect_match

  type, public :: expect_session
    logical :: active = .false.
    type(expect_options) :: options
    type(pty_session) :: pty
    integer :: scan_start = 1
    integer :: error_code = FGOF_EXPECT_OK
    character(len=:), allocatable :: error_message
    type(expect_match) :: last_match
    character(len=:), allocatable :: program
    character(len=:), allocatable :: transcript
  end type expect_session

end module fgof_expect_types
