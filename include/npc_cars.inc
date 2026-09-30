NUM_NPC_CARS = 4

.enum NpcCarFlags
  ACTIVE = $80
  VISIBLE = $40
  CIVILIAN = $01
.endenum

.enum RoadTetherDirections
  LEFT = $00
  RIGHT = $FF
.endenum

.code

.global npc_cars_init
.global npc_cars_update
.global npc_cars_draw

.global enemy_update
.global civilian_update

.global enemy_car_sprite, civilian_car_sprite

.global enemy_car_chr_0
.global enemy_car_chr_1
.global enemy_car_chr_2

.global civilian_car_chr_0
.global civilian_car_chr_1
.global civilian_car_chr_2
