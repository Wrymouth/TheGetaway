.include "common.inc"
.include "player.inc"
.include "level.inc"
.include "camera.inc"
.include "controller.inc"
.include "sprites.inc"

.zeropage
player_x: .res 2
player_y: .res 2
player_vel_x: .res 2
player_vel_y: .res 2
player_health: .res 2
.code

.proc player_init
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
  SUB16_L player_health, #$10
  BCS :+
    LDA #PLAYER_MAX_HEALTH
    STA player_health+1
    LDA #$00
    STA player_health
  :

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

  ; JSR player_wrap_x

  LDA player_y+1
  CMP #LEVEL_LENGTH
  BCC :+
    LDA #LEVEL_LENGTH
    CLC
    ADC player_y+1
    STA player_y+1
  :

  ; handle collision

  RTS
.endproc

.proc player_accel
  LDA player_vel_y
  SEC
  SBC #<PLAYER_ACCEL
  STA player_vel_y
  LDA player_vel_y+1
  SBC #>PLAYER_ACCEL
  STA player_vel_y+1
  RTS
.endproc

.proc player_decel
  LDA player_vel_y
  CLC
  ADC #<PLAYER_DECEL
  STA player_vel_y
  LDA player_vel_y+1
  ADC #>PLAYER_DECEL
  STA player_vel_y+1
  RTS
.endproc

.proc player_accel_left
  LDA player_vel_x
  SEC
  SBC #<PLAYER_ACCEL_X
  STA player_vel_x
  LDA player_vel_x+1
  SBC #>PLAYER_ACCEL_X
  STA player_vel_x+1

  ; if the car wasn't moving forward much, start accelerating it now
  ; we're currently ignoring the high byte, because it's 0 for the constant
  LDA player_vel_y+1
  BEQ accel
  CMP #>-PLAYER_MAX_TURN_VEL
  BEQ compare_lsb
  BCS accel
  JMP done
compare_lsb:
  LDA player_vel_y
  CMP #<-PLAYER_MAX_TURN_VEL
  BCC done
accel:
  JSR player_accel

done:
  RTS
.endproc

.proc player_accel_right
  LDA player_vel_x
  CLC
  ADC #<PLAYER_ACCEL_X
  STA player_vel_x
  LDA player_vel_x+1
  ADC #>PLAYER_ACCEL_X
  STA player_vel_x+1

  ; if the car wasn't moving forward much, start accelerating it now
  ; we're currently ignoring the high byte, because it's 0 for the constant
  LDA player_vel_y+1
  BEQ accel
  CMP #>-PLAYER_MAX_TURN_VEL
  BEQ compare_lsb
  BCS accel
  JMP done
compare_lsb:
  LDA player_vel_y
  CMP #<-PLAYER_MAX_TURN_VEL
  BCC done
accel:
  JSR player_accel
done:
  RTS
.endproc

.proc player_decel_left
  LDA player_vel_x
  CLC
  ADC #<PLAYER_X_DRAG
  STA player_vel_x
  LDA player_vel_x+1
  ADC #>PLAYER_X_DRAG
  STA player_vel_x+1
  ; check if we've switched sides and set to 0 if so
  LDA player_vel_x+1
  BMI done
set_vel_0:
  LDA #$00
  STA player_vel_x
  STA player_vel_x+1
done:
  RTS
.endproc

.proc player_decel_right
  LDA player_vel_x
  SEC
  SBC #<PLAYER_X_DRAG
  STA player_vel_x
  LDA player_vel_x+1
  SBC #>PLAYER_X_DRAG
  STA player_vel_x+1
  ; check if we've switched sides and set to 0 if so
  LDA player_vel_x+1
  BPL done
set_vel_0:
  LDA #$00
  STA player_vel_x
  STA player_vel_x+1
done:
  RTS
.endproc


.proc player_limit_vel_pos
  LDA player_vel_y+1
  CMP #$00
  BEQ compare_lsb
  BCS set_max_vel
  JMP done
compare_lsb:
  LDA player_vel_y
  CMP #$00
  BCC done
set_max_vel:
  LDA #$00
  STA player_vel_y
  LDA #$00
  STA player_vel_y+1
done:
  RTS
.endproc

.proc player_limit_vel_neg
  LDA player_vel_y+1
  CMP #>-PLAYER_MAX_VEL_Y
  BEQ compare_lsb
  BCS done
  JMP set_max_vel
compare_lsb:
  LDA player_vel_y
  CMP #<-PLAYER_MAX_VEL_Y
  BCS done
set_max_vel:
  LDA #<-PLAYER_MAX_VEL_Y
  STA player_vel_y
  LDA #>-PLAYER_MAX_VEL_Y
  STA player_vel_y+1
done:
  RTS
.endproc

.proc player_limit_vel_left
  LDA player_vel_x+1
  CMP #>-PLAYER_MAX_VEL_X
  BEQ compare_lsb
  BCS set_max_vel
  JMP done
compare_lsb:
  LDA player_vel_x
  CMP #<-PLAYER_MAX_VEL_X
  BCS done
set_max_vel:
  LDA #<-PLAYER_MAX_VEL_X
  STA player_vel_x
  LDA #>-PLAYER_MAX_VEL_X
  STA player_vel_x+1
done:
  RTS
.endproc

.proc player_limit_vel_right
  LDA player_vel_x+1
  CMP #>PLAYER_MAX_VEL_X
  BEQ compare_lsb
  BCS set_max_vel
  JMP done
compare_lsb:
  LDA player_vel_x
  CMP #<PLAYER_MAX_VEL_X
  BCC done
set_max_vel:
  LDA #<PLAYER_MAX_VEL_X
  STA player_vel_x
  LDA #>PLAYER_MAX_VEL_X
  STA player_vel_x+1
done:
  RTS
.endproc

.proc player_move_x
  LDA player_x
  CLC
  ADC player_vel_x
  STA player_x
  LDA player_x+1
  ADC player_vel_x+1
  STA player_x+1
  RTS
.endproc

.proc player_move_y
  LDA player_y
  CLC
  ADC player_vel_y
  STA player_y
  LDA player_y+1
  ADC player_vel_y+1
  STA player_y+1
  RTS
.endproc

.proc player_wrap_x
  LDA player_x+1
  BMI wrap_negative
  CMP #LEVEL_TOTAL_WIDTH
  BCS wrap_positive
  JMP done
wrap_positive:
  SEC
  SBC #LEVEL_TOTAL_WIDTH
  STA player_x+1
  JMP done
wrap_negative:
  CLC
  ADC #LEVEL_TOTAL_WIDTH
  STA player_x+1
done:
  RTS
.endproc


.proc player_get_screen_coords
  player_x_camera := locals+0 ; 2 bytes
  player_y_camera := locals+2 ; 2 bytes
  temp_camera_y := locals+4 ; 1 byte, just the high
  sprite_x := locals+11
  sprite_y := locals+12


  ; wait! what if camera_y is *greater* than player_y?
  ; when wrapping, that is a thing that may happen.

  LDA player_y+1
  CMP camera_y+1
  BCS :+
    LDA camera_y+1
    SEC
    SBC #LEVEL_LENGTH
    STA temp_camera_y
    JMP sub_y
  :
  LDA camera_y+1
  STA temp_camera_y
sub_y:
  ; subtract camera position
  LDA player_y
  SEC
  SBC camera_y
  STA player_y_camera

  LDA player_y+1
  SBC temp_camera_y
  STA player_y_camera+1

  LDA player_x
  SEC
  SBC camera_x
  STA player_x_camera
  LDA player_x+1
  SBC camera_x+1
  STA player_x_camera+1

  ; convert world pos to screen pos
  LDA player_y_camera+1
  LSHIFT 3
  STA sprite_y
  LDA player_y_camera
  RSHIFT 5
  ORA sprite_y
  STA sprite_y

  LDA player_x_camera+1
  LSHIFT 3
  STA sprite_x
  LDA player_x_camera
  RSHIFT 5
  ORA sprite_x
  STA sprite_x


  RTS
.endproc

.proc player_draw
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes

  ; get screen coords
  JSR player_get_screen_coords ; this sets sprite_x and sprite_y

  LDA #$00
  STA sprite_attr

  LDA player_sprite_idle
  STA size
  LDA #<(player_sprite_idle+1)
  STA sprite_ptr
  LDA #>(player_sprite_idle+1)
  STA sprite_ptr+1
  JSR draw_sprite_dynamic
  RTS
.endproc

player_sprites:

player_sprite_idle:
.byte 24 ; size
NEXXT_SPRITE 0,   0,$00,0
NEXXT_SPRITE 8,   0,$00,0|OAM_FLAG_FLIP_H
NEXXT_SPRITE 0,   8,$01,0
NEXXT_SPRITE 8,   8,$01,0|OAM_FLAG_FLIP_H
NEXXT_SPRITE 0,  16,$02,0
NEXXT_SPRITE 8,  16,$02,0|OAM_FLAG_FLIP_H

player_chr:

player_chr_idle_0:
  .incbin "player/player_idle_0.chr"
player_chr_idle_1:
  .incbin "player/player_idle_1.chr"
player_chr_idle_2:
  .incbin "player/player_idle_2.chr"