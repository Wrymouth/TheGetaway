.include "common.inc"
.include "shot.inc"
.include "npc_cars.inc"
.include "level.inc"
.include "sprites.inc"

SHOT_COOLDOWN = 8
SHOT_OFFSET_X = $0080
SHOT_LIFETIME = 16
SHOT_RELATIVE_SPEED = $0100

SHOT_HORIZONTAL_DISTANCE = $00A0

.zeropage
  shot_flags: .res NUM_SHOTS
  shot_x_hi: .res NUM_SHOTS
  shot_x_lo: .res NUM_SHOTS
  shot_y_hi: .res NUM_SHOTS
  shot_y_lo: .res NUM_SHOTS
  shot_vel_hi: .res NUM_SHOTS
  shot_vel_lo: .res NUM_SHOTS
  shot_lifetime: .res NUM_SHOTS

  shot_cooldown: .res 1
.code

.proc shots_init
  .repeat NUM_SHOTS, i
    LDA #$00
    STA shot_flags+i
  .endrepeat
  LDA #SHOT_COOLDOWN
  STA shot_cooldown
  RTS
.endproc

.proc shot_create
  LDA shot_cooldown
  BNE done
  LDX #NUM_SHOTS-1
loop:
  LDA shot_flags,x
  BMI load_next

  ; create shot
  LDA #ShotFlags::ACTIVE|ShotFlags::VISIBLE
  STA shot_flags,x

  LDA #SHOT_COOLDOWN
  STA shot_cooldown
  
  LDA player_x
  STA shot_x_lo,x
  LDA player_x+1
  STA shot_x_hi,x

  LDA player_y
  STA shot_y_lo,x
  LDA player_y+1
  STA shot_y_hi,x

  SEC
  LDA player_vel_y
  SBC #<SHOT_RELATIVE_SPEED
  STA shot_vel_lo,x
  LDA player_vel_y+1
  SBC #>SHOT_RELATIVE_SPEED
  STA shot_vel_hi,x

  LDA #SHOT_LIFETIME
  STA shot_lifetime,x


  JMP done
load_next:
  DEX
  BNE loop
done:
  RTS
.endproc

.proc shots_update
  LDA shot_cooldown
  BEQ :+
    DEC shot_cooldown
  :
  LDX #NUM_SHOTS-1
check_active:
  LDA shot_flags,x
  BPL load_next
  JSR shot_update
load_next:
  DEX
  BNE check_active
  RTS
.endproc

.proc shot_update
  CLC
  LDA shot_y_lo,x
  ADC shot_vel_lo,x
  STA shot_y_lo,x
  LDA shot_y_hi,x
  ADC shot_vel_hi,x
  STA shot_y_hi,x

  DEC shot_lifetime,x
  BNE :+
    LDA shot_flags,x
    AND #<~ShotFlags::ACTIVE
    STA shot_flags,x
  :

  RTS
.endproc

.proc shot_collide_with_npc_cars
  LDY #NUM_NPC_CARS-1
check_active:
  LDA npc_car_flags,y
  BPL load_next
  JSR shot_collide_with_npc_car
load_next:
  DEX
  BNE check_active
  RTS
.endproc

; X = shot
; Y = car
.proc shot_collide_with_npc_car
  car_right := locals+0 ; 2 bytes
  car_bottom := locals+2 ; 2 bytes
  shot_right := locals+4 ; 2 bytes
  
cmp_shot_left_car_right:
  RTS
.endproc

.proc shot_get_screen_pos
  shot_x_camera := locals+0 ; 2 bytes
  shot_y_camera := locals+2 ; 2 bytes
  temp_camera_y := locals+4 ; 1 byte, just the high
  should_be_drawn := locals+5 ; if dips below screen, answer is no
  sprite_x := locals+11
  sprite_y := locals+12

  LDA shot_y_hi,x
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
  LDA shot_y_lo,x
  SEC
  SBC camera_y
  STA shot_y_camera

  LDA shot_y_hi,x
  SBC temp_camera_y
  STA shot_y_camera+1

  LDA shot_x_lo,x
  SEC
  SBC camera_x
  STA shot_x_camera
  LDA shot_x_hi,x
  SBC camera_x+1
  STA shot_x_camera+1

  ; convert world pos to screen pos
  LDA shot_y_camera+1
  LSHIFT 3
  STA sprite_y
  LDA shot_y_camera
  RSHIFT 5
  ORA sprite_y
  STA sprite_y

  LDA shot_x_camera+1
  LSHIFT 3
  STA sprite_x
  LDA shot_x_camera
  RSHIFT 5
  ORA sprite_x
  STA sprite_x

  RTS
  RTS
.endproc

.proc shots_draw
    LDX #NUM_SHOTS-1
check_active:
  LDA shot_flags,x
  AND #ShotFlags::ACTIVE|ShotFlags::VISIBLE
  CMP #ShotFlags::ACTIVE|ShotFlags::VISIBLE
  BNE load_next
  JSR shot_draw
load_next:
  DEX
  BNE check_active
  RTS
  RTS
.endproc

.proc shot_draw
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes
  
  JSR shot_get_screen_pos
  
  LDA #$04
  STA size

  LDA #<shot_sprite
  STA sprite_ptr
  LDA #>shot_sprite
  STA sprite_ptr+1

  LDA #$00
  STA sprite_attr

  PUSH_X
  JSR draw_sprite_dynamic
  PULL_X
  
  RTS
.endproc

shot_sprite:
.byte $00, $0E, $00, $00

shot_chr:
  .incbin "shot.chr"