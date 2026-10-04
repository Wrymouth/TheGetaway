.include "common.inc"
.include "player.inc"
.include "player_internal.inc"
.include "controller.inc"
.include "level.inc"
.include "shot.inc"
.include "score.inc"

.zeropage
  player_x: .res 2
  player_y: .res 2
  player_vel_x: .res 2
  player_vel_y: .res 2
  player_health: .res 2
  player_flags: .res 1
  player_y_prev: .res 1
.code

.proc player_init
  LDA #$00
  STA player_y_prev
  LDA #<PLAYER_INITIAL_POS_X
  STA player_x
  LDA #>PLAYER_INITIAL_POS_X
  STA player_x+1
  LDA #<PLAYER_INITIAL_POS_Y
  STA player_y
  LDA #>PLAYER_INITIAL_POS_Y
  STA player_y+1
  LDA #$00
  STA player_vel_x
  STA player_vel_x+1
  STA player_vel_y
  STA player_vel_y+1
  STA player_health
  LDA #PLAYER_MAX_HEALTH
  STA player_health+1
  RTS
.endproc

.proc player_update
  LDA player_y+1
  STA player_y_prev
  LDA pad1_pressed
  AND #BTN_UP
  BEQ :+
    JSR player_accel
  :
  LDA pad1_pressed
  AND #BTN_DOWN
  BEQ :+
    JSR player_decel
  :

  LDA pad1_pressed
  AND #BTN_LEFT
  BEQ :+
    JSR player_accel_left
    JMP limit_vel_y
  :
check_right:
  LDA pad1_pressed
  AND #BTN_RIGHT
  BEQ :+
    JSR player_accel_right
    JMP limit_vel_y
  : 

decel_x:
  LDA player_vel_x+1
  BPL :+
    JSR player_decel_left
    JMP limit_vel_y
  :
  JSR player_decel_right

limit_vel_y:
  LDA player_vel_y+1
  BPL :+
    JSR player_limit_vel_neg
    JMP limit_vel_x
  :

  JSR player_limit_vel_pos
  ; stop any attempt at steering from here
  LDA #$00
  STA player_vel_x
  STA player_vel_x+1

limit_vel_x:
  LDA player_vel_x+1
  BPL :+
    JSR player_limit_vel_left
    JMP move
  :
  JSR player_limit_vel_right
move:
  JSR player_move_x
  JSR player_move_y

  JSR player_wrap_x

  LDA player_y+1
  CMP #LEVEL_LENGTH
  BCC :+
    LDA #LEVEL_LENGTH
    CLC
    ADC player_y+1
    STA player_y+1
  :

  LDA player_y_prev
  CMP player_y+1
  BEQ :+
    JSR add_score
    LDA player_flags
    ORA #PlayerFlags::HAS_MOVED
    STA player_flags
    JMP collide
  :
  LDA player_flags
  AND #<~PlayerFlags::HAS_MOVED
  STA player_flags
collide:
  JSR player_collide_with_grass

shoot:
  LDA pad1_pressed
  AND #BTN_B
  BEQ :+
    JSR shot_create
  :

  RTS
.endproc
