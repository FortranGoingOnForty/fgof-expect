module fgof_expect
  use fgof_pty, only : &
    FGOF_PTY_ERR_CLOSE_FAILED, &
    FGOF_PTY_ERR_EXEC_FAILED, &
    FGOF_PTY_ERR_INTERNAL, &
    FGOF_PTY_ERR_INVALID_COMMAND, &
    FGOF_PTY_ERR_INVALID_SIZE, &
    FGOF_PTY_ERR_SPAWN_FAILED, &
    close_pty, &
    pty_backend_name, &
    spawn_pty
  use fgof_expect_types, only : &
    FGOF_EXPECT_ERR_CLOSE_FAILED, &
    FGOF_EXPECT_ERR_INTERNAL, &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    FGOF_EXPECT_ERR_SPAWN_FAILED, &
    FGOF_EXPECT_OK, &
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
    FGOF_EXPECT_ERR_CLOSE_FAILED, &
    FGOF_EXPECT_ERR_INTERNAL, &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    FGOF_EXPECT_ERR_SPAWN_FAILED, &
    FGOF_EXPECT_OK, &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_MATCHED, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    clear_expect_match, &
    clear_expect_options, &
    clear_expect_session, &
    close_expect, &
    expect_match, &
    expect_options, &
    expect_session, &
    expect_backend_name, &
    expect_error_name, &
    expect_status_name
  public :: spawn_expect

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
    session%error_code = FGOF_EXPECT_OK
    session%error_message = ""
    session%program = ""
    session%transcript = ""
  end function clear_expect_session

  function expect_backend_name() result(name)
    character(len=:), allocatable :: name

    name = "fgof-pty/" // pty_backend_name()
  end function expect_backend_name

  function expect_error_name(code) result(name)
    integer, intent(in) :: code
    character(len=:), allocatable :: name

    select case (code)
    case (FGOF_EXPECT_OK)
      name = "ok"
    case (FGOF_EXPECT_ERR_INVALID_COMMAND)
      name = "invalid-command"
    case (FGOF_EXPECT_ERR_INVALID_OPTIONS)
      name = "invalid-options"
    case (FGOF_EXPECT_ERR_SPAWN_FAILED)
      name = "spawn-failed"
    case (FGOF_EXPECT_ERR_CLOSE_FAILED)
      name = "close-failed"
    case (FGOF_EXPECT_ERR_INTERNAL)
      name = "internal"
    case default
      name = "unknown"
    end select
  end function expect_error_name

  function spawn_expect(program, argv, options) result(session)
    character(len=*), intent(in) :: program
    character(len=*), intent(in), optional :: argv(:)
    type(expect_options), intent(in), optional :: options
    type(expect_session) :: session
    type(expect_options) :: resolved_options

    session = clear_expect_session()
    resolved_options = clear_expect_options()
    if (present(options)) resolved_options = options

    if (len_trim(program) == 0) then
      call set_error(session, FGOF_EXPECT_ERR_INVALID_COMMAND, "program must not be empty")
      return
    end if

    if (.not. valid_expect_options(resolved_options)) then
      call set_error(session, FGOF_EXPECT_ERR_INVALID_OPTIONS, &
        "expect options must use positive timeout and terminal size")
      return
    end if

    session%program = program
    session%pty = spawn_pty(program, argv, resolved_options%size)
    session%active = session%pty%is_open .and. session%pty%child_running

    if (session%pty%error_code /= 0) then
      call sync_pty_error(session)
      return
    end if
  end function spawn_expect

  logical function close_expect(session) result(success)
    type(expect_session), intent(inout) :: session

    call clear_error(session)

    if (session%pty%master_fd < 0 .and. session%pty%child_pid <= 0) then
      session%active = .false.
      success = .true.
      return
    end if

    success = close_pty(session%pty)
    session%active = session%pty%is_open .and. session%pty%child_running
    if (.not. success) then
      call set_error(session, FGOF_EXPECT_ERR_CLOSE_FAILED, expect_pty_message(session%pty, "failed to close expect session"))
      return
    end if

    session%active = .false.
  end function close_expect

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

  logical function valid_expect_options(options) result(valid)
    type(expect_options), intent(in) :: options

    valid = options%timeout_ms > 0 .and. options%size%rows > 0 .and. options%size%cols > 0
  end function valid_expect_options

  subroutine clear_error(session)
    type(expect_session), intent(inout) :: session

    session%error_code = FGOF_EXPECT_OK
    session%error_message = ""
  end subroutine clear_error

  subroutine set_error(session, code, message)
    type(expect_session), intent(inout) :: session
    integer, intent(in) :: code
    character(len=*), intent(in) :: message

    session%error_code = code
    session%error_message = message
    session%active = .false.
  end subroutine set_error

  subroutine sync_pty_error(session)
    type(expect_session), intent(inout) :: session
    integer :: mapped_code

    mapped_code = map_pty_error(session%pty%error_code)
    call set_error(session, mapped_code, expect_pty_message(session%pty, "pty backend reported an error"))
  end subroutine sync_pty_error

  integer function map_pty_error(code) result(mapped)
    integer, intent(in) :: code

    select case (code)
    case (FGOF_PTY_ERR_INVALID_COMMAND)
      mapped = FGOF_EXPECT_ERR_INVALID_COMMAND
    case (FGOF_PTY_ERR_INVALID_SIZE)
      mapped = FGOF_EXPECT_ERR_INVALID_OPTIONS
    case (FGOF_PTY_ERR_SPAWN_FAILED, FGOF_PTY_ERR_EXEC_FAILED)
      mapped = FGOF_EXPECT_ERR_SPAWN_FAILED
    case (FGOF_PTY_ERR_CLOSE_FAILED)
      mapped = FGOF_EXPECT_ERR_CLOSE_FAILED
    case (FGOF_PTY_ERR_INTERNAL)
      mapped = FGOF_EXPECT_ERR_INTERNAL
    case default
      mapped = FGOF_EXPECT_ERR_INTERNAL
    end select
  end function map_pty_error

  function expect_pty_message(session, fallback) result(message)
    use fgof_pty_types, only : pty_session
    type(pty_session), intent(in) :: session
    character(len=*), intent(in) :: fallback
    character(len=:), allocatable :: message

    if (allocated(session%error_message)) then
      if (len(session%error_message) > 0) then
        message = session%error_message
        return
      end if
    end if

    message = fallback
  end function expect_pty_message

end module fgof_expect
