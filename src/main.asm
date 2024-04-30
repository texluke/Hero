
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
    jsr $1000

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
    JSR .f_hero_shooting    
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

.f_position_enemies
    ; disable enemies sprite
    LDA $D015
    AND #%00000011
    STA $D015
    ; reset MSB for all enemies
    LDA $D010
    AND #%00000011
    STA $D010
    ; reset streatched for all enemied
    LDA $D01D
    AND #%00000011
    STA $D01D
    STA $D017
    ; reset enemies array
    LDX #$00
reset_enemy_array    
    LDA enemies, x
    CMP #$FF
    BEQ reset_enemy_array_completed
    LDA #$00
    STA enemies, x
    TXA
    CLC
    ADC #$05 ;
    TAX
    JMP reset_enemy_array
reset_enemy_array_completed
    LDA #$00
    STA enemy_index    
    ; use zero page accordingly to the currenet level    
    LDA #<enemies_level_1
    STA $FB; Zero page
    LDA #>enemies_level_1
    STA $FC; Zero page
    LDY #$FF
get_enemies_in_room                
    INY
    ; ROOM
    LDA ($FB), y
    CMP current_room
    BNE skip_to_next_room        
    ; NUMBER OF ENEMIES
    INY         
    LDA ($FB),y 
    TAX
get_next_enemy
    CPX #$00
    BEQ enemies_positioning_completed
    JSR .f_init_enemy
    DEX
    JMP get_next_enemy
    RTS
skip_to_next_room
    BCS enemies_positioning_completed
    INY
    LDA ($FB), y ; number of enemies
    TAX
skip_enemies_in_room
    CPX #$00
    BEQ get_enemies_in_room    
    INY ; sprite
    INY ; x
    INY ; y
    INY ; msb x  
    INY ; streatched      
    DEX
    JMP skip_enemies_in_room    
enemies_positioning_completed
    RTS

.f_init_enemy    
    ; SPRITE #
    INY
    LDA ($FB), y
    JSR .f_store_enemy_data
    CLC
    ADC #$80    
    STA $07F9, x  ; start from sprite 3, $07FA, X: 1-> N
    ; Calculate sprite coordinate registry offset
    STX tmp_X        
    DEX
    TXA
    ASL ; multiply * 2
    TAX    
    ; SPRITE X  
    INY  
    LDA ($FB), y ; sprite X        
    JSR .f_store_enemy_data
    ; D004, D006, D008, D00A, D00C, D00D
    ; D004, (x-1)*2    
    STA $D004, x        
    ; SPRITE Y
    INY
    LDA ($FB), y ; sprite Y
    JSR .f_store_enemy_data
    ; D005, D007, D009, D00B, D00D, D00F
    ; D005, (x-1)*2
    STA $D005, x
    LDX tmp_X ; restore index Y        
    ; SPRITE MSB
    INY
    LDA ($FB), y ; sprite MSB X
    JSR .f_store_enemy_data
    CMP #$00
    BEQ no_msb
    LDA $D010
    ORA enemies_sprite_mask, x
    STA $D010    
no_msb    
    ; SPRITE STRETCHED
    INY    
    LDA ($FB), y
    CMP #$00
    BEQ no_stretched
    LDA $D01D
    ORA enemies_sprite_mask, x
    STA $D01D
    LDA $D017  
    ORA enemies_sprite_mask, x
    STA $D017
no_stretched  
    ; Enable sprite
    LDA $D015
    ORA enemies_sprite_mask, x
    STA $D015
    ; Enemy hits   
    LDA #$10    
    JSR .f_store_enemy_data

    ; Print sprite index
    STX tmp_X
    STY tmp_Y
    TXA     
    JSR .f_get_enemy_sprite_row_column
    LDA tmp_X
    JSR .f_put_char
    LDX tmp_X
    LDY tmp_Y
    RTS

.f_store_enemy_data
    STY tmp_Y
    LDY enemy_index
    STA enemies, y
    INY 
    STY enemy_index
    LDY tmp_Y
    RTS

.f_move_hero

    ; disable bubble
    LDA $D015        
    AND #%11111101   
    STA $D015 

    ; set hero to "not moved"
    LDA #$00
    STA hero_moved

    ; save old coordinates
    LDA hero_x
    STA hero_new_x
    LDA hero_x_msb
    STA hero_new_x_msb
    LDA hero_y
    STA hero_new_y

    ; get joystic button
    JSR .f_get_joystick
    CPX #$01    
    BEQ move_hero_right
    CPX #$FF
    BEQ move_hero_left
    JMP hero_move_up_down

move_hero_right
    ; move right
    LDA hero_moved
    ORA #$01
    STA hero_moved
    LDA #$01 ; facing right
    JSR .f_update_facing
    LDA hero_x   
    CLC
    ADC #$2
    BNE end_hero_move_left_right
    TAX    
    LDA hero_x_msb
    ORA #%00000001
    STA hero_new_x_msb
    TXA
    JMP end_hero_move_left_right
move_hero_left
    ; move hero left      
    LDA hero_moved
    ORA #$02
    STA hero_moved
    LDA #$00 ; facing right
    JSR .f_update_facing
    LDA hero_x        
    SEC
    SBC #$2           
    BPL end_hero_move_left_right
    TAX
    LDA hero_x_msb
    AND #%11111110
    STA hero_new_x_msb
    TXA
end_hero_move_left_right          
    STA hero_new_x
    
hero_move_up_down
    CPY #$01    
    BEQ hero_move_down
    CPY #$FF    
    BEQ hero_move_up
    JMP end_hero_move
hero_move_down
    LDA hero_moved
    ORA #$04
    STA hero_moved
    LDA hero_y 
    CLC
    ADC #$2
    JMP end_hero_move_up_down
hero_move_up
    LDA hero_moved
    ORA #$08
    STA hero_moved
    LDA hero_y      
    SEC
    SBC #$2  
end_hero_move_up_down    
    STA hero_new_y

end_hero_move  
    LDA hero_moved
    CMP #$00
    BNE move_hero_contine
    RTS ; no move, return

move_hero_contine
    ; check collision
    JSR .f_check_backgroud_collision
    CMP #$01
    BNE check_left
    LDA $D015        ; show bubble on collision
    ORA #%00000011   
    STA $D015 
    RTS ; no move, return

    ; room switching    
check_left
    LDA hero_new_x
    CMP #$00
    BNE check_right
    LDA hero_new_x_msb 
    AND #$01
    CMP #$00
    BEQ room_left    
check_right
    LDA hero_new_x
    CMP #$58
    BNE check_up
    LDA hero_new_x_msb 
    AND #$01
    CMP #$01
    BEQ room_right    
check_up    
    LDA hero_new_y
    CMP #$10    
    BNE check_down        
    ; check direction
    LDA hero_moved
    AND #$08
    CMP #$00
    BNE room_up    
check_down
    ; check direction
    LDA hero_new_y
    CMP #$FE
    BNE finalize_hero_move
    ; check direction
    LDA hero_moved
    AND #$04
    CMP #$00
    BNE room_down
    JMP finalize_hero_move

room_left
    LDA #$58
    STA hero_new_x
    LDA hero_new_x_msb
    ORA #$01
    STA hero_new_x_msb
    ; switch room left
    DEC current_room
    INC refresh_room
    JMP finalize_hero_move
room_right
    LDA #$00
    STA hero_new_x
    LDA hero_new_x_msb
    AND #$FE
    STA hero_new_x_msb
    ; switch room left
    INC current_room
    INC refresh_room
    JMP finalize_hero_move
room_up
    LDA #$FE
    STA hero_new_y
    DEC current_room
    DEC current_room
    DEC current_room
    INC refresh_room
    JMP finalize_hero_move
room_down
    LDA #$10
    STA hero_new_y
    INC current_room
    INC current_room
    INC current_room
    INC refresh_room
    JMP finalize_hero_move

finalize_hero_move
    ; if no collision, finalize move
    ; JSR .f_get_shooting_char
    ; LDA #$00
    ; JSR .f_put_char

    LDA hero_new_x
    STA hero_x
    STA $D000
    STA $D002
    LDA hero_new_y
    STA hero_y
    STA $D001
    STA $D003

    ; handle smb also for the buggle
    LDA hero_new_x_msb
    AND #%00000001
    CMP #$01
    BEQ hero_msb_1
    LDA $D010
    AND #%11111100 ; force 1 msb for sprite 2 (bubble)    
    JMP set_hero_msb
hero_msb_1
    ;LDA hero_new_x_msb
    LDA $D010
    ORA #%00000011 ; force 1 msb for sprite 2 (bubble)
set_hero_msb
    STA $D010
    ; update current x msb
    LDA hero_new_x_msb
    STA hero_x_msb    
    ; shooting point
    ; JSR .f_get_shooting_char    
    ; JSR .f_put_char
    ; smoke    
hero_no_move
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
    LDA #$30
    JMP get_y
set_low_bullet    
    LDA #$31
    JMP get_y
add_another_one
    INX     
    CMP #$06
    BPL set_upper_bullet
    ; middle
    LDA #$30
    JMP get_y
set_upper_bullet
    LDA #$2F
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

.f_hero_shooting
    LDA $DC00
    AND #$10
    CMP #$00
    BEQ fire_pressed
    ; fire not pressed
    ; set button released
    LDA #$00
    STA button_pressed  
    RTS
fire_pressed
    LDA button_pressed    
    CMP #$01
    BNE * + 3
    RTS
    ; set button pressed
    LDA #$01
    STA button_pressed    
    ; get a free bullet
    LDX #$00
get_free_bullets
    LDA bullets, x
    CMP #$00
    BEQ shoot
    CMP #$FF ; end of array
    BEQ no_shoot
    TXA ; 2
    CLC ; 2
    ADC #$05 ; 2
    TAX ; 2
    JMP get_free_bullets
shoot    
    STX tmp_X ; store bullets array index    
    JSR .f_get_shooting_char
    STA tmp_A ; store shooting char
    ; JSR .f_get_hero_sprite_row_column ; use tmp
    ; ; get bullet initial position
    ; INX
    ; INX
    ; INY
    ; INY
    JSR .f_get_char
    CMP wall
    BEQ no_shoot
    ; choose the right char according to sprite coordinates (how?) and gun type    
    ; LDA #$2F    
    LDA tmp_A
    JSR .f_put_char
    STX tmp ; store bullet X

    ; store bullet position
    LDX tmp_X 
    ; ACTIVE
    LDA #$01
    STA bullets, x
    ; X
    INX
    LDA tmp
    STA bullets, x
    ; Y
    INX
    TYA
    STA bullets, x
    ; CHAR
    INX
    LDA tmp_A
    STA bullets, x
    ; DIRECTION
    INX
    LDA hero_facing
    STA bullets, x

no_shoot
    RTS

.f_move_bullets
    LDX #$00
bullet
    STX tmp_X
    LDA bullets, x
    CMP #$01
    BEQ move_bullet
    CMP #$FF ; end of array
    BNE get_next_bullet
    RTS

move_bullet    
    JSR .f_move_bullet
    ;JMP get_next_bullet
    // Check return
    CMP #$00
    BEQ get_next_bullet

    ; check collision
    LDA $D01F
    CMP #$00
    BEQ get_next_bullet

    ; collision detected, lets investigate    
    LSR ; skip hero
    LSR ; skip bubble
    LDX #$02
sprite_loop
    STX tmp
    LSR
    BCS sprite_collide
    JMP next_sprite
sprite_collide
    JSR .f_get_enemy
    ; load sprite data
    ; check sprite row

    ; check sprite bounding box    
    ; LDX bullet_x
    ; LDY bullet_y   
    ; LDA #$01     
    ; JSR .f_put_char
    ; JSR .f_clear_bullet 
next_sprite
    LDX tmp
    INX
    CPX #$08    
    BNE sprite_loop

    ; LDX bullet_x
    ; LDY bullet_y        
    ; JSR .f_put_char
    ; JSR .f_clear_bullet 
        
get_next_bullet
    LDA tmp_X    
    CLC ; 2
    ADC #$05 ; 2
    TAX ; 2
    JMP bullet
end_of_bullets
    RTS

; X contains the sprite index   
.f_get_enemy
    LDA #$00

    RTS

; on return, in A: $01 collision need to be checked, $00 otherwise
.f_move_bullet
    INX ; X
    LDA bullets, x
    STA bullet_x
    INX ; Y        
    LDA bullets, x
    STA bullet_y
    INX ; char
    LDA bullets, x
    STA bullet_char    
    INX ; direction    
    LDA bullets, x
    STA bullet_direction
    ; remove old bullet
    LDA #$00
    LDX bullet_x
    LDY bullet_y
    JSR .f_put_char
    LDA bullet_direction
    CMP #$01
    BEQ bullet_right
    ; bullet left
    DEY
    jmp put_bullet
bullet_right
    INY
put_bullet    
    JSR .f_get_char
    CMP wall
    BEQ clear_bullet
    CPY #$FF
    BEQ clear_bullet
    CPY #$27
    BEQ clear_bullet
    LDA bullet_char
    JSR .f_put_char    
    ; store new Y
    STY bullet_y
    ; update bullet position in list
    TYA
    LDX tmp_X
    INX
    INX
    STA bullets, x    
    LDA #$01
    RTS
clear_bullet
    JSR .f_clear_bullet
    RTS

.f_clear_bullet
    LDX tmp_X
    LDA #$00
    STA bullets, x
    INX
    STA bullets, x
    INX
    STA bullets, x
    INX
    STA bullets, x
    INX
    STA bullets, x       
    LDA #$00
    RTS

.f_move_enemies
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

.f_get_hero_sprite_row_column
    STA tmp_A
    LDA #$00
    JSR .f_get_sprite_row_column
    LDA tmp_A
    RTS

.f_get_enemy_sprite_row_column    
    CLC
    ADC #$01
    JSR .f_get_sprite_row_column
    RTS

.f_get_sprite_row_column    
    TAX
    TAY
    LDA $D010 ; sprite X MSB
    AND sprite_mask, x
    CMP #$00
    BEQ row_0_32
column_33_40
    TYA
    ASL ; *2, sprite offset in coordinate registries
    TAX
    LDA $D000, x ; sprite X coordinate
    SEC
    SBC border_width_x  
    BMI right_negative_zone
    LSR
    LSR
    LSR
    SEC
    ADC #31
    JMP save_column_with_msb    
right_negative_zone    
    LSR
    LSR
    LSR
save_column_with_msb 
    TAY
    JMP row
row_0_32
    TYA    
    ASL ; *2, sprite offset in coordinate registries
    TAX
    LDA $D000, x ; sprite X coordinate
    SEC
    SBC border_width_x  
    ;BMI left_negatize_zone
    LSR
    LSR
    LSR
    JMP save_column
left_negatize_zone
    LDA #$00 ; force 0
save_column
    TAY
row    
    INX 
    LDA $D000, x ; sprite Y coordinate   
    SEC    
    SBC border_width_y
    LSR
    LSR
    LSR
    TAX ; row
    ; LDA #$01
    ; JSR .f_put_char

    RTS

.f_get_char
    ; Parameters 
    ;   X => ROW
    ;   Y => COLUMN      
    LDA ScreenRAMRowTableLow, x
    STA $FD;
    LDA ScreenRAMRowTableHigh, x
    STA $FE;    
    LDA ($FD),y 
    RTS

.f_put_char
    ; Parameters 
    ;   X => ROW
    ;   Y => COLUMN      
    ;   A => char to be printed
    
    PHA ; save accumulator into stack
    
    LDA ScreenRAMRowTableLow, x
    STA $FD ; Zero page unused byte
    LDA ScreenRAMRowTableHigh, x
    STA $FE ; Zero page unused byte

    PLA ; load accumulator value (character to be printed)

    ; Zero Page Indirect-indexed addressing (works using Y as offet)
    STA ($FD),y 
    RTS

.f_get_joystick
djrr    lda $dc00     ; get input from port 2 only
djrrb   ldy #0        ; this routine reads and decodes the
        ldx #0        ; joystick/firebutton input data in
        lsr           ; the accumulator. this least significant
        bcs djr0      ; 5 bits contain the switch closure
        dey           ; information. if a switch is closed then it
djr0    lsr           ; produces a zero bit. if a switch is open then
        bcs djr1      ; it produces a one bit. The joystick dir-
        iny           ; ections are right, left, forward, backward
djr1    lsr           ; bit3=right, bit2=left, bit1=backward,
        bcs djr2      ; bit0=forward and bit4=fire button.
        dex           ; at rts time dx and dy contain 2's compliment
djr2    lsr           ; direction numbers i.e. $ff=-1, $00=0, $01=1.
        bcs djr3      ; dx=1 (move right), dx=-1 (move left),
        inx           ; dx=0 (no x change). dy=-1 (move up screen),
djr3    lsr           ; dy=0 (move down screen), dy=0 (no y change).
        stx dx        ; the forward joystick position corresponds
        sty dy        ; to move up the screen and the backward
        rts           ; position to move down screen.

.f_update_facing    
    CMP #$01
    BEQ turn_right
    LDA #$00
    STA hero_facing_switched
    ; turn left
    LDA hero_facing 
    CMP #$00
    BEQ f_update_facing_end
    ; hero right
    LDA #$80
    STA $07f8
    DEC hero_facing    
    LDA #$01
    STA hero_facing_switched
    ; update hero sprite
    JMP f_update_facing_end
turn_right
    LDA #$00
    STA hero_facing_switched
    LDA hero_facing
    CMP #$01    
    BEQ f_update_facing_end
    ; hero left
    LDA #$81
    STA $07f8
    INC hero_facing
    LDA #$01
    STA hero_facing_switched
f_update_facing_end
    RTS

; Variables

; temporary 
tmp
    !byte $00

tmp_A
    !byte $00

tmp_X
    !byte $00

tmp_Y
    !byte $00

button_pressed   
    !byte $00

refresh_room  ; set to $01 if screen need to be refreshed
    !byte $01

dx 
    !byte $00
dy 
    !byte $01

; !byte   $0A,    $80,    $00,    $80
; !byte   $08,    $80,    $00,    $A0

hero_facing
    !byte $01 ; right

hero_facing_switched
    !byte $00

hero_moved
    !byte $00


no_smokes
    !byte $02

smokes 
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
smoke_index_in
    !byte $00
smoke_index_out
    !byte $FF

; EXPLOSIONS
explosions
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $FF

; HERO BULLETS
bullets
    ; active, x, y, char, direction
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $FF

bullet_x 
    !byte $00
bullet_y
    !byte $00
bullet_char
    !byte $00
bullet_direction
    !byte $00

; Symbols
current_room 
    !byte $09

current_level 
    !byte $01

wall 
    !byte $29

!set drone_inactive = $08
!set drone_left = $09
!set drone_right = $09
!set reaver_inactive = $0A
!set reaver_left = $0B
!set reaver_right = $0C
!set crusher_inactive = $0D
!set crusher_left = $0E
!set crusher_right = $0E
!set hunter_inactive = $0F
!set hunter_left = $10
!set hunter_right = $11
!set generator = $12

sprite_mask
    !byte %00000001    
enemies_sprite_mask 
    !byte %00000010
    !byte %00000100
    !byte %00001000
    !byte %00010000
    !byte %00100000
    !byte %01000000
    !byte %10000000

enemies_level_1    
    !byte $01,      $01
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   generator,         $9C,    $50,    $00,     $01
    !byte $02,      $00
    !byte $03,      $00
    !byte $04,      $00         
    !byte $05,      $00    
    !byte $06,      $00    
    !byte $07,      $00            
    !byte $08,      $00        
    !byte $09,      $03
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $9C,    $C8,    $00,     $00   
        !byte   drone_inactive,    $30,    $60,    $01,     $00   
        !byte   reaver_inactive,   $30,    $C0,    $01,     $00   

enemy_index
    !byte $00

enemy_sprites
    ; two dummy byte to speed up the sprite calculation
    !byte   $00, $00
enemies
    ;       SPRITE  X       Y       MSB     HITS
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00 
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00    
    !byte   $FF

enemies_bullets

!set level_width = $03
!set level_heigh = $03    

SCRN  = $0400
ScreenRAMRowTableLow
        !byte <SCRN+(40*00),<SCRN+(40*01),<SCRN+(40*02),<SCRN+(40*03),<SCRN+(40*04),<SCRN+(40*05),<SCRN+(40*06),<SCRN+(40*07)
        !byte <SCRN+(40*08),<SCRN+(40*09),<SCRN+(40*10),<SCRN+(40*11),<SCRN+(40*12),<SCRN+(40*13),<SCRN+(40*14),<SCRN+(40*15)
        !byte <SCRN+(40*16),<SCRN+(40*17),<SCRN+(40*18),<SCRN+(40*19),<SCRN+(40*20),<SCRN+(40*21),<SCRN+(40*22),<SCRN+(40*23)
        !byte <SCRN+(40*24)

ScreenRAMRowTableHigh
        !byte >SCRN+(40*00),>SCRN+(40*01),>SCRN+(40*02),>SCRN+(40*03),>SCRN+(40*04),>SCRN+(40*05),>SCRN+(40*06),>SCRN+(40*07)
        !byte >SCRN+(40*08),>SCRN+(40*09),>SCRN+(40*10),>SCRN+(40*11),>SCRN+(40*12),>SCRN+(40*13),>SCRN+(40*14),>SCRN+(40*15)
        !byte >SCRN+(40*16),>SCRN+(40*17),>SCRN+(40*18),>SCRN+(40*19),>SCRN+(40*20),>SCRN+(40*21),>SCRN+(40*22),>SCRN+(40*23)
        !byte >SCRN+(40*24)

LEVEL = $5000
LEVEL_1_Low
    !byte <LEVEL+(0*$3e8),<LEVEL+(1*$3e8),<LEVEL+(2*$3e8),<LEVEL+(3*$3e8),<LEVEL+(4*$3e8)
    !byte <LEVEL+(5*$3e8),<LEVEL+(6*$3e8),<LEVEL+(7*$3e8),<LEVEL+(8*$3e8)
LEVEL_1_High
    !byte >LEVEL+(0*$3e8),>LEVEL+(1*$3e8),>LEVEL+(2*$3e8),>LEVEL+(3*$3e8),>LEVEL+(4*$3e8)
    !byte >LEVEL+(5*$3e8),>LEVEL+(6*$3e8),>LEVEL+(7*$3e8),>LEVEL+(8*$3e8)