
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
    ; LDA #$29
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
    sta $d01a

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
    JSR .f_move_hero
    JSR .f_move_bullets
    JSR .f_hero_shooting
    
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
color_loop: 
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
    ADC #$04
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
    
    ; smoke    
hero_no_move
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
    STX tmp_2 ; store bullets array index
    JSR .f_get_sprite_row_column ; use tmp
    INX
    INX
    INY
    INY
    ; choose the right char according to sprite coordinates (how?) and gun type    
    LDA #$2F    
    JSR .f_put_char
    STX tmp ; store bullet X

    ; store bullet position
    LDX tmp_2 
    LDA #$01
    STA bullets, x
    INX
    LDA tmp
    STA bullets, x
    INX
    TYA
    STA bullets, x
    INX
    LDA #$2F
    STA bullets, x
    INX
    LDA hero_facing
    STA bullets, x

no_shoot
    RTS

.f_move_bullets
    LDX #$00
bullet
    STX tmp_5
    LDA bullets, x
    CMP #$01
    BEQ move_bullet
    CMP #$FF ; end of array
    BEQ end_of_bullets
    JMP get_next_bullet
move_bullet
    INX ; X
    LDA bullets, x
    STA tmp
    INX ; Y        
    LDA bullets, x
    STA tmp_2
    INX ; char
    LDA bullets, x
    STA tmp_3    
    INX ; direction    
    LDA bullets, x
    STA tmp_4
    LDA #$00
    LDX tmp
    LDY tmp_2
    JSR .f_put_char
    LDA tmp_4
    CMP #$01
    BEQ bullet_right
    ; bullet left
    DEY
    jmp put_bullet
bullet_right
    INY
put_bullet
    JSR .f_get_char
    CMP #$29
    BEQ clear_bullet
    CPY #$00
    BEQ clear_bullet
    CPY #$27
    BEQ clear_bullet
    LDA tmp_3
    JSR .f_put_char    
    ; update bullet position in array
    TYA
    LDX tmp_5
    INX
    INX
    STA bullets, x
    JMP get_next_bullet
clear_bullet
    LDX tmp_5
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

get_next_bullet
    LDA tmp_5    
    CLC ; 2
    ADC #$05 ; 2
    TAX ; 2
    JMP bullet
end_of_bullets
    RTS

.f_move_enemies
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
    STA tmp 
    LDA hero_new_x_msb    
    AND #$01
    SBC #$00
    LSR
    LDA tmp
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
    CMP #$29
    BEQ hit        
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char    
    CMP #$29
    BEQ hit    
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char    
    CMP #$29
    BEQ hit        
    DEX
    DEX
    INY  
check_only_current
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char    
    CMP #$29
    BEQ hit        
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char    
    CMP #$29
    BEQ hit    
    INX
    JSR .f_get_char
    ; LDA #01
    ; JSR .f_put_char    
    CMP #$29
    BEQ hit
    LDA #$00
    JMP f_check_backgroud_collision_end
hit    
    LDA #01
    ; JSR .f_put_char    
f_check_backgroud_collision_end
    RTS

.f_get_sprite_row_column
    ; Parameter
    ;   A => Sprite index
    ; Return 
    ;   X => ROW
    ;   Y => COLUMN      
    ; (hate this but works better and faster then using switched index)

    ; Fix it to handle x coordinate MSB
    ; LDA hero_new_x
    ; SEC
    ; SBC border_width_x    
    ; STA tmp    
    ; LDA hero_new_x_msb
    ; AND #$01
    ; SBC #$00
    ; LSR
    ; LDA tmp
    ; ROR        
    ; LSR
    ; LSR
    ; TAY ; column
    ; LDA hero_new_y
    ; SEC    
    ; SBC border_width_y
    ; LSR
    ; LSR
    ; LSR
    ; TAX ; row   

    LDA $D000 ; sprite X coordinate
    SEC
    SBC border_width_x    
    STA tmp    
    LDA $D010 ; sprite X high bit
    AND #$01
    SBC #$00
    LSR
    LDA tmp
    ROR        
    LSR
    LSR
    TAY ; column
    LDA $D000 + $01 ; sprite Y coordinate   
    SEC    
    SBC border_width_y
    LSR
    LSR
    LSR
    TAX ; row
    RTS

.f_get_char
    ; Parameters 
    ;   X => ROW
    ;   Y => COLUMN      
    LDA ScreenRAMRowTableLow, x
    STA $FB;
    LDA ScreenRAMRowTableHigh, x
    STA $FC;    
    LDA ($FB),y 
    RTS

.f_put_char
    ; Parameters 
    ;   X => ROW
    ;   Y => COLUMN      
    ;   A => char to be printed
    
    PHA ; save accumulator into stack
    
    LDA ScreenRAMRowTableLow, x
    STA $FB ; Zero page unused byte
    LDA ScreenRAMRowTableHigh, x
    STA $FC ; Zero page unused byte

    PLA ; load accumulator value (character to be printed)

    ; Zero Page Indirect-indexed addressing (works using Y as offet)
    STA ($FB),y 
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
    ; turn left
    LDA hero_facing 
    CMP #$00
    BEQ f_update_facing_end
    ; hero right
    LDA #$80
    STA $07f8
    DEC hero_facing    
    LDA #$02
    STA hero_facing_switched
    ; update hero sprite
    JMP f_update_facing_end
turn_right
    LDA hero_facing
    CMP #$01    
    BEQ f_update_facing_end
    ; hero left
    LDA #$81
    STA $07f8
    INC hero_facing
    LDA #$02
    STA hero_facing_switched
f_update_facing_end
    RTS

; Variables

; temporary 
tmp
    !byte $00
tmp_2
    !byte $00
tmp_3
    !byte $00
tmp_4
    !byte $00
tmp_5
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

; Symbols
current_room 
    !byte $09

current_level 
    !byte $01


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
    ;     LEVEL  /  # OF NEMIES
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

enemies
    ;       SPRITE  X       Y       MSB
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00
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