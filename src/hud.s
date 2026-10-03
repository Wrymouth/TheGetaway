.include "common.inc"
.include "hud.inc"
.include "player.inc"
.include "sprites.inc"

.zeropage
  hp_bar_segment_data_lo: .res NUM_SPRITES_HEALTH_BAR
  hp_bar_segment_data_hi: .res NUM_SPRITES_HEALTH_BAR

.code

.proc hud_update
  partial_hp_amount := locals+0
  player_health_temp := locals+1
  partial_chr_ptr := locals+14

  LDA #$01
  STA partial_hp_amount ; initialize

  LDX #NUM_SPRITES_HEALTH_BAR

  ; the first sprite
  LDA player_health+1
  STA player_health_temp
  BEQ fill_zero ; 0 HP left
loop_sub_hp:
  LDA player_health_temp
  SEC
  SBC #$08
  STA player_health_temp
  BEQ set_full_then_empty
  BCC set_partial
  ; resulting HP was greater than 8, so draw full and restart the loop
set_full:
  DEX
  LDA #<health_bar_full_spr
  STA hp_bar_segment_data_lo,x
  LDA #>health_bar_full_spr
  STA hp_bar_segment_data_hi,x
  JMP loop_sub_hp
set_full_then_empty:
  DEX
  LDA #<health_bar_full_spr
  STA hp_bar_segment_data_lo,x
  LDA #>health_bar_full_spr
  STA hp_bar_segment_data_hi,x
  TXA
  BEQ write_partial_chr
  JMP fill_zero
set_partial:
  CLC
  ADC #$08
  STA partial_hp_amount
  DEX
  LDA #<health_bar_partial_spr
  STA hp_bar_segment_data_lo,x
  LDA #>health_bar_partial_spr
  STA hp_bar_segment_data_hi,x
  TXA
  BEQ write_partial_chr
fill_zero:
  DEX
  LDA #<health_bar_empty_spr
  STA hp_bar_segment_data_lo,x
  LDA #>health_bar_empty_spr
  STA hp_bar_segment_data_hi,x
  TXA
  BNE fill_zero
write_partial_chr:
  LDX partial_hp_amount
  LDA health_bar_partial_ptrs_lo,x
  STA partial_chr_ptr+0
  LDA health_bar_partial_ptrs_hi,x
  STA partial_chr_ptr+1
  LDY #$03
  JSR replace_chr_tile
  RTS
.endproc

.proc hud_draw
  JSR hud_display_hp
  RTS
.endproc

.proc hud_display_hp
  amount_full_bars := locals+0

  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes

  LDA #$04
  STA size ; draw one sprite at a time
  LDA #$00
  STA sprite_attr ; palette 0

  LDA player_health+1
  RSHIFT 3 ; div 8
  STA amount_full_bars
  LDX #$00
  LDA #HEALTH_BAR_BASE_X
  STA sprite_x
  LDA #HEALTH_BAR_BASE_Y
  STA sprite_y
loop:
  DEC amount_full_bars
  LDA hp_bar_segment_data_lo,x
  STA sprite_ptr
  LDA hp_bar_segment_data_hi,x
  STA sprite_ptr+1
  PUSH_X
  LSHIFT 2 ; mul 4
  JSR draw_sprite_fixed
  PULL_X
  LDA sprite_x
  CLC
  ADC #$08
  STA sprite_x
  INX
  CPX #NUM_SPRITES_HEALTH_BAR
  BCC loop
  RTS
.endproc

health_bar_full_spr:
  .byte $00, $04, $00, $00

health_bar_empty_spr:
  .byte $00, $05, $00, $00

health_bar_partial_spr:
  .byte $00, $03, $00, $00

health_bar_partial_ptrs_lo:
  .lobytes health_bar_partials
health_bar_partial_ptrs_hi:
  .hibytes health_bar_partials

health_bar_full_chr:
  .incbin "health_bar/health_bar_full.chr"
health_bar_empty_chr:
  .incbin "health_bar/health_bar_empty.chr"
health_bar_1_chr:
  .incbin "health_bar/health_bar_1.chr"
health_bar_2_chr:
  .incbin "health_bar/health_bar_2.chr"
health_bar_3_chr:
  .incbin "health_bar/health_bar_3.chr"
health_bar_4_chr:
  .incbin "health_bar/health_bar_4.chr"
health_bar_5_chr:
  .incbin "health_bar/health_bar_5.chr"
health_bar_6_chr:
  .incbin "health_bar/health_bar_6.chr"
health_bar_7_chr:
  .incbin "health_bar/health_bar_7.chr"
