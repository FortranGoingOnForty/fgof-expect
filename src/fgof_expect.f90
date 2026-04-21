module fgof_expect
  use fgof_pty, only : &
    FGOF_PTY_ERR_CLOSE_FAILED, &
    FGOF_PTY_ERR_EXEC_FAILED, &
    FGOF_PTY_ERR_INTERNAL, &
    FGOF_PTY_ERR_INVALID_COMMAND, &
    FGOF_PTY_ERR_INVALID_SIZE, &
    FGOF_PTY_ERR_IO_FAILED, &
    FGOF_PTY_ERR_SPAWN_FAILED, &
    close_pty, &
    pty_backend_name, &
    read_some, &
    spawn_pty, &
    write_all
  use fgof_expect_types, only : &
    FGOF_EXPECT_ERR_CLOSE_FAILED, &
    FGOF_EXPECT_ERR_INTERNAL, &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    FGOF_EXPECT_ERR_INVALID_PATTERN, &
    FGOF_EXPECT_ERR_SPAWN_FAILED, &
    FGOF_EXPECT_ERR_SESSION_ENDED, &
    FGOF_EXPECT_OK, &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_MATCHED, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    expect_match, &
    expect_options, &
    expect_pattern, &
    expect_session
  implicit none
  private

  interface wait_for_match
    module procedure wait_for_match_strings
    module procedure wait_for_match_specs
  end interface

  public :: &
    FGOF_EXPECT_ERR_CLOSE_FAILED, &
    FGOF_EXPECT_ERR_INTERNAL, &
    FGOF_EXPECT_ERR_INVALID_COMMAND, &
    FGOF_EXPECT_ERR_INVALID_OPTIONS, &
    FGOF_EXPECT_ERR_INVALID_PATTERN, &
    FGOF_EXPECT_ERR_SPAWN_FAILED, &
    FGOF_EXPECT_ERR_SESSION_ENDED, &
    FGOF_EXPECT_OK, &
    FGOF_EXPECT_STATUS_ERROR, &
    FGOF_EXPECT_STATUS_IDLE, &
    FGOF_EXPECT_STATUS_MATCHED, &
    FGOF_EXPECT_STATUS_TIMEOUT, &
    clear_expect_match, &
    clear_expect_options, &
    clear_expect_session, &
    clear_transcript, &
    close_expect, &
    exact_pattern, &
    expect_match, &
    expect_options, &
    expect_pattern, &
    expect_session, &
    expect_backend_name, &
    expect_error_name, &
    expect_status_name, &
    last_expect_match, &
    send_line, &
    send_text, &
    transcript_text, &
    trimmed_pattern, &
    wait_for_match, &
    wait_for_string
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
    match%start_index = 0
    match%end_index = 0
    match%text = ""
  end function clear_expect_match

  function exact_pattern(text) result(pattern)
    character(len=*), intent(in) :: text
    type(expect_pattern) :: pattern

    pattern%text = text
    pattern%trim_trailing = .false.
  end function exact_pattern

  function trimmed_pattern(text) result(pattern)
    character(len=*), intent(in) :: text
    type(expect_pattern) :: pattern

    pattern%text = text
    pattern%trim_trailing = .true.
  end function trimmed_pattern

  function clear_expect_session() result(session)
    type(expect_session) :: session

    session%active = .false.
    session%options = clear_expect_options()
    session%scan_start = 1
    session%error_code = FGOF_EXPECT_OK
    session%error_message = ""
    session%last_match = clear_expect_match()
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
    case (FGOF_EXPECT_ERR_INVALID_PATTERN)
      name = "invalid-pattern"
    case (FGOF_EXPECT_ERR_SPAWN_FAILED)
      name = "spawn-failed"
    case (FGOF_EXPECT_ERR_CLOSE_FAILED)
      name = "close-failed"
    case (FGOF_EXPECT_ERR_SESSION_ENDED)
      name = "session-ended"
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
    session%options = resolved_options
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

  function wait_for_string(session, pattern, timeout_ms) result(match)
    type(expect_session), intent(inout) :: session
    character(len=*), intent(in) :: pattern
    integer, intent(in), optional :: timeout_ms
    type(expect_match) :: match
    type(expect_pattern) :: patterns(1)

    patterns(1) = exact_pattern(pattern)
    match = wait_for_match_specs(session, patterns, timeout_ms)
  end function wait_for_string

  function wait_for_match_strings(session, patterns, timeout_ms) result(match)
    type(expect_session), intent(inout) :: session
    character(len=*), intent(in) :: patterns(:)
    integer, intent(in), optional :: timeout_ms
    type(expect_match) :: match
    type(expect_pattern), allocatable :: pattern_specs(:)
    integer :: i

    allocate(pattern_specs(size(patterns)))
    do i = 1, size(patterns)
      pattern_specs(i) = trimmed_pattern(patterns(i))
    end do

    match = wait_for_match_specs(session, pattern_specs, timeout_ms)
  end function wait_for_match_strings

  logical function send_text(session, text) result(success)
    type(expect_session), intent(inout) :: session
    character(len=*), intent(in) :: text

    call clear_error(session)
    call sync_active_state(session)

    if (.not. session%pty%is_open) then
      call set_error(session, FGOF_EXPECT_ERR_SESSION_ENDED, "expect session is not open")
      success = .false.
      return
    end if

    success = write_all(session%pty, text)
    call sync_active_state(session)
    if (.not. success) then
      call sync_pty_error(session)
    end if
  end function send_text

  logical function send_line(session, text) result(success)
    type(expect_session), intent(inout) :: session
    character(len=*), intent(in) :: text

    success = send_text(session, text // new_line("a"))
  end function send_line

  subroutine clear_transcript(session)
    type(expect_session), intent(inout) :: session

    session%transcript = ""
    session%scan_start = 1
    session%last_match = clear_expect_match()
  end subroutine clear_transcript

  function transcript_text(session) result(text)
    type(expect_session), intent(in) :: session
    character(len=:), allocatable :: text

    if (allocated(session%transcript)) then
      text = session%transcript
    else
      text = ""
    end if
  end function transcript_text

  function last_expect_match(session) result(match)
    type(expect_session), intent(in) :: session
    type(expect_match) :: match

    match = session%last_match
  end function last_expect_match

  function wait_for_match_specs(session, patterns, timeout_ms) result(match)
    type(expect_session), intent(inout) :: session
    type(expect_pattern), intent(in) :: patterns(:)
    integer, intent(in), optional :: timeout_ms
    type(expect_match) :: match
    character(len=:), allocatable :: chunk
    integer :: limit_ms
    integer :: start_count
    integer :: current_count
    integer :: rate
    integer :: elapsed_ms

    call clear_error(session)
    call sync_active_state(session)
    match = clear_expect_match()
    session%last_match = clear_expect_match()

    if (.not. valid_patterns(patterns)) then
      call set_error(session, FGOF_EXPECT_ERR_INVALID_PATTERN, "at least one non-empty pattern is required")
      match%status = FGOF_EXPECT_STATUS_ERROR
      return
    end if

    if (present(timeout_ms)) then
      limit_ms = timeout_ms
    else
      limit_ms = session%options%timeout_ms
    end if

    if (limit_ms < 0) then
      call set_error(session, FGOF_EXPECT_ERR_INVALID_OPTIONS, "timeout must not be negative")
      match%status = FGOF_EXPECT_STATUS_ERROR
      return
    end if

    if (try_match_patterns(session, patterns, match)) return

    if (.not. session%pty%is_open) then
      call set_error(session, FGOF_EXPECT_ERR_SESSION_ENDED, "expect session is not open")
      match%status = FGOF_EXPECT_STATUS_ERROR
      return
    end if

    call system_clock(start_count, rate)
    do
      chunk = read_some(session%pty, 4096)
      call sync_active_state(session)

      if (session%pty%error_code /= 0) then
        call sync_pty_error(session)
        match%status = FGOF_EXPECT_STATUS_ERROR
        return
      end if

      if (len(chunk) > 0) then
        session%transcript = session%transcript // chunk
        if (try_match_patterns(session, patterns, match)) return
      end if

      if (session%pty%eof_reached .or. session%pty%completed .or. .not. session%pty%child_running) then
        call set_error(session, FGOF_EXPECT_ERR_SESSION_ENDED, "session ended before a pattern matched")
        match%status = FGOF_EXPECT_STATUS_ERROR
        return
      end if

      call system_clock(current_count)
      if (rate > 0) then
        elapsed_ms = int((real(current_count - start_count) / real(rate)) * 1000.0)
      else
        elapsed_ms = limit_ms + 1
      end if

      if (elapsed_ms > limit_ms) then
        match%status = FGOF_EXPECT_STATUS_TIMEOUT
        return
      end if

      call spin_wait(20)
    end do
  end function wait_for_match_specs

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

  logical function valid_patterns(patterns) result(valid)
    type(expect_pattern), intent(in) :: patterns(:)
    integer :: i

    valid = size(patterns) > 0
    if (.not. valid) return

    do i = 1, size(patterns)
      if (pattern_length(patterns(i)) > 0) then
        valid = .true.
        return
      end if
    end do
    valid = .false.
  end function valid_patterns

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
    if (code /= FGOF_EXPECT_OK) then
      session%active = session%pty%is_open .and. session%pty%child_running
    end if
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
    case (FGOF_PTY_ERR_IO_FAILED)
      mapped = FGOF_EXPECT_ERR_SESSION_ENDED
    case (FGOF_PTY_ERR_INTERNAL)
      mapped = FGOF_EXPECT_ERR_INTERNAL
    case default
      mapped = FGOF_EXPECT_ERR_INTERNAL
    end select
  end function map_pty_error

  subroutine sync_active_state(session)
    type(expect_session), intent(inout) :: session

    session%active = session%pty%is_open .and. session%pty%child_running
  end subroutine sync_active_state

  logical function try_match_patterns(session, patterns, match) result(found)
    type(expect_session), intent(inout) :: session
    type(expect_pattern), intent(in) :: patterns(:)
    type(expect_match), intent(inout) :: match
    character(len=:), allocatable :: search_text
    character(len=:), allocatable :: pattern_text
    integer :: i
    integer :: pattern_len
    integer :: relative_pos
    integer :: candidate_start
    integer :: best_start
    integer :: best_end
    integer :: best_pattern

    found = .false.
    if (.not. allocated(session%transcript)) session%transcript = ""
    if (len(session%transcript) == 0) return

    if (session%scan_start < 1) session%scan_start = 1
    if (session%scan_start > len(session%transcript)) return

    best_pattern = 0
    best_start = huge(0)
    best_end = 0
    search_text = normalize_for_match(session%transcript(session%scan_start:), session%options%case_sensitive)

    do i = 1, size(patterns)
      pattern_len = pattern_length(patterns(i))
      if (pattern_len <= 0) cycle

      pattern_text = normalize_for_match(pattern_text_value(patterns(i)), session%options%case_sensitive)
      relative_pos = index(search_text, pattern_text)
      if (relative_pos <= 0) cycle

      candidate_start = session%scan_start + relative_pos - 1
      if (candidate_start < best_start) then
        best_start = candidate_start
        best_end = candidate_start + pattern_len - 1
        best_pattern = i
      end if
    end do

    if (best_pattern == 0) return

    match%status = FGOF_EXPECT_STATUS_MATCHED
    match%pattern_index = best_pattern
    match%start_index = best_start
    match%end_index = best_end
    match%text = session%transcript(best_start:best_end)
    session%last_match = match
    session%scan_start = best_end + 1
    found = .true.
  end function try_match_patterns

  integer function pattern_length(pattern) result(length)
    type(expect_pattern), intent(in) :: pattern

    length = len(pattern_text_value(pattern))
  end function pattern_length

  function pattern_text_value(pattern) result(text)
    type(expect_pattern), intent(in) :: pattern
    character(len=:), allocatable :: text
    integer :: trimmed_len

    if (.not. allocated(pattern%text)) then
      text = ""
      return
    end if

    if (pattern%trim_trailing) then
      trimmed_len = len_trim(pattern%text)
      if (trimmed_len <= 0) then
        text = ""
      else
        text = pattern%text(:trimmed_len)
      end if
    else
      text = pattern%text
    end if
  end function pattern_text_value

  function normalize_for_match(text, case_sensitive) result(normalized)
    character(len=*), intent(in) :: text
    logical, intent(in) :: case_sensitive
    character(len=:), allocatable :: normalized

    if (case_sensitive) then
      normalized = text
    else
      normalized = lower_ascii(text)
    end if
  end function normalize_for_match

  function lower_ascii(text) result(lowered)
    character(len=*), intent(in) :: text
    character(len=:), allocatable :: lowered
    integer :: i
    integer :: code

    lowered = text
    do i = 1, len(lowered)
      code = iachar(lowered(i:i))
      if (code >= iachar("A") .and. code <= iachar("Z")) then
        lowered(i:i) = achar(code + 32)
      end if
    end do
  end function lower_ascii

  subroutine spin_wait(duration_ms)
    integer, intent(in) :: duration_ms
    integer :: start_count
    integer :: current_count
    integer :: rate
    integer :: elapsed_ms

    if (duration_ms <= 0) return

    call system_clock(start_count, rate)
    if (rate <= 0) return

    do
      call system_clock(current_count)
      elapsed_ms = int((real(current_count - start_count) / real(rate)) * 1000.0)
      if (elapsed_ms >= duration_ms) exit
    end do
  end subroutine spin_wait

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
