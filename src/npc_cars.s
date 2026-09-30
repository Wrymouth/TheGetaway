.include "common.inc"
.include "player.inc"
.include "npc_cars.inc"
.include "level.inc"

.zeropage
  npc_car_flags: .res NUM_NPC_CARS
  npc_car_x_lo: .res NUM_NPC_CARS
  npc_car_x_hi: .res NUM_NPC_CARS
  npc_car_y_lo: .res NUM_NPC_CARS
  npc_car_y_hi: .res NUM_NPC_CARS
  npc_car_vel_x_lo: .res NUM_NPC_CARS
  npc_car_vel_x_hi: .res NUM_NPC_CARS
  npc_car_vel_y_lo: .res NUM_NPC_CARS
  npc_car_vel_y_hi: .res NUM_NPC_CARS
  npc_car_health: .res NUM_NPC_CARS

  time_to_next_car: .res 1
  road_tether_dir: .res 1 ; flips with every car
.code

.proc npc_cars_init
  .repeat NUM_NPC_CARS, i
    LDA #$00
    STA npc_car_flags+i
  .endrepeat
  RTS
.endproc

.proc check_car_spawn
  LDX #NUM_NPC_CARS-1
loop:
  LDA npc_car_flags,x
  BPL check_spawn_timer
load_next:
  DEX
  BNE loop
  JMP done ; no slots left

check_spawn_timer:
  ; only advance timer if you've moved this frame
  LDA player_flags
  AND #PlayerFlags::HAS_MOVED
  BEQ done
  DEC time_to_next_car
  BNE load_next
  
  JSR npc_car_spawn
  INC16_L rand_seed
  JSR get_rand_byte
  STA time_to_next_car

done:
  RTS
.endproc

.proc check_car_despawn
  despawn_seam := locals+0
  car_bottom := locals+1
  cam_wrapped := locals+2

  LDA #FALSE
  STA cam_wrapped

  LDX #NUM_NPC_CARS-1
loop:
  LDA npc_car_flags,x
  BPL load_next
  
  LDA camera_y+1
  CLC
  ADC #(LEVEL_LENGTH/2)+(>NPC_CAR_HEIGHT)
  STA despawn_seam
  ; wrap
  CMP #LEVEL_LENGTH
  BCC :+
    SEC
    SBC #LEVEL_LENGTH
    STA despawn_seam
    LDA #TRUE
    STA cam_wrapped
  :
  LDA npc_car_y_hi,x
  CLC
  ADC #>NPC_CAR_HEIGHT
  ; wrap, again
  CMP #LEVEL_LENGTH
  BCC :+
    SEC
    SBC #LEVEL_LENGTH
  :
  STA car_bottom
  CMP despawn_seam
  BCC load_next
  
  LDA cam_wrapped
  BEQ :+
    LDA car_bottom
    CMP camera_y+1
    BCS load_next
  :
  
  LDA npc_car_flags,x
  AND #<~NpcCarFlags::ACTIVE
  STA npc_car_flags,x
load_next:
  DEX
  BNE loop
  JMP done ; no slots left

check_spawn_timer:
  ; only advance timer if you've moved this frame
  LDA player_flags
  AND #PlayerFlags::HAS_MOVED
  BEQ done
  DEC time_to_next_car
  BNE done
  
  JSR npc_car_spawn
  INC16_L rand_seed
  JSR get_rand_byte
  STA time_to_next_car

done:
  RTS
.endproc

.proc npc_car_spawn
  ; randomly decide whether civilian or enemy
  INC16_L rand_seed
  JSR get_rand_byte
  LDA rand_value
  AND #$01
  ORA #NpcCarFlags::ACTIVE|NpcCarFlags::VISIBLE
  STA npc_car_flags,x

  ; randomly generate position
  INC16_L rand_seed
  JSR get_rand_byte
  LDA rand_value
  AND #LEVEL_MAX_WIDTH-1 ; constrain to level width
  LDA camera_y+1
  STA npc_car_y_hi,x
  LDA #$00
  STA npc_car_y_lo,x
  RTS
.endproc

.proc npc_cars_update
  LDX #NUM_NPC_CARS-1
check_active:
  LDA npc_car_flags,x
  BPL load_next
  JSR npc_car_update
load_next:
  DEX
  BNE check_active
  ; check if a new one should spawn
  JSR check_car_spawn
  ; check if an existing car should stop existing
  JSR check_car_despawn
  RTS
.endproc

.proc npc_car_update
  LDA npc_car_flags,x
  AND #NpcCarFlags::CIVILIAN
  BEQ :+
    JMP civilian_update
  :
  JMP enemy_update
  RTS
.endproc

.proc npc_cars_draw
  LDX #NUM_NPC_CARS-1
check_active:
  LDA npc_car_flags,x
  AND #NpcCarFlags::ACTIVE|NpcCarFlags::VISIBLE
  CMP #NpcCarFlags::ACTIVE|NpcCarFlags::VISIBLE
  BNE load_next
  JSR npc_car_draw
load_next:
  DEX
  BNE check_active
  RTS
.endproc

.proc npc_car_draw
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes

  JSR npc_car_get_screen_pos
  LDA npc_car_flags,x
  AND #NpcCarFlags::CIVILIAN
  BEQ :+
    ; draw enemy
    LDA #<enemy_car_sprite
    STA sprite_ptr
    LDA #>enemy_car_sprite
    STA sprite_ptr+1
    JMP draw
  :
  ; draw civilian
    LDA #<civilian_car_sprite
    STA sprite_ptr
    LDA #>civilian_car_sprite
    STA sprite_ptr+1
draw:
  LDA #$00
  STA sprite_attr
  LDA #24
  STA size
  PUSH_X
  JSR draw_sprite_dynamic
  PULL_X
  RTS
.endproc

.proc npc_car_get_screen_pos
  npc_car_x_camera := locals+0 ; 2 bytes
  npc_car_y_camera := locals+2 ; 2 bytes
  temp_camera_y := locals+4 ; 1 byte, just the high
  should_car_be_drawn := locals+5 ; if dips below screen, answer is no
  sprite_x := locals+11
  sprite_y := locals+12


  ; wait! what if camera_y is *greater* than player_y?
  ; when wrapping, that is a thing that may happen.

  LDA npc_car_y_hi,x
  CMP camera_y+1
  BCS :+
    LDA camera_y+1
    SEC
    SBC #LEVEL_LENGTH
    STA temp_camera_y
    JMP sub_y
  :
  LDA camera_y+1
  STA temp_camera_y
sub_y:
  ; subtract camera position
  LDA npc_car_y_lo,x
  SEC
  SBC camera_y
  STA npc_car_y_camera

  LDA npc_car_y_hi,x
  SBC temp_camera_y
  STA npc_car_y_camera+1

  LDA npc_car_x_lo,x
  SEC
  SBC camera_x
  STA npc_car_x_camera
  LDA npc_car_x_hi,x
  SBC camera_x+1
  STA npc_car_x_camera+1

  ; convert world pos to screen pos
  LDA npc_car_y_camera+1
  LSHIFT 3
  STA sprite_y
  LDA npc_car_y_camera
  RSHIFT 5
  ORA sprite_y
  STA sprite_y

  LDA npc_car_x_camera+1
  LSHIFT 3
  STA sprite_x
  LDA npc_car_x_camera
  RSHIFT 5
  ORA sprite_x
  STA sprite_x

  RTS
.endproc
