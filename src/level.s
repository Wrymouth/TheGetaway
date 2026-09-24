.include "common.inc"
.include "level.inc"
.include "camera.inc"
.include "background.inc"
.include "chr_allocator.inc"

.zeropage
current_row_width: .res 1
current_row_start: .res 1

.segment "LEVEL" :bss :mem $0300 :size $0100
level: .res 240

.code
.proc level_init
  ; initialize the level as a single long straight road
  LDX #$00
loop:
  LDA #9
  STA level+0,x
  LDA #22
  STA level+1,x
  LDA #$00
  STA level+2,x
  LDA #$00
  STA level+3,x
  INX
  INX
  INX
  INX
  CPX #LEVEL_LENGTH*LEVEL_ROW_SIZE
  BCC loop
  RTS
.endproc

; update the RAM level data with random new values
.proc level_update
  current_row := locals+0
  LDA camera_y+1
  SEC
  SBC #SCROLL_SEAM_OFFSET
  ; handle wraparound
  BCS :+
    CLC
    ADC #LEVEL_LENGTH
  :
  STA current_row

  ; multiply by 4 to get its offset in the level data
  LSHIFT 2
  TAX
  ; TODO generate tile data randomly
  LDA #$09
  STA level,x
  INX
  
  LDA #$16
  STA level,x
  INX
  
  LDA #$00
  ORA level,x
  STA level,x
  INX

  LDA #$00
  STA level,x

  RTS
.endproc

; draw the next row at the scroll seam
.proc level_draw_row
  current_row_offset := locals+0
  ppu_addr := locals+1 ; 2 bytes, big endian
  current_row_road_start := locals+3
  current_row_road_end := locals+4
  current_row_flags := locals+5
  chr_row := locals+6

  ; compute nametable addr
  LDA #$00
  STA ppu_addr+0
  STA ppu_addr+1

  LDA camera_y+1
  SEC
  SBC #SCROLL_SEAM_OFFSET
  ; handle wraparound
  BCS :+
    CLC
    ADC #LEVEL_LENGTH
  :

  STA chr_row

  LSHIFT 2
  TAY

  LDA level+2,y ; flags for this row
  AND #LevelFlags::ROW_CONTAINS_CHR
  BEQ done

    ; the relevant row has been identified.
    ; for the CHR allocator
    ; report the current CHR tile occupying this
    ; location.

    JSR get_deleted_chr_tile ; clobbers A and X



    ; if it contains CHR, it won't after this run
    LDA level+2,y
    AND #<~LevelFlags::ROW_CONTAINS_CHR
    STA level+2,y

  TYA
  CMP #LEVEL_TOTAL_BYTES/2
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_BYTES/2
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
  CPY #LEVEL_LENGTH/2*4
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

  VRAM_BUFFER_BEGIN
  VRAM_BUFFER_SET_DATA_LENGTH #LEVEL_TOTAL_WIDTH
  VRAM_BUFFER_SET_NAMETABLE_POS ppu_addr

  LDA level,y
  STA current_row_road_start
  INY
  LDA level,y
  STA current_row_road_end
  INY
  LDA level,y
  STA current_row_flags

  LDA #$00
  STA current_row_offset

loop_draw_row:
  JSR draw_road_tile ; must remember registers

  INC current_row_offset
  LDA current_row_offset
  CMP #LEVEL_TOTAL_WIDTH
  BCC loop_draw_row
  VRAM_BUFFER_END
done:
  RTS
.endproc

.proc draw_road_tile
  current_row_offset := locals+0
  ppu_addr := locals+1 ; 2 bytes, big endian
  current_row_road_start := locals+3
  current_row_road_end := locals+4
  current_row_flags := locals+5

  LDA current_row_offset
  CMP current_row_road_start
  BEQ draw_road_edge_left
  BCC draw_grass
  CMP current_row_road_end
  BEQ draw_road_edge_right
  BCS draw_grass
draw_road:
  LDA #$3D ; road
  JMP done
draw_road_edge_left:
  LDA current_row_flags
  AND #LevelFlags::DRAW_LEFT_SLANT_LEFT
  BEQ :+
    LDA #$BC
    JMP done
  :
  AND #LevelFlags::DRAW_LEFT_SLANT_RIGHT
  BEQ :+
    LDA #$BD
    JMP done
  :
  LDA #$3E ; road left edge
  JMP done
draw_road_edge_right:
  LDA current_row_flags
  AND #LevelFlags::DRAW_RIGHT_SLANT_LEFT
  BEQ :+
    LDA #$BF
    JMP done
  :
  AND #LevelFlags::DRAW_RIGHT_SLANT_RIGHT
  BEQ :+
    LDA #$BE
    JMP done
  :
  LDA #$3F ; road right edge
  JMP done

draw_grass:
  LDA #$3C ; grass
done:
  VRAM_BUFFER_WRITE_A
  RTS
.endproc

.proc level_write_chr
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR

  LDX #$00
loop_draw_bank_0:
  LDA background_bank_0,x
  STA PPUDATA
  INX
  CPX #LEVEL_BACKGROUND_BANK_SIZE
  BCC loop_draw_bank_0

  LDA #$2B
  STA PPUADDR
  LDA #$C0
  STA PPUADDR

  LDX #$00
loop_draw_bank_1:
  LDA background_bank_1,x
  STA PPUDATA
  INX
  CPX #LEVEL_BACKGROUND_BANK_SIZE
  BCC loop_draw_bank_1
  RTS
.endproc

; TODO do this during vblank instead
.proc level_write_palettes
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

.proc level_draw_initial
; determine nametable address from row index
; for each row:
; get row offset (in bytes) ASL 3 (multiply by 8)
; this turns 4 into 20, 8 into 40 etc

  LDX #$00
draw_row:
  JSR level_draw_row_directly
  INX
  INX
  INX
  INX
  CPX #LEVEL_LENGTH*LEVEL_ROW_SIZE
  BCC draw_row

  JSR level_write_palettes
  JSR level_write_chr
  RTS
.endproc

.proc level_draw_row_directly
  ppu_addr := locals+0 ; 2 bytes, big endian
  current_row_road_start := locals+2
  current_row_road_end := locals+3
  current_row_offset := locals+4

  LDA #$00
  STA ppu_addr+0
  STA ppu_addr+1
  
  TXA
  CMP #LEVEL_TOTAL_BYTES/2
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_BYTES/2
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
  BEQ draw_road_left
  BCC draw_grass
  CMP current_row_road_end
  BEQ draw_road_right
  BCS draw_grass
draw_road:
  LDA #$3D ; road
  JMP inc_row_offset
draw_road_left:
  LDA #$3E ; road left edge
  JMP inc_row_offset
draw_road_right:
  LDA #$3F ; road right edge
  JMP inc_row_offset

draw_grass:
  LDA #$3C ; grass
inc_row_offset:
  STA PPUDATA
  INC current_row_offset
  LDA current_row_offset
  CMP #LEVEL_TOTAL_WIDTH
  BCC loop_draw_row
  RTS
.endproc

sprite_palettes:
.byte $0F, $0F, $15, $30
.byte $0F, $0F, $12, $30
.byte $0F, $0F, $26, $30
.byte $0F, $0F, $2A, $30

bg_palette:
.byte $0F, $10, $2A, $30

background_bank_0:
.incbin "background_bank_0.chr"
background_bank_1:
.incbin "background_bank_1.chr"