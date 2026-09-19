.segment "HEADER"
  .byte "NES", $1a
  .byte 2               ; 32KB of PRG ROM, as two 16KB banks
  .byte 0               ; NO CHR ROM
  .byte $A0, $D8        ; mapper 218 (NROM), horizontal mirroring
  .res 8, $00