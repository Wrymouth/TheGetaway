.include "common.inc"
.include "npc_cars.inc"
.include "sprites.inc"

.code

.proc civilian_update
  RTS
.endproc

civilian_car_sprite:
NEXXT_SPRITE 0,    0, $12, 1
NEXXT_SPRITE 0,    8, $13, 1
NEXXT_SPRITE 0,   16, $14, 1
NEXXT_SPRITE 8,    8, $13, 1 | OAM_FLAG_FLIP_H
NEXXT_SPRITE 8,    0, $12, 1 | OAM_FLAG_FLIP_H
NEXXT_SPRITE 8,   16, $14, 1 | OAM_FLAG_FLIP_H

civilian_car_chr_0:
  .incbin "civilian_car_0.chr"
civilian_car_chr_1:
  .incbin "civilian_car_1.chr"
civilian_car_chr_2:
  .incbin "civilian_car_2.chr"
