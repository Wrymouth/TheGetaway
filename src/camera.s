.include "common.inc"
.include "camera.inc"
.include "player.inc"
.include "level.inc"

.zeropage
camera_x: .res 2
camera_y: .res 2
camera_vel_x: .res 2
camera_vel_y: .res 2
scroll_x: .res 1
scroll_y: .res 1

.code

.proc camera_init
  LDA #$00
  STA camera_x
  STA camera_x+1
  STA camera_y
  STA camera_y+1
  STA camera_vel_x
  STA camera_vel_x+1
  STA camera_vel_y
  STA camera_vel_y+1
  STA scroll_x
  STA scroll_y
  LDA #TRUE
  JSR camera_update
  RTS
.endproc

.proc camera_update
  CAMERA_PLAYER_OFFSET_X = $10
  CAMERA_PLAYER_OFFSET_Y = $10

  camera_goal_x := locals+0 ; 1 byte, just msb
  camera_goal_offset_x := locals+1 ; 2 bytes
  move_instantly:= locals+3

  STA move_instantly

  ; follow the player on the Y axis, the road on the X axis
  LDA player_y
  STA camera_y
  LDA player_y+1
  SEC
  SBC #CAMERA_PLAYER_OFFSET_Y
  STA camera_y+1

  LDA camera_y+1
  CMP #LEVEL_LENGTH
  BCC :+
    LDA #LEVEL_LENGTH
    CLC
    ADC camera_y+1
    STA camera_y+1
  :

  ; that was Y, now comes X
  ; we want the road to be centered on the screen at the player's Y position
  ; this means we must calculate where the center of the road is at that point
  ;
  ; the road always has the same number of horizontal tiles, namely 32.
  ; the amount of grass tiles is total_tiles - (road_end - road_start)
  ; the amount of grass on the left is half of that
  ; camera is top left, so we want to place the camera X at road_start - half_grass
  ; alternatively, place the camera at road_start + (road_width/2) - 16
  LDX player_y+1

  LDA level_start,x
  CMP level_end,x
  BCS wrapped
regular:
  ; road width
  LDA level_end,x
  SEC
  SBC level_start,x
  CLC
  ADC #$01 ; road start inclusive
  LSR ; div 2
  CLC
  ADC level_start,x
  SEC
  SBC #LEVEL_TOTAL_WIDTH/2
  STA camera_goal_x
  JMP check_camera_goal_wrap_x
wrapped:
  ; road width
  LDA level_end,x
  CLC
  ADC #LEVEL_TOTAL_WIDTH
  SEC
  SBC level_start,x
  CLC
  ADC #$01 ; road start inclusive
  LSR ; div 2
  CLC
  ADC level_start,x
  SEC
  SBC #LEVEL_TOTAL_WIDTH/2
  STA camera_goal_x
check_camera_goal_wrap_x:
  LDA camera_goal_x
  BMI wrap_goal_negative
  CMP #LEVEL_TOTAL_WIDTH
  BCS wrap_goal_positive
  JMP set_camera_x
wrap_goal_positive:
  SEC
  SBC #LEVEL_TOTAL_WIDTH
  STA camera_goal_x
  JMP set_camera_x
wrap_goal_negative:
  CLC
  ADC #LEVEL_TOTAL_WIDTH
  STA camera_goal_x
set_camera_x:
  LDA move_instantly
  JSR camera_move_x

set_scroll:
  JSR camera_to_scroll

  RTS
.endproc

.proc camera_move_x
  camera_goal_x := locals+0 ; 1 byte, just msb
  camera_goal_offset_x := locals+1 ; 2 bytes
  move_instantly:= locals+3
  
  BNE set_camera_to_goal_x

  ; now, where is camera_goal_x relative to camera_x? is it to the left or to the right?
  ; camera_x(+1) will never be negative at this stage, because it will have been wrapped
  ; so if camera_goal_x is negative, we know it's to the left
  SEC
  LDA #$00
  SBC camera_x
  STA camera_goal_offset_x
  LDA camera_goal_x
  SBC camera_x+1
  STA camera_goal_offset_x+1
  BEQ check_lsb
  BCS positive
  JMP negative
check_lsb:
  LDA camera_goal_offset_x
  BEQ done
  BCS positive
negative:
  LDA camera_goal_offset_x+1
  CMP #-(LEVEL_TOTAL_WIDTH/2)
  BCS move_left
  JMP move_right
positive:
  LDA camera_goal_offset_x+1
  CMP #(LEVEL_TOTAL_WIDTH/2)
  BCS move_left
  JMP move_right
move_left:
  SEC
  LDA camera_x
  SBC #<CAMERA_VEL_X
  STA camera_x
  LDA camera_x+1
  SBC #>CAMERA_VEL_X
  STA camera_x+1
  JMP wrap
move_right:
  CLC
  LDA camera_x
  ADC #<CAMERA_VEL_X
  STA camera_x
  LDA camera_x+1
  ADC #>CAMERA_VEL_X
  STA camera_x+1
  JMP wrap
set_camera_to_goal_x:
  LDA camera_goal_x
  STA camera_x+1
  LDA #$00
  STA camera_x

wrap:
  LDA camera_x+1
  CMP #LEVEL_TOTAL_WIDTH
  BCC done

  LDA #LEVEL_TOTAL_WIDTH
  CLC
  ADC camera_x+1
  STA camera_x+1
  
done:
  RTS
.endproc

.proc camera_to_scroll
  LDA camera_x+1
  LSHIFT 3
  STA scroll_x
  LDA camera_x
  RSHIFT 5
  ORA scroll_x
  STA scroll_x

  LDA camera_y+1
  LSHIFT 3
  STA scroll_y
  LDA camera_y
  RSHIFT 5
  ORA scroll_y
  STA scroll_y

  LDA camera_y+1
  CMP #LEVEL_LENGTH/2
  BCS set_nametable_y_1
set_nametable_y_0:
  LDA ppuctrl_settings
  AND #<~PPUCTRL_NAMETABLE_Y
  JMP done
set_nametable_y_1:
  LDA scroll_y
  CLC
  ADC #$10
  STA scroll_y
  LDA ppuctrl_settings
  ORA #PPUCTRL_NAMETABLE_Y
done:
  STA ppuctrl_settings
  RTS
.endproc
