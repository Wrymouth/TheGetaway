LEVEL_MIN_WIDTH = 10
LEVEL_MAX_WIDTH = 16
LEVEL_TOTAL_WIDTH = 32

LEVEL_ROW_SIZE = 4 ; bytes in a single level row
LEVEL_LENGTH = 60 ; two vertical nametables

; level format is 
; 1 byte - road start
; 1 byte - road end
; 1 byte - flags
; 1 byte - reserved

.enum LevelFlags
  DRAW_LEFT_SLANT_LEFT = $80
  DRAW_RIGHT_SLANT_LEFT = $40
  DRAW_LEFT_SLANT_RIGHT = $20
  DRAW_RIGHT_SLANT_RIGHT = $10
.endenum

.code

.global init_level
.global draw_initial_level
