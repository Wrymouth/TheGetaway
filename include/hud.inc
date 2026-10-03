HEALTH_BAR_BASE_X = 200
HEALTH_BAR_BASE_Y = 30

.code

.global hud_init
.global hud_update
.global hud_draw

.define health_bar_partials health_bar_empty_chr, health_bar_1_chr, health_bar_2_chr, health_bar_3_chr, health_bar_4_chr, health_bar_5_chr, health_bar_6_chr, health_bar_7_chr

.global health_bar_full_chr
.global health_bar_partials
