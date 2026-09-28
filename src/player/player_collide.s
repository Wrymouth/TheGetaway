.include "common.inc"
.include "player.inc"
.include "player_internal.inc"
.include "level.inc"

.proc player_collide_with_grass
  GRASS_DAMAGE = 35
  LDY player_y+1
  LDA level_start,y
  CMP level_end,y
  BCS wrapped
regular:
  LDA player_x+1
  CMP level_start,y
  BCC hurt
  LDA player_x+1
  CMP level_end,y
  BEQ done
  BCC done
  JMP hurt
wrapped:
  LDA player_x+1
  CMP level_end,y
  BEQ done
  BCC done

  LDA player_x+1
  CMP level_start,y
  BCS done
hurt:
  SEC
  LDA player_health
  SBC #<GRASS_DAMAGE
  STA player_health
  LDA player_health+1
  SBC #>GRASS_DAMAGE
  STA player_health+1
  BCS :+
    LDA #$00
    STA player_health
    STA player_health+1
  :
done:
  RTS
.endproc