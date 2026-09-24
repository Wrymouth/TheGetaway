.include "common.inc"
.include "chr_allocator.inc"
.include "level.inc"
.include "camera.inc"
.include "background.inc"

.zeropage
  chr_tile_to_draw: .res 1 ; the level drawing routine communicates this

.segment "CHR_ALLOCATOR" :bss :mem $0400 :size $0100

  ; tells the true CHR index of each tile
  ; key value pair:
  ;   index/key = source tile
  ;   value = current tile in VRAM
  chr_map: .res NUM_CHR_TILES 
  
  ; pointers to the original tile datas, ordered by SOURCE not current
  chr_ptr_lo: .res NUM_CHR_TILES
  chr_ptr_hi: .res NUM_CHR_TILES

.code

; $21C0 to $2920 must be initialized as CHR 
; that's tile indices 28 to 79
.proc chr_allocator_init
  chr_initial_offset := locals+0
  LDA camera_y+1 ; by now already initialized
  SEC
  SBC #(LEVEL_LENGTH/2)-(SCROLL_SEAM_OFFSET+1)
  ASL
  STA chr_initial_offset
  LDX #$00
loop_initialize_map:
  TXA
  CLC
  ADC chr_initial_offset
  CMP #60 ; watch out! if the tile is greater than 60, it should be written accurately to the next bank!
  BCC :+
    CLC
    ADC #68 ; this realigns it
  :
  STA chr_map,x
  INX
  CPX #NUM_CHR_TILES
  BCC loop_initialize_map

  LDX #$00
loop_zero_out_pointers:
  LDA initial_chr_layout_lo,x
  STA chr_ptr_lo,x
  LDA initial_chr_layout_hi,x
  STA chr_ptr_hi,x
  INX
  CPX #NUM_CHR_TILES
  BCC loop_zero_out_pointers

  LDA #$00
  STA chr_tile_to_draw

  RTS
.endproc

.proc draw_initial_chr_space
  LDA camera_y+1 ; by now already initialized
  SEC
  SBC #(LEVEL_LENGTH/2)-(SCROLL_SEAM_OFFSET+1)
  ASL
  TAX ; X contains location

  LDY #$00 ; Y contains source tile to draw there
draw_row:
  ; PUSH_X
  TXA
  PHA

  ASL ; multiply by 2 to get the level data offset
  TAX
  LDA level+2,x ; flags
  ORA #LevelFlags::ROW_CONTAINS_CHR
  STA level+2,x

  ; PULL_X
  PLA
  TAX
  ; this hits the attr region. that needs to be fixed next
  JSR draw_chr_tile_directly
  INX
  INY
  JSR draw_chr_tile_directly
  INX
  INY
  CPY #NUM_CHR_TILES
  BCC draw_row

  RTS
.endproc

; X contains the tile dest location (0-120)
; Y contains the tile to draw (0-52)
.proc draw_chr_tile_directly
  ppu_addr := locals+0 ; 2 bytes, big endian
  tile_ptr := locals+2 ; 2 bytes, little endian
  
  ; compute nametable addr
  LDA #$00
  STA ppu_addr+0
  STA ppu_addr+1

  ; mul 16, 16 bit result
  TXA
  CMP #LEVEL_LENGTH
  BCC :+
    SEC
    SBC #LEVEL_LENGTH
:
  ASL
  ROL ppu_addr+0
  ASL
  ROL ppu_addr+0
  ASL
  ROL ppu_addr+0
  ASL
  ROL ppu_addr+0
  STA ppu_addr+1

  ; add base nametable address
  LDA ppu_addr+0
  CPX #LEVEL_LENGTH
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

  LDA chr_ptr_lo,y
  STA tile_ptr
  LDA chr_ptr_hi,y
  STA tile_ptr+1

  PUSH_Y
  LDY #$00
draw:
  LDA (tile_ptr),y
  STA PPUDATA
  INY
  CPY #CHR_TILE_SIZE
  BCC draw
  PULL_Y
  RTS
.endproc

; write a row of CHR data to the nametables
.proc write_chr_row
  temp_ppu_addr := locals+0 ; 1 byte, just a temp for calculation
  ppu_addr := locals+1 ; 2 bytes, big endian
  tile_ptr := locals+3 ; 2 bytes
  dest_tile := locals+5 ; 1 byte

  ; compute nametable addr
  LDA #$00
  STA ppu_addr+0
  STA ppu_addr+1

  LDA camera_y+1
  CLC
  ADC #(LEVEL_LENGTH/2)+SCROLL_SEAM_OFFSET
  CMP #LEVEL_LENGTH
  ; handle wraparound
  BCC :+
    SEC
    SBC #LEVEL_LENGTH
  :
  ASL
  STA dest_tile
  ASL
  STA temp_ppu_addr

  ; should we even be drawing here?
  TAY
  INY
  INY
  LDA level,y
  AND #LevelFlags::ROW_CONTAINS_CHR
  BNE done

  ; if the row does not contain CHR, it will now
  LDA level,y
  ORA #LevelFlags::ROW_CONTAINS_CHR
  STA level,y

  LDA temp_ppu_addr
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

  ; draw the two tiles that the level deleted earlier
  LDY chr_tile_to_draw
  ; we've relocated the (source) tile, so move it in the map as well
  LDA dest_tile
  CMP #60 ; watch out! if the tile is greater than 60, it should be written accurately to the next bank!
  BCC :+
    CLC
    ADC #68 ; this realigns it
  :
  STA chr_map,y

  LDA chr_ptr_lo,y
  STA tile_ptr
  LDA chr_ptr_hi,y
  STA tile_ptr+1
  JSR write_chr_tile

  INY ; draw the one directly next to it. these are guaranteed to be linked.
  INC dest_tile

  LDA dest_tile
  CMP #60 ; watch out! if the tile is greater than 60, it should be written accurately to the next bank!
  BCC :+
    CLC
    ADC #68 ; this realigns it
  :
  STA chr_map,y

  LDA chr_ptr_lo,y
  STA tile_ptr
  LDA chr_ptr_hi,y
  STA tile_ptr+1
  JSR write_chr_tile

done:
  VRAM_BUFFER_END
  RTS
.endproc

.proc write_chr_tile
  tile_ptr := locals+3

  PUSH_Y ; not getting around this

  LDY #$00
loop:
  LDA (tile_ptr),y
  VRAM_BUFFER_WRITE_A
  INY
  CPY #CHR_TILE_SIZE
  BCC loop

  PULL_Y
  RTS
.endproc

; given a base index (in A), returns the REAL CHR index for this tile (also in A)
; clobbers X
.proc get_chr_tile_index
  tile := locals+0
  real_tile := locals+0 ; alias

  STA tile
  PUSH_X
  LDX tile
  LDA chr_map,x
  STA tile
  PULL_X
  RTS
.endproc

; given a level row (in A), returns the index of the first CHR tile that lives there
; (the second can be inferred with a +1)
.proc get_deleted_chr_tile
  LDA chr_tile_to_draw
  SEC
  SBC #$02
  BCS :+
    LDA #NUM_CHR_TILES-2
  :
  STA chr_tile_to_draw
  RTS
.endproc


; update a tile, for example for health or foliage
; X = pointer low
; Y = pointer high
.proc replace_chr_tile

  RTS
.endproc

; TODO handle score


blank_chr_tile:
  .incbin "blank_tile.chr"

initial_chr_layout_lo:
  .lobytes player_chr_idle_0, player_chr_idle_1, player_chr_idle_2
  .repeat 49
    .byte <blank_chr_tile
  .endrepeat
initial_chr_layout_hi:
  .hibytes player_chr_idle_0, player_chr_idle_1, player_chr_idle_2
  .repeat 49
    .byte >blank_chr_tile
  .endrepeat