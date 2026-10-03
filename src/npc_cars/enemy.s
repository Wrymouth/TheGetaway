.include "common.inc"
.include "npc_cars.inc"
.include "level.inc"
.include "sprites.inc"

.code

ENEMY_SPEED = $00C0
ENEMY_HEALTH = 40


.proc enemy_update
  SEC
  LDA npc_car_y_lo,x
  SBC #<ENEMY_SPEED
  STA npc_car_y_lo,x 
  LDA npc_car_y_hi,x
  SBC #>ENEMY_SPEED
  STA npc_car_y_hi,x
  ; wrap
  BCS :+
    CLC
    ADC #LEVEL_LENGTH
  :
  STA npc_car_y_hi,x
  RTS
.endproc

enemy_car_sprite:
  NEXXT_SPRITE 0,    0, $0f, 0
  NEXXT_SPRITE 8,    8, $10, 2 | OAM_FLAG_FLIP_H
  NEXXT_SPRITE 0,    8, $10, 0
  NEXXT_SPRITE 0,   16, $11, 0
  NEXXT_SPRITE 8,    0, $0f, 0 | OAM_FLAG_FLIP_H
  NEXXT_SPRITE 8,   16, $11, 0 | OAM_FLAG_FLIP_H

enemy_car_chr_0:
  .incbin "cars/enemy_car_0.chr"
enemy_car_chr_1:
  .incbin "cars/enemy_car_1.chr"
enemy_car_chr_2:
  .incbin "cars/enemy_car_2.chr"
