.include "common.inc"
.include "sprites.inc"

.zeropage
oam_current_index: .res 1
oam_offset_add: .res 1
sprites_drawn: .res 1 ; track if we're overflowing?

.code

.proc clear_oam
  LDX #$3C
  LDA #$FF
loop:
  STA $0200,x
  STA $0240,x
  STA $0280,x
  STA $02C0,x
  DEX
  DEX
  DEX
  DEX
  BPL loop
  RTS
.endproc

.proc set_dynamic_oam_direction
  LDA #OAM_DYNAMIC_WINDOW_START
  STA oam_current_index
  LDA oam_offset_add
  CMP #OAM_OFFSET_FORWARD
  BEQ set_oam_offset_backward
  LDA #OAM_OFFSET_FORWARD
  STA oam_offset_add
  JMP done
set_oam_offset_backward:
  LDA #OAM_OFFSET_BACKWARD
  STA oam_offset_add
  LDA #OAM_OFFSET_BACKWARD
  STA oam_current_index
done:
  RTS
.endproc


; @arg A = oam_offset
; all other locals are themselves args
.proc draw_sprite_fixed
  oam_offset := locals+9
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes

  STA oam_offset
  LDY #$00
  LDX oam_offset
draw:
  LDA (sprite_ptr),y
  CLC
  ADC sprite_y
  STA $0200,x
  INY

  LDA (sprite_ptr),y
  STA $0201,x
  INY
  
  LDA (sprite_ptr),y
  ORA sprite_attr
  STA $0202,x
  INY

  LDA (sprite_ptr),y
  CLC
  ADC sprite_x
  STA $0203,x
  INY

  INX
  INX
  INX
  INX

  CPY size
  BNE draw
  RTS
.endproc

; all locals are args
.proc draw_sprite_dynamic
  size := locals+10
  sprite_x := locals+11
  sprite_y := locals+12
  sprite_attr := locals+13
  sprite_ptr := locals+14 ; 2 bytes
  

  LDY #$00
draw:
  LDX oam_current_index
  LDA (sprite_ptr),y
  CLC
  ADC sprite_y
  STA $0200,x
  INY

  LDA (sprite_ptr),y
  STA $0201,x
  INY
  
  LDA (sprite_ptr),y
  ORA sprite_attr
  STA $0202,x
  INY

  LDA (sprite_ptr),y
  CLC
  ADC sprite_x
  STA $0203,x
  INY

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  CPY size
  BNE draw
  RTS
.endproc