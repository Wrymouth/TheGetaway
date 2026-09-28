.include "common.inc"
.include "player.inc"
.include "player_internal.inc"
.include "level.inc"



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