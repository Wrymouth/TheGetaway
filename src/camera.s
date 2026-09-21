.include "camera.inc"

.zeropage
camera_x: .res 2
camera_y: .res 2
camera_vel_x: .res 2
camera_vel_y: .res 2


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
  RTS
.endproc

.proc camera_update
  ; follow the player on the Y axis, the road on the X axis
  RTS
.endproc