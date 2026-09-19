.include "common.inc"
.include "level.inc"

.zeropage
current_row_width: .res 1
current_row_start: .res 1

.segment "LEVEL" :bss :mem $0300 :size $0100
level: .res 240

.code
.proc init_level
  ; initialize the level as a single long straight road
  LDX #$00
loop:
  LDA #9
  STA level+0,x
  LDA #22
  STA level+1,x
  LDA #$00
  STA level+2,x
  STA level+3,x
  INX
  INX
  INX
  INX
  CPX #LEVEL_LENGTH*LEVEL_ROW_SIZE
  BCC loop
  RTS
.endproc

.proc write_level_palettes
  LDA #$3F
  STA PPUADDR
  LDA #$00
  STA PPUADDR
  .repeat 4
    LDA bg_palette+0
    STA PPUDATA
    LDA bg_palette+1
    STA PPUDATA
    LDA bg_palette+2
    STA PPUDATA
    LDA bg_palette+3
    STA PPUDATA
  .endrepeat
  .repeat 16, i
    LDA sprite_palettes+i
    STA PPUDATA
  .endrepeat

  RTS
.endproc

.proc draw_initial_level
  ppu_addr := locals+0 ; 2 bytes, big endian
  current_row_road_start := locals+2
  current_row_road_end := locals+3
  current_row_offset := locals+4

  LDA game_status_flags
  ORA #GameStatusFlags::NMI_SKIP_SCROLL
  STA game_status_flags

; determine nametable address from row index
; for each row:
; get row offset (in bytes) ASL 3 (multiply by 8)
; this turns 4 into 20, 8 into 40 etc

  LDX #$00
draw_row:
  LDA #$00
  STA ppu_addr+0
  STA ppu_addr+1
  
  TXA
  CMP #LEVEL_LENGTH/2*4
  BCC :+
    SEC
    SBC #30*4
:
  ; mul 8, 16 bit result
  ASL
  ROL ppu_addr+0
  ASL
  ROL ppu_addr+0
  ASL
  ROL ppu_addr+0
  STA ppu_addr+1

  ; add base nametable address
  LDA ppu_addr+0
  CPX #LEVEL_LENGTH/2*4
  BCS :+
    ; less than 30
    CLC
    ADC #$20
    JMP store_ppu_addr
  :
  CLC
  ADC #$28
store_ppu_addr:
  STA ppu_addr+0

  LDA ppu_addr+0
  STA PPUADDR
  LDA ppu_addr+1
  STA PPUADDR

  ; now DRAW
  ; "inverted" check not necessary, it's guaranteed to not be the case on initial draw (for now, anyway)
  ; draw grass until "road start"
  LDA level,x
  STA current_row_road_start
  LDA level+1,x
  STA current_row_road_end

  LDA #$00
  STA current_row_offset

loop_draw_row:
  LDA current_row_offset
  CMP current_row_road_start
  BCC draw_grass
  CMP current_row_road_end
  BEQ draw_road
  BCS draw_grass
draw_road:
  LDA #$3D ; road
  STA PPUDATA
  JMP inc_row_offset
draw_grass:
  LDA #$3C ; grass
  STA PPUDATA
inc_row_offset:
  LDA current_row_offset
  CLC
  ADC #$01
  STA current_row_offset
  CMP #LEVEL_TOTAL_WIDTH
  BCC loop_draw_row

  INX
  INX
  INX
  INX
  CPX #LEVEL_LENGTH*LEVEL_ROW_SIZE
  BCC draw_row

  JSR write_level_palettes

  LDA game_status_flags
  AND #<~GameStatusFlags::NMI_SKIP_SCROLL
  STA game_status_flags
  RTS
.endproc

sprite_palettes:
.byte $0F, $0F, $15, $30
.byte $0F, $0F, $12, $30
.byte $0F, $0F, $26, $30
.byte $0F, $0F, $2A, $30

bg_palette:
.byte $0F, $10, $2A, $30