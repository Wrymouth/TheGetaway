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
  RTS
.endproc

.proc camera_update
  CAMERA_PLAYER_OFFSET_X = $10
  CAMERA_PLAYER_OFFSET_Y = $10

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

  JSR camera_to_scroll

  RTS
.endproc

.proc camera_to_scroll
  LDA camera_x+1
  LSHIFT 5
  STA scroll_x
  LDA camera_x
  RSHIFT 3
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
