.enum GameStates
  LOGOS
  TITLE
  ENTER_GAME
  GAME
  LOSE
  GAME_OVER
.endenum

.define game_states game_state_logos, game_state_title, game_state_enter_game, game_state_game, game_state_lose, game_state_game_over
.code
.global set_game_state, do_game_state
.global game_states