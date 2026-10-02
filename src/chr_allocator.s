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
  TXA
  LSR
  TAX
  LDA level_flags,x ; flags
  ORA #LevelFlags::ROW_CONTAINS_CHR
  STA level_flags,x

  TXA
  ASL ; mult by 2 to go to CHR tile location
  TAX

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
  TAY
  ASL
  STA dest_tile

  ; should we even be drawing here?
  LDA level_flags,y
  AND #LevelFlags::ROW_CONTAINS_CHR
  BNE done

  ; if the row does not contain CHR, it will now
  LDA level_flags,y
  ORA #LevelFlags::ROW_CONTAINS_CHR
  STA level_flags,y

  LDA dest_tile
  CMP #LEVEL_LENGTH
  BCC :+
    SEC
    SBC #LEVEL_LENGTH
:
  
  ; mul 16, 16 bit result
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
  CPY #LEVEL_LENGTH/2
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
  CMP #LEVEL_LENGTH ; watch out! if the tile is greater than 60, it should be written accurately to the next bank!
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
  CMP #LEVEL_LENGTH ; watch out! if the tile is greater than 60, it should be written accurately to the next bank!
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
  tile := locals+8
  real_tile := locals+8 ; alias

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
; locals arg: new pointer to tile
; Y = source offset
.proc replace_chr_tile
  ppu_addr := locals+12 ; 2 bytes, make sure these aren't used by the caller
  ptr := locals+14 ; 2 bytes

  LDA chr_ptr_lo,y
  CMP ptr+0
  BNE start

  LDA chr_ptr_hi,y
  CMP ptr+1
  BEQ done ; they're the same, don't act

start:
  LDA ptr+0
  STA chr_ptr_lo,y
  LDA ptr+1
  STA chr_ptr_hi,y

  LDA #$00
  STA ppu_addr
  STA ppu_addr+1
  ; demand this tile be rewritten during the draw phase of this frame

  ; immediately write this to the relevant nametable data
  LDA chr_map,y
  TAX
  ; convert this to a nametable entry
  CMP #LEVEL_LENGTH
  BCC :+
    SEC
    SBC #128 ; get the original offset back, to properly set the nametable
  :

  ; mul 16, 16 bit result
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

  VRAM_BUFFER_BEGIN
  VRAM_BUFFER_SET_DATA_LENGTH #CHR_TILE_SIZE ; just one tile
  VRAM_BUFFER_SET_NAMETABLE_POS ppu_addr
  
  ; duplicate of write_chr_tile, because of locals clashing
  PUSH_Y ; not getting around this
  LDY #$00
loop:
  LDA (ptr),y
  VRAM_BUFFER_WRITE_A
  INY
  CPY #CHR_TILE_SIZE
  BCC loop
  VRAM_BUFFER_END
  PULL_Y

done:
  RTS
.endproc

; TODO handle score


blank_chr_tile:
  .incbin "blank_tile.chr"

initial_chr_layout_lo:
  .lobytes player_chr_idle_0, player_chr_idle_1, player_chr_idle_2, health_bar_7_chr, health_bar_full_chr, health_bar_empty_chr
  .repeat 8
    .byte <blank_chr_tile
  .endrepeat
  .lobytes shot_chr, enemy_car_chr_0, enemy_car_chr_1, enemy_car_chr_2, civilian_car_chr_0, civilian_car_chr_1, civilian_car_chr_2
  .repeat 35
    .byte <blank_chr_tile
  .endrepeat
initial_chr_layout_hi:
  .hibytes player_chr_idle_0, player_chr_idle_1, player_chr_idle_2, health_bar_7_chr, health_bar_full_chr, health_bar_empty_chr
  .repeat 8
    .byte >blank_chr_tile
  .endrepeat
  .hibytes shot_chr, enemy_car_chr_0, enemy_car_chr_1, enemy_car_chr_2, civilian_car_chr_0, civilian_car_chr_1, civilian_car_chr_2 
  .repeat 35
    .byte >blank_chr_tile
  .endrepeat
