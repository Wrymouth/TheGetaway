.include "common.inc"
.include "score.inc"

SCORE_DIGIT_PLANE_SIZE = 4 ; bytes

.zeropage
  score: .res 3 ; base 100, 6 digits

.segment "SCORE" :mem $0500 :size $80 :bss
  score_chr_0: .res 16
  score_chr_1: .res 16
  score_chr_2: .res 16

.code
.proc score_init
  LDA #$00
  STA score+0
  STA score+1
  STA score+2
  RTS
.endproc

.proc score_update
  RTS
.endproc

.proc score_draw
  RTS
.endproc

.proc write_score_chr_to_ram
  
  RTS
.endproc

; A = amount, guaranteed greater than 0 by this point
.proc add_score
  amount := locals+0

  STA amount



  RTS
.endproc

base_100_to_bcd:
  .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19
  .byte $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
  .byte $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59
  .byte $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79
  .byte $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $90, $91, $92, $93, $94, $95, $96, $97, $98, $99

score_chr_0_plane_0:
  .incbin "score/score_0_plane_0.chr"
score_chr_0_plane_1:
  .incbin "score/score_0_plane_1.chr"

score_chr_1_plane_0:
  .incbin "score/score_1_plane_0.chr"
score_chr_1_plane_1:
  .incbin "score/score_1_plane_1.chr"

score_chr_2_plane_0:
  .incbin "score/score_2_plane_0.chr"
score_chr_2_plane_1:
  .incbin "score/score_2_plane_1.chr"

score_chr_3_plane_0:
  .incbin "score/score_3_plane_0.chr"
score_chr_3_plane_1:
  .incbin "score/score_3_plane_1.chr"

score_chr_4_plane_0:
  .incbin "score/score_4_plane_0.chr"
score_chr_4_plane_1:
  .incbin "score/score_4_plane_1.chr"

score_chr_5_plane_0:
  .incbin "score/score_5_plane_0.chr"
score_chr_5_plane_1:
  .incbin "score/score_5_plane_1.chr"

score_chr_6_plane_0:
  .incbin "score/score_6_plane_0.chr"
score_chr_6_plane_1:
  .incbin "score/score_6_plane_1.chr"

score_chr_7_plane_0:
  .incbin "score/score_7_plane_0.chr"
score_chr_7_plane_1:
  .incbin "score/score_7_plane_1.chr"

score_chr_8_plane_0:
  .incbin "score/score_8_plane_0.chr"
score_chr_8_plane_1:
  .incbin "score/score_8_plane_1.chr"

score_chr_9_plane_0:
  .incbin "score/score_9_plane_0.chr"
score_chr_9_plane_1:
  .incbin "score/score_9_plane_1.chr"