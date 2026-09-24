; player position is Q11.5
; 8 bits "tile position", 3 bits "pixel position", 5 bits "subpixel position"

PLAYER_MAX_VEL_Y = $00FF
PLAYER_ACCEL = $0002

PLAYER_INITIAL_POS_X = $0F00
PLAYER_INITIAL_POS_Y = $39FF

PLAYER_ACCEL_X = $0009
PLAYER_MAX_VEL_X = $0030
PLAYER_X_DRAG  = $000A

PLAYER_MAX_TURN_VEL = PLAYER_MAX_VEL_X ; the max forward velocity when driving sideways

.zeropage
.globalzp player_x, player_y

.code
.global player_init
.global player_update
.global player_draw
.global player_chr_idle_0
.global player_chr_idle_1
.global player_chr_idle_2