.define DEBUG FALSE

.macro DEBUG_SET_GRAYSCALE
.if DEBUG = TRUE
  LDA ppumask_settings
  ORA #$01
  STA ppumask_settings
  STA PPUMASK
.endif
.endmacro

.macro DEBUG_CLEAR_GRAYSCALE
.if DEBUG = TRUE
  LDA ppumask_settings
  EOR #$01
  STA ppumask_settings
  STA PPUMASK
.endif
.endmacro