.include "common.inc"
.include "game_states.inc"

.code 

.proc game_state_game_over
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    ; first set the CHR

    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  RTS
.endproc


