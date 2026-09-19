.include "constants.inc"

.zeropage
sleeping: .res 1

.code

.proc reset
  sei
  cld
  ldx #$40
  stx APU_FRAME
  ldx #$ff
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
  stx sleeping

  bit PPUSTATUS
: 
  bit PPUSTATUS
  bpl :-
:
  bit PPUSTATUS
  bpl :-

  lda #%10000000
  sta PPUCTRL
  jmp main
.endproc

.proc nmi
  INC sleeping
  RTI
.endproc

.proc irq
  RTI
.endproc

.proc main
main_loop:
set_sleeping:
  DEC sleeping
sleep:
  LDA sleeping
  BEQ sleep
  JMP main_loop
.endproc

.org $fffa
  .word nmi
  .word reset
  .word irq

.segment "CHR"
.incbin "tiles.chr"
