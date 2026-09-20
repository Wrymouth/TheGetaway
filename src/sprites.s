.include "sprites.inc"

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

.proc draw_sprite_fixed
  RTS
.endproc

.proc draw_sprite_dynamic
  
  RTS
.endproc