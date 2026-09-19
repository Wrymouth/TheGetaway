.include "common.inc"
.include "background.inc"

.proc clear_vram_buffer
  LDX #$00
loop:
  LDA #$00
  STA $0100,x
  INX
  CPX #VRAM_BUFFER_SIZE
  BNE loop

  RTS
.endproc