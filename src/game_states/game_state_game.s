.include "common.inc"
.include "game_states.inc"
.include "camera.inc"
.include "player.inc"

.proc game_state_game
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  JSR player_update
  JSR camera_update
  JSR player_draw
  RTS
.endproc