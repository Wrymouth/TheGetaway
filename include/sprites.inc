OAM_ENTRY_SIZE = 4
OAM_OFFSET_FORWARD = $04
OAM_OFFSET_BACKWARD = $FC


; fixed OAM: health bar (5 tiles), lives (1 tile), score (3 tiles), foliage and road signs: (20 tiles)
; this means the dynamic OAM window starts at tile offset 29 (times 4)
NUM_SPRITES_HEALTH_BAR = 5
NUM_SPRITES_LIVES = 1
NUM_SPRITES_SCORE = 3

OAM_DYNAMIC_WINDOW_START = (NUM_SPRITES_HEALTH_BAR + NUM_SPRITES_LIVES + NUM_SPRITES_SCORE) * OAM_ENTRY_SIZE

.macro NEXXT_SPRITE posX, posY, tile, attr
  .byte posY, tile, attr, posX 
.endmacro

.code
.global clear_oam
.global set_dynamic_oam_direction
.global draw_sprite_fixed
.global draw_sprite_dynamic