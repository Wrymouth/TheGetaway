.include "common.inc"
.include "game_states.inc"
.include "camera.inc"
.include "player.inc"
.include "level.inc"
.include "chr_allocator.inc"
.include "hud.inc"

.proc game_state_game
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  JSR player_update

  LDA #FALSE
  JSR camera_update
  JSR level_update

  JSR hud_update

  JSR level_draw_row
  JSR write_chr_row
  
  JSR player_draw
  JSR hud_draw
  RTS
.endproc