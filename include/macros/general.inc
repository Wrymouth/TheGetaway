.macro PUSH_X_Y
  TXA
  PHA
  TYA
  PHA
.endmacro

.macro PULL_X_Y
  PLA
  TAY
  PLA
  TAX
.endmacro

.macro PUSH_X
  TXA
  PHA
.endmacro

.macro PULL_X
  PLA
  TAX
.endmacro

.macro PUSH_Y
  TYA
  PHA
.endmacro

.macro PULL_Y
  PLA
  TAY
.endmacro

.macro JSR_WITH_ADDR proc, addr
  LDA #<addr
  LDX #>addr
  JSR proc
.endmacro

; little endian
.macro INC16_L addr
  clc
  lda     addr
  adc     #$01
  sta     addr
  lda     addr+1
  adc     #$00
  sta     addr+1
.endmacro

; big endian
.macro INC16_B addr
  clc
  lda     addr+1
  adc     #$01
  sta     addr+1
  lda     addr
  adc     #$00
  sta     addr
.endmacro

.macro DEC16_B addr
  sec
  lda     addr+1
  sbc     #$01
  sta     addr+1
  lda     addr
  sbc     #$00
  sta     addr
.endmacro

.macro DEC16_L addr
  sec
  lda     addr
  sbc     #$01
  sta     addr
  lda     addr+1
  sbc     #$00
  sta     addr+1
.endmacro

.macro ADD16_L addr, value
  LDA addr+0
  CLC
  ADC value
  STA addr+0
  LDA addr+1
  ADC #$00
  STA addr+1
.endmacro

.macro ADD16_B addr, value
  LDA addr+1
  CLC
  ADC value
  STA addr+1
  LDA addr+0
  ADC #$00
  STA addr+0
.endmacro

.macro SUB16_B addr, value
  sec
  lda     addr+1
  sbc     value
  sta     addr+1
  lda     addr
  sbc     #$00
  sta     addr
.endmacro

.macro SUB16_L addr, value
  sec
  lda     addr
  sbc     value
  sta     addr
  lda     addr+1
  sbc     #$00
  sta     addr+1
.endmacro

.macro RSHIFT i
  .repeat i
  LSR
  .endrepeat
.endmacro

.macro LSHIFT i
  .repeat i
  ASL
  .endrepeat
.endmacro
