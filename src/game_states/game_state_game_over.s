.include "common.inc"
.include "game_states.inc"
.include "background.inc"
.include "chr_allocator.inc"

GAME_OVER_TIME = 255

.zeropage

game_over_timer: .res 1

.code 

.proc game_state_game_over
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA #$00
    STA ppumask_settings
    STA PPUMASK ; really, we should wait for vblank before doing this but it's probably fine

    LDA #GAME_OVER_TIME
    STA game_over_timer

    LDA game_status_flags
    ORA #GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags

    ; first set the CHR
    JSR load_game_over_chr
    JSR clear_screen
    JSR draw_game_over_backgrounds
    JSR game_over_write_palettes

    LDA game_status_flags
    AND #<~GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags

    LDA #%00011110
    STA ppumask_settings
    
    LDA #$00
    STA scroll_x
    STA scroll_y

    LDA ppuctrl_settings
    AND #<~PPUCTRL_NAMETABLE_Y
    STA ppuctrl_settings

    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :

  DEC game_over_timer
  BNE :+
    LDA #GameStates::TITLE
    JSR set_game_state
  :
  RTS
.endproc

.proc game_over_write_palettes
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

.proc load_game_over_chr
  tile_ptr := locals+0

  LDA #$28
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  LDX #$00
  LDA #<game_over_chr
  STA tile_ptr
  LDA #>game_over_chr
  STA tile_ptr+1
loop:
  JSR draw_game_over_chr_tile_directly
  ADD16_L tile_ptr, #16
  INX
  CPX #64
  BCC loop
  RTS
.endproc

.proc draw_game_over_chr_tile_directly
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

.proc draw_game_over_backgrounds
  LDA #$21
  STA PPUADDR
  LDA #$60
  STA PPUADDR
  LDX #$00
@loop:
  LDA game_over_image,x
  CLC
  ADC #$80
  STA PPUDATA
  INX
  CPX #160
  BCC @loop
  RTS
.endproc

bg_palette:
  .byte $0F, $0F, $13, $30

game_over_image:
  .incbin "game_over_img.map"

game_over_chr:
  .incbin "game_over.chr"
