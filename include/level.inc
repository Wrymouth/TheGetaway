LEVEL_MIN_WIDTH = 7
LEVEL_MAX_WIDTH = 16
LEVEL_TOTAL_WIDTH = 32

INITIAL_ROAD_START = 9
INITIAL_ROAD_WIDTH = 13

LEVEL_ROW_SIZE = 4 ; bytes in a single level row
LEVEL_LENGTH = 60 ; two vertical nametables
LEVEL_TOTAL_BYTES = LEVEL_LENGTH * 4

LEVEL_BACKGROUND_BANK_SIZE = 64

SCROLL_SEAM_OFFSET = $01

; level format is 
; 1 byte - road start
; 1 byte - road end
; 1 byte - flags
; 1 byte - reserved

.enum LevelFlags
  DRAW_LEFT_SLANT_LEFT   = $80
  DRAW_RIGHT_SLANT_LEFT  = $40
  DRAW_LEFT_SLANT_RIGHT  = $20
  DRAW_RIGHT_SLANT_RIGHT = $10
  ROW_CONTAINS_CHR       = $08
  ROW_WAS_GENERATED      = $04
.endenum

.segment "LEVEL" :bss :mem $0300 :size $0100
.global level_start
.global level_end
.global level_flags
.global level_reserved

.code

.global does_row_contain_chr

.global level_init
.global level_update
.global level_draw_row

.global level_draw_initial
.global level_write_palettes
