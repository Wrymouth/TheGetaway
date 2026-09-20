; player position is Q11.5
; 8 bits "tile position", 3 bits "pixel position", 5 bits "subpixel position"

PLAYER_MAX_SPEED = 8
PLAYER_ACCEL = 2

PLAYER_INITIAL_POS = $5800

.code
.global player_update