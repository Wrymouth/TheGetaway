.include "common.inc"
.include "background.inc"

.zeropage
  buffer_idx: .res 1
  vram_buffer_saved_stack_ptr: .res 1
  temp_vram_buffer_length: .res 1
  vram_buffer_jump: .res 3

.code
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

; format:
;   byte 1    : data length
;   byte 2,3  : ppu addr
;   byte 4..* : tiles to write
;
; range: $0100 - $019F
.proc draw_buffered_gfx
; do not make vram_buffer_saved_stack_ptr a local, this is an NMI routine
  TSX
  STX vram_buffer_saved_stack_ptr
  LDX #$FF
  TXS
process_string:
  ; get data length
  PLA
  BNE :+
    JMP done
  :
  TAY
  ; get address
  PLA
  STA PPUADDR
  PLA
  STA PPUADDR

  CPY #32
  BEQ draw_tiles
  
  LDA #$4C ; JMP abs
  STA vram_buffer_jump
  ; calculate where to jump
  TYA
  ; each write is 4 bytes (PLA, STA abs), so mult length by 4
  LSHIFT 2
  STA vram_buffer_jump+1
  LDA #<draw_tiles
  CLC
  ADC vram_buffer_jump+1
  STA vram_buffer_jump+1
  LDA #>draw_tiles
  ADC #$00
  STA vram_buffer_jump+2
  JMP vram_buffer_jump

draw_tiles:
  .repeat 32
    PLA
    STA PPUDATA
  .endrepeat
  JMP process_string

done:
  LDX vram_buffer_saved_stack_ptr
  TXS
  LDA #$00
  STA buffer_idx
  RTS
.endproc
