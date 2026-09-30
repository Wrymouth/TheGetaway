.include "common.inc"
.include "npc_cars.inc"
.include "sprites.inc"

.code

.proc enemy_update
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
  .incbin "enemy_car_0.chr"
enemy_car_chr_1:
  .incbin "enemy_car_1.chr"
enemy_car_chr_2:
  .incbin "enemy_car_2.chr"
