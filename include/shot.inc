NUM_SHOTS = 5

SHOT_DAMAGE = 5

.enum ShotFlags
  ACTIVE = $80
  VISIBLE = $40
.endenum

.code
.global shots_init
.global shot_create
.global shots_update
.global shots_draw

.global shot_chr