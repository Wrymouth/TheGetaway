; player position is Q11.5
; 8 bits "tile position", 3 bits "pixel position", 5 bits "subpixel position"

PLAYER_MAX_VEL_Y = $00FE
PLAYER_ACCEL = $0002

PLAYER_INITIAL_POS_X = $0F00
PLAYER_INITIAL_POS_Y = $3A00

PLAYER_VEL_X = $0020

.zeropage
.globalzp player_x, player_y

.code
.global player_init
.global player_update
.global player_draw