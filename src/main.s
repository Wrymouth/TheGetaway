.include "common.inc"
.include "controller.inc"
.include "game_states.inc"
.include "sprites.inc"
.include "camera.inc"
.include "background.inc"

.import handle_input_pad1

.zeropage
  locals: .res 16
  sleeping: .res 1
  game_status_flags: .res 1
  ppuctrl_settings: .res 1
  ppumask_settings: .res 1
.code

.proc reset
  sei
  cld
  ldx #$40
  stx APUFRAME
  ldx #$ff
  txs
  inx
  stx PPUCTRL
  stx PPUMASK
  stx ppumask_settings
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
  sta ppuctrl_settings
  jmp main
.endproc

.proc nmi
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA game_status_flags
  BMI :+
    JSR draw_buffered_gfx
  :

  ; OAM DMA
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA

  LDA ppuctrl_settings
  STA PPUCTRL
  LDA ppumask_settings
  STA PPUMASK

  LDA game_status_flags
  BMI done 
  
  LDA PPUSTATUS
  LDA scroll_x ; X scroll first
  STA PPUSCROLL
  LDA scroll_y ; Y scroll
  STA PPUSCROLL

done:
  LDA #$00
  STA sleeping
  
  PLA
  TAY
  PLA
  TAX
  PLA
  RTI
.endproc

.proc irq
  RTI
.endproc

.proc main
  LDA #$00
  STA buffer_idx
  LDA #GameStates::ENTER_GAME
  JSR set_game_state
main_loop:
  JSR clear_vram_buffer
  JSR clear_oam
  JSR set_dynamic_oam_direction
  JSR handle_input_pad1
  JSR do_game_state
set_sleeping:
  INC sleeping
sleep:
  LDA sleeping
  BNE sleep
  JMP main_loop
.endproc

.org $fffa
  .word nmi
  .word reset
  .word irq

.segment "CHR"
.incbin "tiles.chr"
