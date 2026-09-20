.include "camera.inc"

.zeropage
camera_x: .res 2
camera_y: .res 2
camera_vel_x: .res 2
camera_vel_y: .res 2


.code

.proc camera_init
  RTS
.endproc

.proc camera_update
  ; follow the player on the Y axis, the road on the X axis
  RTS
.endproc