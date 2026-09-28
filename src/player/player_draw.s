.include "common.inc"
.include "player.inc"
.include "player_internal.inc"
.include "sprites.inc"
.include "camera.inc"
.include "level.inc"

.proc player_get_screen_coords
  player_x_camera := locals+0 ; 2 bytes
  player_y_camera := locals+2 ; 2 bytes
  temp_camera_y := locals+4 ; 1 byte, just the high
  sprite_x := locals+11
  sprite_y := locals+12


  ; wait! what if camera_y is *greater* than player_y?
  ; when wrapping, that is a thing that may happen.

  LDA player_y+1
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
  LDA player_y
  SEC
  SBC camera_y
  STA player_y_camera

  LDA player_y+1
  SBC temp_camera_y
  STA player_y_camera+1

  LDA player_x
  SEC
  SBC camera_x
  STA player_x_camera
  LDA player_x+1
  SBC camera_x+1
  STA player_x_camera+1

  ; convert world pos to screen pos
  LDA player_y_camera+1
  LSHIFT 3
  STA sprite_y
  LDA player_y_camera
  RSHIFT 5
  ORA sprite_y
  STA sprite_y

  LDA player_x_camera+1
  LSHIFT 3
  STA sprite_x
  LDA player_x_camera
  RSHIFT 5
  ORA sprite_x
  STA sprite_x

  RTS
.endproc

.proc player_draw
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes

  ; get screen coords
  JSR player_get_screen_coords ; this sets sprite_x and sprite_y

  LDA #$00
  STA sprite_attr

  LDA player_sprite_idle
  STA size
  LDA #<(player_sprite_idle+1)
  STA sprite_ptr
  LDA #>(player_sprite_idle+1)
  STA sprite_ptr+1
  JSR draw_sprite_dynamic
  RTS
.endproc

player_sprites:

player_sprite_idle:
.byte 24 ; size
NEXXT_SPRITE 0,   0,$00,0
NEXXT_SPRITE 8,   0,$00,0|OAM_FLAG_FLIP_H
NEXXT_SPRITE 0,   8,$01,0
NEXXT_SPRITE 8,   8,$01,0|OAM_FLAG_FLIP_H
NEXXT_SPRITE 0,  16,$02,0
NEXXT_SPRITE 8,  16,$02,0|OAM_FLAG_FLIP_H

player_chr:

player_chr_idle_0:
  .incbin "player/player_idle_0.chr"
player_chr_idle_1:
  .incbin "player/player_idle_1.chr"
player_chr_idle_2:
  .incbin "player/player_idle_2.chr"