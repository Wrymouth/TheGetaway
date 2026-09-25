.include "random.inc"

.zeropage
  rand_seed: .res 2
  rand_value: .res 1

.code

.proc get_rand_byte

  lda rand_seed+1
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr ; shift to consume zeroes on left...
	lsr
	lsr
	sta rand_seed+1 ; now recreate the remaining bits in reverse order... %111
	lsr
	eor rand_seed+1
	lsr
	eor rand_seed+1
	eor rand_seed+0 ; recombine with original low byte
	sta rand_seed+1
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta rand_seed+0
	asl
	eor rand_seed+0
	asl
	eor rand_seed+0
	asl
	asl
	asl
	eor rand_seed+0
	sta rand_seed+0
	sta rand_value
  RTS
.endproc