.include "common.inc"
.include "level.inc"
.include "camera.inc"
.include "background.inc"
.include "chr_allocator.inc"
.include "random.inc"

.zeropage
current_row_width: .res 1
current_row_start: .res 1

.segment "LEVEL" :bss :mem $0300 :size $0100
level_start: .res 60
level_end: .res 60
level_flags: .res 60

.code
.proc level_init
  ; initialize the level as a single long straight road
  LDX #$00
  LDA #INITIAL_ROAD_START
  STA current_row_start
  LDA #INITIAL_ROAD_WIDTH
  STA current_row_width
loop:
  LDA current_row_start
  STA level_start,x
  LDA current_row_start
  CLC
  ADC current_row_width
  ; handle wraparound
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_WIDTH
  :
  STA level_end,x
  LDA #$00
  STA level_flags,x
  INX
  CPX #LEVEL_LENGTH
  BCC loop
  RTS
.endproc

; update the RAM level data with random new values
.proc level_update
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  LDA #$00
  STA row_flags
  LDA camera_y+1
  SEC
  SBC #SCROLL_SEAM_OFFSET
  ; handle wraparound
  BCS :+
    CLC
    ADC #LEVEL_LENGTH
  :
  TAX

  ; has this row already been generated?
  LDA level_flags,x ; flags
  AND #LevelFlags::ROW_WAS_GENERATED
  BNE done

  JSR generate_random_level_data_pre

  LDA current_row_start
  STA level_start,x
  
  ; standard row width adjust
  LDA current_row_start
  CLC
  ADC row_width ; the persistent road_width will be set in the generate routine
  ; handle wraparound
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_WIDTH
  :

  STA level_end,x
  
  LDA level_flags,x
  AND #LevelFlags::ROW_CONTAINS_CHR
  ORA row_flags
  ORA #LevelFlags::ROW_WAS_GENERATED
  STA level_flags,x

  JSR generate_random_level_data_post

  ; unset the "generated" flag for the previous row
  INX
  CPX #LEVEL_LENGTH
  BCC :+
    LDX #$00
  :
  LDA level_flags,x
  AND #<~LevelFlags::ROW_WAS_GENERATED
  STA level_flags,x
done:  
  RTS
.endproc

; format:
; top 5 bits: equal to %11111000 means a road change will happen
; bottom 2 bits: determine what will happen in this road change event
.proc generate_random_level_data_pre
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  JSR get_rand_byte ; first byte: does a road change happen at all?

  ; 1/32 chance of a road change
  LDA rand_value
  ; LDA #LEVEL_GEN_CHANGE_THRESHOLD-1 ; DEBUG: always have straight road
  CMP #LEVEL_GEN_CHANGE_THRESHOLD
  STA change_road_data
  BCC no_change

  INC16_L rand_seed
  JSR get_rand_byte ; second byte: what change?
  LDA rand_value
  STA current_instruction

  ; LDA #LevelGenInstructions::VEER_RIGHT-1 ; DEBUG: override random road gen value
  ; STA current_instruction

  CMP #LevelGenInstructions::VEER_LEFT
  BCC handle_veer_left_pre
  CMP #LevelGenInstructions::VEER_RIGHT
  BCC handle_veer_right_pre
  CMP #LevelGenInstructions::WIDEN
  BCC handle_widen_pre
  
  JMP handle_thin_pre

no_change:
  LDA current_row_width
  STA row_width
  RTS
.endproc

.proc handle_veer_left_pre
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  LDA current_row_start
  SEC
  SBC #$01
  ; handle wraparound
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    CLC
    ADC #LEVEL_TOTAL_WIDTH
  :
  STA current_row_start

  LDA current_row_width
  CLC
  ADC #$01 ; NOTE: assuming this will NEVER overflow, because MAX_WIDTH will be appropriately configured.
  STA row_width

  LDA row_flags
  ORA #LevelFlags::DRAW_LEFT_SLANT_LEFT|LevelFlags::DRAW_RIGHT_SLANT_LEFT
  STA row_flags
  RTS
.endproc

.proc handle_veer_right_pre
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  LDA current_row_width
  CLC
  ADC #$01 ; NOTE: assuming this will NEVER overflow, because MAX_WIDTH will be appropriately configured.
  STA row_width

  LDA row_flags
  ORA #LevelFlags::DRAW_LEFT_SLANT_RIGHT|LevelFlags::DRAW_RIGHT_SLANT_RIGHT
  STA row_flags
  RTS
.endproc

.proc handle_widen_pre
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  LDA current_row_width
  CLC
  ADC #$02
  CMP #LEVEL_MAX_WIDTH ; TODO: make this variable based on ruleset
  BEQ store
  BCC store
  ; if widen isn't possible, thin instead
  LDA #LevelGenInstructions::THIN-1
  STA current_instruction
  JMP handle_thin_pre
store:
  STA current_row_width
  STA row_width

  LDA current_row_start
  SEC
  SBC #$01
  ; handle wraparound
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    CLC
    ADC #LEVEL_TOTAL_WIDTH
  :
  STA current_row_start

  LDA row_flags
  ORA #LevelFlags::DRAW_LEFT_SLANT_LEFT|LevelFlags::DRAW_RIGHT_SLANT_RIGHT
  STA row_flags
  RTS
.endproc

.proc handle_thin_pre
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  ; test whether the thinning is possible
  LDA current_row_width
  STA row_width
  SEC
  SBC #$02
  CMP #LEVEL_MIN_WIDTH ; TODO: make this variable based on ruleset
  BCS :+
    LDA #LevelGenInstructions::WIDEN-1
    STA current_instruction
    JMP handle_widen_pre
  :
  ; do not store, that happens in post
  LDA row_flags
  ORA #LevelFlags::DRAW_LEFT_SLANT_RIGHT|LevelFlags::DRAW_RIGHT_SLANT_LEFT
  STA row_flags

  RTS
.endproc

; use the random value from earlier to apply changes to the road post-generation
; used to more forgivingly handle road changes by not affecting collision
.proc generate_random_level_data_post
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  LDA change_road_data
  CMP #LEVEL_GEN_CHANGE_THRESHOLD
  BCC no_change

  LDA current_instruction
  
  CMP #LevelGenInstructions::VEER_LEFT
  BCC no_change
  CMP #LevelGenInstructions::VEER_RIGHT
  BCC handle_veer_right_post
  CMP #LevelGenInstructions::WIDEN
  BCC no_change

  JMP handle_thin_post

no_change:
  RTS
.endproc

; no handle_veer_left_post or handle_widen_post, it would be empty

.proc handle_veer_right_post
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3
  
  LDA current_row_start
  CLC
  ADC #$01
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_WIDTH
  :
  STA current_row_start
  RTS
.endproc

.proc handle_thin_post
  row_width := locals+0
  row_flags := locals+1
  change_road_data := locals+2
  current_instruction := locals+3

  ; the pre routine has already determined this to be safe
  LDA current_row_width
  SEC
  SBC #$02
  STA current_row_width

  LDA current_row_start
  CLC
  ADC #$01
  CMP #LEVEL_TOTAL_WIDTH
  BCC :+
    SEC
    SBC #LEVEL_TOTAL_WIDTH
  :
  STA current_row_start

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
  TAY

  LDA level_flags,y ; flags for this row
  AND #LevelFlags::ROW_CONTAINS_CHR
  BEQ done

    ; the relevant row has been identified.
    ; for the CHR allocator
    ; report the current CHR tile occupying this
    ; location.

    JSR get_deleted_chr_tile ; clobbers A and X



    ; if it contains CHR, it won't after this run
    LDA level_flags,y
    AND #<~LevelFlags::ROW_CONTAINS_CHR
    STA level_flags,y

  TYA
  CMP #LEVEL_LENGTH/2
  BCC :+
    SEC
    SBC #LEVEL_LENGTH/2
  :

  ; mul 8, 16 bit result
  ASL
  ROL ppu_addr+0
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

  LDA level_start,y
  STA current_row_road_start
  LDA level_end,y
  STA current_row_road_end
  LDA level_flags,y
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
  ; now that we've drawn the road, clear the draw flags
  LDA level_flags,y
  AND #<~LevelFlags::DRAW_LEFT_SLANT_LEFT|LevelFlags::DRAW_LEFT_SLANT_RIGHT|LevelFlags::DRAW_RIGHT_SLANT_LEFT|LevelFlags::DRAW_RIGHT_SLANT_RIGHT
  STA level_flags,y
done:
  RTS
.endproc

.proc draw_road_tile
  current_row_offset := locals+0
  ppu_addr := locals+1 ; 2 bytes, big endian
  current_row_road_start := locals+3
  current_row_road_end := locals+4
  current_row_flags := locals+5

  LDA current_row_road_start
  CMP current_row_road_end
  BCS wrapped
regular:
  ; in regular mode, draw grass until the road starts
  LDA current_row_offset
  CMP current_row_road_start
  BEQ draw_road_edge_left
  BCC draw_grass
  CMP current_row_road_end
  BEQ draw_road_edge_right
  BCS draw_grass
  JMP draw_road
wrapped:
  ; in wrapped road, draw road until the road ends
  LDA current_row_offset
  CMP current_row_road_end
  BEQ draw_road_edge_right
  BCC draw_road
  CMP current_row_road_start
  BEQ draw_road_edge_left
  BCS draw_road
  JMP draw_grass
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
  LDA current_row_flags
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
  LDA current_row_flags
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
  VRAM_BUFFER_BEGIN
  VRAM_BUFFER_SET_DATA_LENGTH #32
  VRAM_BUFFER_SET_NAMETABLE_BYTES #$3F, #$00
  .repeat 4

    LDA bg_palette+0
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+1
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+2
    VRAM_BUFFER_WRITE_A
    LDA bg_palette+3
    VRAM_BUFFER_WRITE_A
  .endrepeat
  .repeat 16, i
    LDA sprite_palettes+i
    VRAM_BUFFER_WRITE_A
  .endrepeat
  VRAM_BUFFER_END
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
  CPX #LEVEL_LENGTH
  BCC draw_row

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
  CMP #LEVEL_LENGTH/2
  BCC :+
    SEC
    SBC #LEVEL_LENGTH/2
:
  ; mul 32, 16 bit result
  ASL
  ROL ppu_addr+0
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
  CPX #LEVEL_LENGTH/2
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
  LDA level_start,x
  STA current_row_road_start
  LDA level_end,x
  STA current_row_road_end

  LDY #$00

loop_draw_row:
  CPY current_row_road_start
  BEQ draw_road_left
  BCC draw_grass
  CPY current_row_road_end
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
  INY
  CPY #LEVEL_TOTAL_WIDTH
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