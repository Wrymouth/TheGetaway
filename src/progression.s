.include "common.inc"
.include "progression.inc"
.include "score.inc"
.include "background.inc"

.zeropage
  current_phase: .res 1
  road_min_width: .res 1
  road_max_width: .res 1
  road_change_chance: .res 1

.code

.proc progression_init
  LDX #$00
  STX current_phase
  LDA min_widths,x
  STA road_min_width
  LDA max_widths,x
  STA road_max_width
  LDA road_change_thresholds,x
  STA road_change_chance
  RTS
.endproc

.proc progression_update
  ; check if we're in a phase transition
  ; check if we've hit a new phase
  LDX current_phase
  LDA score+2
  CMP phase_milestones_2,x
  BEQ check_1
  BCS inc_phase
  JMP done
check_1:
  LDA score+1
  CMP phase_milestones_1,x
  BEQ check_0
  BCS inc_phase
  JMP done
check_0:
  LDA score+0
  CMP phase_milestones_0,x
  BCC done
inc_phase:
  INX
  STX current_phase
  LDA min_widths,x
  STA road_min_width
  LDA max_widths,x
  STA road_max_width
  LDA road_change_thresholds,x 
  STA road_change_chance
  JSR set_cur_phase_palette
done:
  RTS
.endproc

.proc set_cur_phase_palette
  VRAM_BUFFER_BEGIN
  VRAM_BUFFER_SET_DATA_LENGTH #$80
  
  LDY current_phase
  LDA phase_palettes,y
  VRAM_BUFFER_WRITE_A
  
  VRAM_BUFFER_END
  RTS
.endproc

phase_milestones_0:
.byte 0, 0, 0, 0, 0, 0
phase_milestones_1:
.byte 2, 15, 30, 45, 60, 80
phase_milestones_2:
.byte $00, $00, $00, $00, $00, $00

min_widths:
.byte 10, 10, 10, 10, 10, 10

max_widths:
.byte 20, 20, 20, 20, 20, 20

road_change_thresholds:
.byte $FF, $F0, $F0, $F0, $F0, $F0

phase_palettes:
.byte $2A, $1A, $27, $21, $10, $31