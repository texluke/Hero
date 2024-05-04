
; Hero C64
; by Tex, 2024

*= $1000
!bin "../resources/music.sid",,126

*= $2000
!bin "../resources/sprites.bin"

*= $2800
!bin "../resources/chars.bin"

*= $5000
!bin "../resources/level_1.bin"


*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

!set debug = $01

*=$8000

border_width_x
    !byte $18

border_width_y
    !byte $32

; Hero position
; X
hero_x
    !byte $A0

hero_x_msb
    !byte $00

hero_new_x
    !byte $00

hero_new_x_msb
    !byte $00

; Y
hero_y
    !byte $96

hero_new_y
    !byte $00

main
    jsr $1003

    ; set font at $2800
    LDA $D018
    AND #$F1
    ORA #$0A
    STA $D018

    LDA #$00
    STA $dc00

    JSR .f_set_color
    JSR .f_clear

    ; load sprite
    LDA #$81
    STA $07f8

    LDA #$82
    STA $07f9

    ; Configure sprite colors
    LDA #$01         ; Set sprite color to white (color index 15)
    STA $D027        ; Store color information for sprite 0
    STA $D028        ; Store color information for sprite 1
    STA $D029        ; Store color information for sprite 2
    STA $D02A        ; Store color information for sprite 3
    STA $D02B        ; Store color information for sprite 4
    STA $D02C        ; Store color information for sprite 5
    STA $D02D        ; Store color information for sprite 6
    STA $D02E        ; Store color information for sprite 7

    ; Enable high-resolution mode for sprite 0
    LDA $D01C        ; Load current value from VIC-II Control Register 4
    AND #%00000000   ; All sprites highres
    STA $D01C        ; Store modified value back to Control Register 4

    ; Enable sprites
    LDA $D015        ; Load current value from Control Register 4
    ORA #%00000001   ; Set bit 0 to enable sprites (jero)
    STA $D015        ; Store modified value back to Control Register 4

    ; Sprite position
    LDA hero_x
    STA $D000
    STA $D002
    LDA hero_y
    STA $D001
    STA $D003

    ; JSR .f_get_sprite_row_column
    ; LDA wall
    ; JSR .f_put_char

    JSR .f_set_irq

    JMP *

.f_set_irq
    sei

    ; How to speed up interrupts disabling kernel
    ; https://codebase64.org/doku.php?id=base:speeding_up_and_optimising_demo_routines
    ; disable kernel
    ; lda #$35
    ; sta $01

    ; disable CIA  interrupt
    lda #$7f
    sta $dc0d
    sta $dd0d
    lda $dc0d
    lda $dd0d

    ; enable VIC-II to generate raster interrupts
    lda #$01
    sta $D01A

    ; raster line extra bit is msb in $d011
    lda $d011
    and #$7f
    sta $d011
    ; raster line
    lda #$20
    sta $d012

    lda #<.f_game_irq
    ldx #>.f_game_irq
    sta $0314
    stx $0315

    cli
    rts

.f_game_irq

    ; imposta la modalità 40 colonne, azzerando i registri di scroll

    ; LDA $d016
    ; ORA #$08
    ; AND #$f8
    ; STA $d016


    ; JSR .f_draw_bar
    !ifdef debug {
        LDY $d012
        CPY $d012
        BEQ *-3
        LDA #1
        STA $d020
    }

    LDX refresh_room
    CPX #$00
    BEQ no_refres_needed
    DEC refresh_room
    JSR .f_draw_room
    JSR .f_position_enemies

no_refres_needed
    ; check the better order to do that
    
    JSR .f_move_hero
    JSR .f_move_bullets

    ; hero shoot any two cycles to reduce number of bullents on the screen
    LDX hero_shoot_wait
    CPX #$01
    BEQ let_shoot
    INX
    STX hero_shoot_wait
    JMP skip_shoot
let_shoot
    LDX #$00
    STX hero_shoot_wait
     JSR .f_hero_shooting
skip_shoot   
    
    JSR .f_check_hero_bullets_collision
    JSR .f_move_enemies    
            
    ; JSR .f_check_bullets_collision

    !ifdef debug {
        LDY $d012
        CPY $d012
        BEQ *-3
        LDA #0
        STA $d020
    }

    ; set next interrupt
    LDA #$ff
    STA $d012
    LDA #<.f_end_irq
    LDX #>.f_end_irq
    STA $0314
    STX $0315

    ; reset interrupt
    ASL $d019

    JMP $ea7e

.f_boder_irq
  JMP $ea7e

.f_end_irq
    JSR .f_draw_bar

    ; !ifdef debug {
    ;     LDY $d012
    ;     CPY $d012
    ;     BEQ *-3
    ;     LDA #0
    ;     STA $d020
    ; }

    jsr $1003	; play

    ; !ifdef debug {
    ;     LDY $d012
    ;     CPY $d012
    ;     BEQ *-3
    ;     LDA #0
    ;     STA $d020
    ; }

    ; set next interrupt
    LDA #$20
    STA $d012
    LDA #<.f_game_irq
    LDX #>.f_game_irq
    STA $0314
    STX $0315

    ; reset interrupt
    ASL $d019

    JMP $ea7e

; Functions
.f_draw_bar
    LDA #1
    LDY $d012
    CPY $d012
    BEQ *-3
    STA $d020

    LDA #0
    LDY $d012
    CPY $d012
    BEQ *-3
    STA $d020
    RTS

.f_draw_room
    ; Print room

    LDX current_room
    DEX

    LDA LEVEL_1_Low, x
    STA $FB;
    LDA LEVEL_1_High, x
    STA $FC;

    LDY #$00
draw_room_loop_1
     ; first video zone
    LDA ($FB), y
    STA $0400, y
    DEY
    BNE draw_room_loop_1

    INC $FC;
    LDY #$00
draw_room_loop_2
    ; second video zone
    LDA ($FB), y
    STA $0500, y
    DEY
    BNE draw_room_loop_2

    INC $FC;
    LDY #$00
draw_room_loop_3
    ; third video zone
    LDA ($FB), y
    STA $0600, y
    DEY
    BNE draw_room_loop_3

    INC $FC;
    LDY #$00
draw_room_loop_4
    ; forth video zone
    CPY #$E8
    BCS draw_room_last_line
    LDA ($FB), y
    STA $0700, y
draw_room_last_line
    DEY
    BNE draw_room_loop_4

    RTS

.f_clear
    LDA #$00
    STA $d020
    STA $d021
    TAX
    LDA #$00 ; empy char from hero char-set
clrloop
    STA $0400,x
    STA $0500,x
    STA $0600,x
    CPX #$E8
    BCS clear_last_line
    ; LDA $8300, x
    STA $0700, x
clear_last_line
    DEX
    BNE clrloop
    RTS

.f_set_color
    LDA #1
    LDX #0
color_loop
    STA $d800,x
    STA $d800 + 250,x
    STA $d800 + 500,x
    STA $d800 + 750,x
    INX
    CPX #250
    bne color_loop
    RTS



.f_get_shooting_char
    JSR .f_get_hero_sprite_row_column
    ; X
    TXA
    // multiply x 8
    ASL
    ASL
    ASL
    STA tmp_A
    ; y down at least one
    INX
    LDA $D001
    SEC
    SBC border_width_y
    SEC
    SBC tmp_A
    CMP #$04
    BPL add_another_one
    CMP #$02
    BPL set_low_bullet
    ; middle
    JSR .f_get_shooting_char_middle
    JMP get_y
set_low_bullet
    JSR .f_get_shooting_char_low
    JMP get_y
add_another_one
    INX
    CMP #$06
    BPL set_upper_bullet
    ; middle
    JSR .f_get_shooting_char_middle
    JMP get_y
set_upper_bullet
    JSR .f_get_shooting_char_high
    JMP get_y
get_y
    ; store char
    STA tmp_A
    LDA hero_facing
    CMP #$01
    BEQ shoot_right
    JMP get_shooting_char_end
shoot_right
    // X (in Y registry!!)
    INY
    INY
    INY
    BCC get_shooting_char_end
get_shooting_char_end
    LDA tmp_A
    RTS

.f_get_shooting_char_high
    LDA hero_power_up
    CMP #$01
    BEQ char_high_powerup
    LDA #bullet_high
    RTS
char_high_powerup    
    LDA hero_facing
    CMP #$01
    BEQ char_high_left_powerup
    LDA #bullet_high_left_powerup
    RTS
char_high_left_powerup
    LDA #bullet_low_right_powerup
    RTS

.f_get_shooting_char_middle
    LDA hero_power_up
    CMP #$01
    BEQ char_middle_powerup
    LDA #bullet
    RTS
char_middle_powerup    
    LDA hero_facing
    CMP #$01
    BEQ char_middle_right_powerup
    LDA #bullet_left_powerup
    RTS
char_middle_right_powerup
    LDA #bullet_right_powerup
    RTS

.f_get_shooting_char_low
    LDA hero_power_up
    CMP #$01
    BEQ char_low_powerup
    LDA #bullet_low
    RTS
char_low_powerup    
    LDA hero_facing
    CMP #$01
    BEQ char_low_right_powerup
    LDA #bullet_low_left_powerup
char_low_right_powerup
    LDA #bullet_low_right_powerup
    RTS

.f_check_bullets_collision
    ; loop on all enemies

    LDA $D01F
    CMP #$00
    BEQ nob_collision
    ; sprite to backgroup collision
    LDA #$01
nob_collision
    ; LDA #$04
    ; JSR .f_get_sprite_row_column
    ; LDA #04
    ; JSR .f_put_char
    ; LDA #$03
    ; JSR .f_get_sprite_row_column
    ; LDA #$03
    ; JSR .f_put_char
    ; LDA #$02
    ; JSR .f_get_sprite_row_column
    ; LDA #$02
    ; JSR .f_put_char



;     LDX #$02
; check_next_enemy
;     LDA enemy_sprites, x
;     CMP #$FF
;     BEQ bullets_collision_end
;     CMP #$00
;     BEQ go_next_enemy

;     STX tmp_X
;     STA tmp_A
;     TXA
;     JSR .f_get_sprite_row_column
;     LDA #$01
;     JSR .f_put_char

;     LDA tmp_A
;     LDX tmp_X
; go_next_enemy
;     TXA
;     CLC
;     ADC #$05
;     TAX
;     JMP check_next_enemy
; bullets_collision_end
    RTS

.f_check_enemies_collision
    RTS

.f_check_backgroud_collision

check_exit_left
    LDA hero_new_x_msb
    CMP #$00
    BNE get_column
    LDA hero_new_x
    SEC
    SBC border_width_x
    BMI check_carry
    JMP get_column_msb
check_carry
    BCS get_column_msb
    JMP y_0x00
get_column
    ; check coming from

    ; hero msb = 1
    ; LDA hero_facing
    ; CMP #$00 ; facing left
    ; BEQ contine_get_column
    LDA hero_new_x
    CMP #$40 ; why 0x40 (64)??
    BCS y_0x40 ; branch if major than
contine_get_column
    LDA hero_new_x
    SEC
    SBC border_width_x
get_column_msb
    STA tmp_A
    LDA hero_new_x_msb
    AND #$01
    SBC #$00
    LSR
    LDA tmp_A
    ROR
    LSR
    LSR
    TAY ; column
    INY ; check collision at sprite middle
    JMP get_row
y_0x00
    LDY #$00
    JMP get_row
y_0x40
    LDA hero_new_x_msb
    LDY #$27 ; set last column (39)

get_row
    LDA hero_new_y
    BMI get_row_positive
    SEC
    SBC border_width_y
    BMI x_0x00
    LSR
    LSR
    LSR
    JMP set_row
get_row_positive
    SEC
    SBC border_width_y
    LSR
    LSR
    LSR
    JMP set_row
x_0x00
    LDA #$00
set_row
    TAX ; row
    ; and now check for collision
    CPY #$27
    BEQ check_only_current ; check last column (39)
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    DEX
    DEX
    INY
check_only_current
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char
    CMP wall
    BEQ hit
    LDA #$00
    JMP f_check_backgroud_collision_end
hit
    LDA #01
    ; JSR .f_put_char
f_check_backgroud_collision_end
    RTS

; Include sources
!source "src/bullet.asm"
!source "src/common.asm"
!source "src/const.asm"
!source "src/enemy.asm"
!source "src/hero.asm"
!source "src/variables.asm"

