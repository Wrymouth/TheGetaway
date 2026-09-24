NUM_CHR_TILES = 56

CHR_TILE_SIZE = 16 ; bytes

.code
.global chr_allocator_init
.global draw_initial_chr_space
.global write_chr_row
.global write_chr_tile
.global get_chr_tile_index
.global get_deleted_chr_tile