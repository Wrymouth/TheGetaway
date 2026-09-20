.include "common.inc"
.include "player.inc"
.include "controller.inc"

.zeropage
player_x: .res 2
player_y: .res 2
player_vel_x: .res 2
player_vel_y: .res 2

.code

.proc player_init
  LDA #<PLAYER_INITIAL_POS
  STA player_x
  LDA #>PLAYER_INITIAL_POS
  STA player_x+1
  RTS
.endproc

.proc player_update
  LDA pad1_first_pressed
  AND #BTN_A
  RTS
.endproc

.proc player_draw
  RTS
.endproc