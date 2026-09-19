.include "hardware_constants.inc"
.include "macros/general.inc"
.include "macros/debug.inc"
.include "common_zeropage.inc"

.define TRUE 1
.define FALSE 0

; game status
.enum GameStatusFlags
  NMI_SKIP_SCROLL = $80
  STATE_SWITCHED = $02
  PAUSED = $01
.endenum