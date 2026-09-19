.include "common.inc"
.include "controller.inc"

.zeropage
  ; controller tracking
  pad1_pressed: .res 1
  pad1_first_pressed: .res 1


.code

.proc read_controller1
  LDA pad1_pressed
  ; write a 1, then a 0, to CONT1
  ; to latch button states
  LDA #$01
  STA CONT1
  LDA #$00
  STA CONT1
  LDA #%00000001
  STA pad1_pressed
get_buttons:
  LDA CONT1 ; Read next button's state
  LSR A           ; Shift button state right, into carry flag
  ROL pad1_pressed        ; Rotate button state from carry flag
                  ; onto right side of pad1
                  ; and leftmost 0 of pad1 into carry flag
  BCC get_buttons ; Continue until original "1" is in carry flag
  RTS
.endproc

.proc handle_input_pad1
  pad1_previous_pressed := locals+0

  LDA pad1_pressed
  STA pad1_previous_pressed
  JSR read_controller1
  ; get held buttons
  LDA pad1_previous_pressed
  AND pad1_pressed
  EOR pad1_pressed
  STA pad1_first_pressed
  RTS
.endproc