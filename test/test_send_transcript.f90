program test_send_transcript
  use fgof_expect, only : &
    FGOF_EXPECT_STATUS_MATCHED, &
    clear_expect_options, &
    clear_transcript, &
    close_expect, &
    last_expect_match, &
    send_line, &
    send_text, &
    spawn_expect, &
    transcript_text, &
    wait_for_string
  use fgof_expect_types, only : expect_match, expect_options, expect_session
  implicit none

  type(expect_options) :: options
  type(expect_session) :: session
  type(expect_match) :: match
  character(len=96) :: argv(2)
  character(len=:), allocatable :: transcript

  options = clear_expect_options()
  options%timeout_ms = 500

  argv = ""
  argv(1) = "-c"
  argv(2) = 'printf ''READY\n''; while IFS= read -r line; do printf ''ACK:%s\n'' "$line"; done'
  session = spawn_expect("sh", argv, options)

  match = wait_for_string(session, "READY")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "session should announce readiness"

  if (.not. send_line(session, "hello")) error stop "send_line should write into the PTY"
  match = wait_for_string(session, "ACK:hello")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "response to send_line should match"

  transcript = transcript_text(session)
  if (index(transcript, "READY") <= 0) error stop "transcript should retain prior output"
  if (index(transcript, "ACK:hello") <= 0) error stop "transcript should include matched responses"

  match = last_expect_match(session)
  if (match%text /= "ACK:hello") error stop "last-match helper should expose the latest match"

  call clear_transcript(session)
  if (transcript_text(session) /= "") error stop "clear_transcript should reset transcript text"

  if (.not. send_text(session, "world")) error stop "send_text should support partial writes"
  if (.not. send_text(session, new_line("a"))) error stop "send_text should accept raw newline writes"
  match = wait_for_string(session, "ACK:world")
  if (match%status /= FGOF_EXPECT_STATUS_MATCHED) error stop "partial send_text writes should still round-trip"
  transcript = transcript_text(session)
  if (index(transcript, "ACK:world") <= 0) error stop "cleared transcript should still accumulate new responses"
  if (index(transcript, "READY") > 0) error stop "clear_transcript should drop earlier output"

  if (.not. close_expect(session)) error stop "interactive send session should close cleanly"
end program test_send_transcript
