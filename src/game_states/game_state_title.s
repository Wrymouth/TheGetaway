.include "common.inc"
.include "game_states.inc"
.include "controller.inc"
.include "background.inc"
.include "chr_allocator.inc"

.code 

.proc game_state_title
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA #$00
    STA ppumask_settings
    STA PPUMASK

    LDA game_status_flags
    ORA #GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags
    
    JSR load_title_chr
    JSR clear_screen
    JSR draw_title_backgrounds
    JSR title_write_palettes
    
    LDA game_status_flags
    AND #<~GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags

    LDA #%00011110
    STA ppumask_settings
    
    LDA #$00
    STA scroll_x
    STA scroll_y

    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  LDA pad1_first_pressed
  AND #BTN_START
  BEQ done
  LDA #GameStates::ENTER_GAME
  JSR set_game_state
done:
  RTS
.endproc

.proc title_write_palettes
  VRAM_BUFFER_BEGIN
  VRAM_BUFFER_SET_DATA_LENGTH #32
  VRAM_BUFFER_SET_NAMETABLE_BYTES #$3F, #$00
  .repeat 8
    LDA bg_palette+0
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+1
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+2
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+3
    VRAM_BUFFER_WRITE_A
  .endrepeat
  VRAM_BUFFER_END
  RTS
.endproc

.proc load_title_chr
  tile_ptr := locals+0

  LDA #$28
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  LDX #$00
  LDA #<title_chr
  STA tile_ptr
  LDA #>title_chr
  STA tile_ptr+1
loop:
  JSR draw_title_chr_tile_directly
  ADD16_L tile_ptr, #16
  INX
  CPX #64
  BCC loop
  RTS
.endproc


.proc draw_title_chr_tile_directly
  tile_ptr := locals+0
  LDY #$00
draw:
  LDA (tile_ptr),y
  STA PPUDATA
  INY
  CPY #CHR_TILE_SIZE
  BCC draw
  RTS
.endproc

.proc draw_title_backgrounds
draw_garbage:
  LDA #$20
  STA PPUADDR
  LDA #$A0
  STA PPUADDR
  LDX #$00
@loop:
  LDA title_image,x
  STA PPUDATA
  INX
  CPX #192
  BCC @loop
draw_title_logo:
  LDA #$20
  STA PPUADDR
  LDA #$C0
  STA PPUADDR
  LDX #$00
@loop:
  LDA title_image,x
  CLC
  ADC #$80
  STA PPUDATA
  INX
  CPX #192
  BCC @loop
load_press_start:
  LDA #$22
  STA PPUADDR
  LDA #$4A
  STA PPUADDR

  LDA #$B0 ; P
  STA PPUDATA
  LDA #$B1 ; R
  STA PPUDATA
  LDA #$B2 ; E
  STA PPUDATA
  LDA #$B3 ; S
  STA PPUDATA
  LDA #$B3 ; S
  STA PPUDATA
  LDA #$80 ; [space]
  STA PPUDATA
  LDA #$B3 ; S
  STA PPUDATA
  LDA #$B4 ; T
  STA PPUDATA
  LDA #$B5 ; A
  STA PPUDATA
  LDA #$B1 ; R
  STA PPUDATA
  LDA #$B4 ; T
  STA PPUDATA
  LDA #$BA ; !
  STA PPUDATA
  RTS
.endproc

bg_palette:
  .byte $0F, $0F, $21, $30

title_image:
  .incbin "title_img.map"

title_chr:
  .incbin "title_screen.chr"
