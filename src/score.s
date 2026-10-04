.include "common.inc"
.include "score.inc"
.include "sprites.inc"
.include "chr_allocator.inc"

SCORE_OFFSET = NUM_SPRITES_HEALTH_BAR + NUM_SPRITES_LIVES

SCORE_DIGIT_PLANE_SIZE = 4 ; bytes

.zeropage
  score: .res 3 ; base 100, 6 digits
  prev_score: .res 3 ; base 100, 6 digits

.segment "SCORE" :mem $0500 :size $80 :bss
  score_chr_0: .res 16
  score_chr_1: .res 16
  score_chr_2: .res 16

.code
.proc score_init
  LDA #$00
  STA score+0
  STA score+1
  STA score+2
  STA prev_score+0
  STA prev_score+1
  STA prev_score+2

  JSR update_score_chr
  RTS
.endproc

.proc score_update
  LDA score+0
  CMP prev_score+0
  BNE update_chr
  LDA score+1
  CMP prev_score+1
  BNE update_chr
  LDA score+2
  CMP prev_score+2
  BEQ done
update_chr:
  JSR update_score_chr
  LDA score+0
  STA prev_score+0
  LDA score+1
  STA prev_score+1
  LDA score+2
  STA prev_score+2
done:
  RTS
.endproc

.proc score_draw
  SCORE_BASE_X = 232
  SCORE_BASE_Y = 20

  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes
  LDA #12
  STA size

  LDA #SCORE_BASE_X
  STA sprite_x
  LDA #SCORE_BASE_Y
  STA sprite_y
  LDA #$00
  STA sprite_attr

  LDA #<score_spr
  STA sprite_ptr
  LDA #>score_spr
  STA sprite_ptr+1
  
  LDA #SCORE_OFFSET*4
  JSR draw_sprite_fixed
  RTS
.endproc

.proc update_score_chr
  chr_ptr := locals+14

  ; write the digits to the RAM area
  JSR write_score_to_ram

  LDA #<score_chr_0
  STA chr_ptr+0
  LDA #>score_chr_0
  STA chr_ptr+1
  LDY #$07
  JSR replace_chr_tile
  
  LDA #<score_chr_1
  STA chr_ptr+0
  LDA #>score_chr_1
  STA chr_ptr+1
  LDY #$08
  JSR replace_chr_tile
  
  LDA #<score_chr_2
  STA chr_ptr+0
  LDA #>score_chr_2
  STA chr_ptr+1
  LDY #$09
  JSR replace_chr_tile
  RTS
.endproc

.proc write_score_to_ram
  tens_digit := locals+0
  ones_digit := locals+1
  tens_byte := locals+2
  ones_byte := locals+3
  tens_ptr := locals+4 ; 2 bytes
  ones_ptr := locals+6 ; 2 bytes

  ; tile 0
  LDX score+0
  LDA base_100_to_bcd,x
  STA ones_digit
  RSHIFT 4
  STA tens_digit

  LDA ones_digit
  AND #$0F
  STA ones_digit

  LDX tens_digit
  LDA score_tens_lo,x
  STA tens_ptr
  LDA score_tens_hi,x
  STA tens_ptr+1

  LDX ones_digit
  LDA score_ones_lo,x
  STA ones_ptr
  LDA score_ones_hi,x
  STA ones_ptr+1

  LDY #$00
@loop:
  LDA (tens_ptr),y
  STA tens_byte
  LDA (ones_ptr),y
  STA ones_byte
  ORA tens_byte
  STA score_chr_0,y
  INY
  CPY #CHR_TILE_SIZE
  BCC @loop

tile_1:
  LDX score+1
  LDA base_100_to_bcd,x
  STA ones_digit
  RSHIFT 4
  STA tens_digit

  LDA ones_digit
  AND #$0F
  STA ones_digit

  LDX tens_digit
  LDA score_tens_lo,x
  STA tens_ptr
  LDA score_tens_hi,x
  STA tens_ptr+1

  LDX ones_digit
  LDA score_ones_lo,x
  STA ones_ptr
  LDA score_ones_hi,x
  STA ones_ptr+1

  LDY #$00
@loop:
  LDA (tens_ptr),y
  STA tens_byte
  LDA (ones_ptr),y
  STA ones_byte
  ORA tens_byte
  STA score_chr_1,y
  INY
  CPY #CHR_TILE_SIZE
  BCC @loop

tile_2:
  LDX score+2
  LDA base_100_to_bcd,x
  STA ones_digit
  RSHIFT 4
  STA tens_digit

  LDA ones_digit
  AND #$0F
  STA ones_digit

  LDX tens_digit
  LDA score_tens_lo,x
  STA tens_ptr
  LDA score_tens_hi,x
  STA tens_ptr+1

  LDX ones_digit
  LDA score_ones_lo,x
  STA ones_ptr
  LDA score_ones_hi,x
  STA ones_ptr+1

  LDY #$00
@loop:
  LDA (tens_ptr),y
  STA tens_byte
  LDA (ones_ptr),y
  STA ones_byte
  ORA tens_byte
  STA score_chr_2,y
  INY
  CPY #CHR_TILE_SIZE
  BCC @loop

  RTS
.endproc

; adds 1 score
.proc add_score
  LDA score+0
  CLC
  ADC #$01
  STA score+0
  CMP #100
  BNE done

  LDA #$00
  STA score+0
  LDA score+1
  CLC
  ADC #$01
  STA score+1
  CMP #100
  BNE done

  LDA #$00
  STA score+1
  LDA score+2
  CLC
  ADC #$01
  STA score+2
  CMP #100
  BNE done

  LDA #$00
  STA score+2
done:
  RTS
.endproc

base_100_to_bcd:
  .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99

score_spr:
  .byte $00, $07, $00,  $00
  .byte $00, $08, $00,   -8
  .byte $00, $09, $00,  -16

.define score_tens score_tens_0, score_tens_1, score_tens_2, score_tens_3, score_tens_4, score_tens_5, score_tens_6, score_tens_7, score_tens_8, score_tens_9
.define score_ones score_ones_0, score_ones_1, score_ones_2, score_ones_3, score_ones_4, score_ones_5, score_ones_6, score_ones_7, score_ones_8, score_ones_9

score_tens_lo:
  .lobytes score_tens
score_tens_hi:
  .hibytes score_tens

score_ones_lo:
  .lobytes score_ones
score_ones_hi:
  .hibytes score_ones

score_tens_0:
  .incbin "score/score_tens_0.chr"
score_tens_1:
  .incbin "score/score_tens_1.chr"
score_tens_2:
  .incbin "score/score_tens_2.chr"
score_tens_3:
  .incbin "score/score_tens_3.chr"
score_tens_4:
  .incbin "score/score_tens_4.chr"
score_tens_5:
  .incbin "score/score_tens_5.chr"
score_tens_6:
  .incbin "score/score_tens_6.chr"
score_tens_7:
  .incbin "score/score_tens_7.chr"
score_tens_8:
  .incbin "score/score_tens_8.chr"
score_tens_9:
  .incbin "score/score_tens_9.chr"

score_ones_0:
  .incbin "score/score_ones_0.chr"
score_ones_1:
  .incbin "score/score_ones_1.chr"
score_ones_2:
  .incbin "score/score_ones_2.chr"
score_ones_3:
  .incbin "score/score_ones_3.chr"
score_ones_4:
  .incbin "score/score_ones_4.chr"
score_ones_5:
  .incbin "score/score_ones_5.chr"
score_ones_6:
  .incbin "score/score_ones_6.chr"
score_ones_7:
  .incbin "score/score_ones_7.chr"
score_ones_8:
  .incbin "score/score_ones_8.chr"
score_ones_9:
  .incbin "score/score_ones_9.chr"