;; Song and Sound Effect ca65 enums for example-project.terrificaudio.
;;
;; Automatically generated using `tad-compiler ca65-enums` or `tad-compiler ca65-export`.
;;
;; This file MUST BE recreated if song list or sound effect export order changes.
;;


LAST_SONG_ID = 47
N_SOUND_EFFECTS = 19

;; Song enum.
;; Input argument for `Tad_LoadSong`
.enum Song
  BLANK = 0 ; blank (silent) song
  gimo_297 = 1
  ode_to_joy = 2
  chords = 3
  chords_transpose = 4
  test_broken_chord = 5
  quantize_with_temp_gain = 6
  early_release = 7
  invert = 8
  test_echo = 9
  test_set_echo_delay = 10
  test_fir = 11
  test_envelope = 12
  test_loop = 13
  test_loop_stack = 14
  test_pan = 15
  test_portamento = 16
  test_samples = 17
  test_song_loop = 18
  test_subroutine_play_at_cursor = 19
  tremolo = 20
  test_vibrato = 21
  test_echo_invert = 22
  test_bc_asm_in_mml = 23
  pan_slide = 24
  panbrello = 25
  pitch_modulation = 26
  play_noise = 27
  play_pitch = 28
  volume_slide = 29
  multi_channel_noise = 30
  detune = 31
  volume_pop_bug = 32
  keyoff_scrn_bug = 33
  envelope_race_condition = 34
  subroutine_vibrato_bug = 35
  portamento_first_tick_bugtest = 36
  tremolo_underflow_bug = 37
  volume_slide_down_bug = 38
  noise_and_sfx_test = 39
  two_channels_modify_timer = 40
  subroutine_cursor_tick_count_bug = 41
  early_release_and_temp_gain = 42
  echo_stress_test = 43
  adjust_echo_i8_limit = 44
  large_skip_last_loop = 45
  unbalanced_vibrato_bug = 46
  vibrato_after_portamento = 47
.endenum


;; Sound Effects enum.
;; Input argument for `Tad_QueueSoundEffect` and `Tad_QueuePannedSoundEffect`
.enum SFX
  ; high-priority sound effects
  player_hurt_low_health = 0
  ; normal-priority sound effects
  menu_cursor = 1
  menu_select = 2
  menu_incorrect = 3
  player_hurt = 4
  jump = 5
  vibrato_alarm = 6
  play_samples_bytecode = 7
  spawn_item = 8
  collect_coin = 9
  robot_notices_player = 10
  robot_ascend = 11
  robot_fires_laser = 12
  fire_arrow = 13
  noise = 14
  sfx_calling_subroutine_asm = 15
  sfx_calling_subroutine_mml = 16
  ; low-priority sound effects
  low_priority_beep = 17
  low_priority_long = 18
.endenum
