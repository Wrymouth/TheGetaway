.include "common.inc"
.include "game_states.inc"
.include "player.inc"
.include "level.inc"

.proc game_state_enter_game
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :

  ; initialize level RAM to just straight roads for two screens
  ; draw initial background from level RAM and write CHR data
  JSR level_init
  JSR level_draw_initial

  LDA #GameStates::GAME
  JSR set_game_state

  LDA #%00011110
  STA ppumask_settings

  RTS
.endproc