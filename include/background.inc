; vram buffer flags
VRAM_BUFFER_FLAG_INC32 = $80

VRAM_BUFFER_START = $0100
VRAM_BUFFER_SIZE = $9F

.macro VRAM_BUFFER_BEGIN
  LDX buffer_idx
.endmacro

.macro VRAM_BUFFER_SET_DATA_LENGTH length
  LDA length
  STA VRAM_BUFFER_START,x
  INX
.endmacro

.macro VRAM_BUFFER_SET_NAMETABLE_BYTES nametable_h, nametable_l
  LDA nametable_h
  STA VRAM_BUFFER_START,x
  INX
  LDA nametable_l
  STA VRAM_BUFFER_START,x
  INX
.endmacro

.macro VRAM_BUFFER_SET_NAMETABLE_POS nametable_pos
  LDA nametable_pos+0
  STA VRAM_BUFFER_START,x
  INX
  LDA nametable_pos+1
  STA VRAM_BUFFER_START,x
  INX
.endmacro

.macro VRAM_BUFFER_SET_FLAGS flags
  LDA flags
  STA VRAM_BUFFER_START,x
  INX
.endmacro

.macro VRAM_BUFFER_WRITE_A
  STA VRAM_BUFFER_START,x
  INX
.endmacro

.macro VRAM_BUFFER_END
  STX buffer_idx
.endmacro

.zeropage
.globalzp buffer_idx

.code
.global clear_vram_buffer
.global draw_buffered_gfx