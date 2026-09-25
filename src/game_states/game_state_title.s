.include "common.inc"
.include "game_states.inc"
.include "controller.inc"

.proc game_state_title
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    ORA #GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags
    
    JSR load_title_chr
    JSR draw_title_backgrounds
    
    LDA game_status_flags
    AND #<~GameStatusFlags::NMI_SKIP_SCROLL
    STA game_status_flags

    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :
  LDA pad1_first_pressed
  AND #BTN_START
  BEQ done
  LDA #GameStates::ENTER_GAME
  JSR set_game_state
done:
  RTS
.endproc

.proc load_title_chr
  RTS
.endproc

.proc draw_title_backgrounds
  RTS
.endproc
