.include "common.inc"
.include "game_states.inc"

.zeropage
  game_state: .res 1

.code

.proc set_game_state
  STA game_state
  LDA game_status_flags
  ORA #GameStatusFlags::STATE_SWITCHED
  STA game_status_flags
  RTS
.endproc

.proc do_game_state
  game_state_address := locals+0 ; 2 bytes
  LDX game_state
  LDA game_states_l,x
  STA game_state_address+0
  LDA game_states_h,x
  STA game_state_address+1

  JMP (game_state_address)
.endproc

game_states_l:
.lobytes game_states
game_states_h:
.hibytes game_states