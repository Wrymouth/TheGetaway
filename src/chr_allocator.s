.include "common.inc"
.include "chr_allocator.inc"

.zeropage

.code
.proc chr_allocator_init
  RTS
.endproc

; write a row of CHR data to the nametables
.proc write_chr_row
  RTS
.endproc

; get the current location of a given CHR tile
.proc get_chr_tile_index
  RTS
.endproc

; update a tile, for example for health or score
.proc write_chr_tile
  RTS
.endproc
