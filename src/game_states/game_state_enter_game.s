.include "common.inc"
.include "game_states.inc"
.include "player.inc"
.include "npc_cars.inc"
.include "level.inc"
.include "chr_allocator.inc"

.proc game_state_enter_game
  LDA game_status_flags
  AND #GameStatusFlags::STATE_SWITCHED
  BEQ :+
    LDA game_status_flags
    EOR #GameStatusFlags::STATE_SWITCHED
    STA game_status_flags
  :

  JSR player_init
  JSR npc_cars_init
  ; initialize level RAM to just straight roads for two screens
  JSR level_init
  
  JSR camera_init

  JSR chr_allocator_init

  LDA game_status_flags
  ORA #GameStatusFlags::NMI_SKIP_SCROLL
  STA game_status_flags

  ; draw initial background from level RAM and write CHR data
  JSR level_draw_initial
  JSR draw_initial_chr_space



  LDA game_status_flags
  AND #<~GameStatusFlags::NMI_SKIP_SCROLL
  STA game_status_flags



  LDA #%00011110
  STA ppumask_settings

  JSR level_write_palettes
  

  LDA #GameStates::GAME
  JSR set_game_state
  
  RTS
.endproc