.include "common.inc"
.include "game_states.inc"
.include "camera.inc"
.include "player.inc"
.include "npc_cars.inc"
.include "shot.inc"
.include "level.inc"
.include "chr_allocator.inc"
.include "hud.inc"

.code 

.proc game_state_game
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  LDA pad1_first_pressed
  AND #BTN_START
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::PAUSED
    STA game_status_flags
  :

  LDA game_status_flags
  AND #GameStatusFlags::PAUSED
  BNE draw
  JSR player_update
  JSR npc_cars_update
  JSR shots_update
  
  LDA #FALSE
  JSR camera_update
  JSR level_update

  JSR hud_update
draw:
  JSR level_draw_row
  JSR write_chr_row
  
  JSR player_draw
  JSR npc_cars_draw
  JSR shots_draw
  JSR hud_draw
  RTS
.endproc