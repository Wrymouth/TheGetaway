CAMERA_PLAYER_OFFSET_X = $0F00
CAMERA_PLAYER_OFFSET_Y = $1000

.zeropage
.globalzp camera_x, camera_y
.globalzp scroll_x, scroll_y

.code
.global camera_init
.global camera_update