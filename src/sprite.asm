*= $2000
!bin "../resources/sprites.bin"

*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

*=$8000 

!set debug = $0

main
    ; border and screen color
    LDA #$05
    STA $d020
    LDA #$00
    STA $d021   

    ;JSR .f_set_color
    JSR .f_clear

    ; load sprite 
    LDA #$84
    STA $07f8

    ; Configure sprite colors
    LDA #$01         ; Set sprite color to white (color index 15)
    STA $D027        ; Store color information for sprite 0
    STA $D028        ; Store color information for sprite 1

    ; Enable high-resolution mode for sprite 0
    LDA $D01C        ; Load current value from VIC-II Control Register 4
    AND #%11111100   ; Set bit 0 to 0 for sprite 0 high res
    STA $D01C        ; Store modified value back to Control Register 4

    ; Enable sprites
    LDA $D015        ; Load current value from Control Register 4
    ORA #%00000001   ; Set bit 0 to enable sprites
    STA $D015        ; Store modified value back to Control Register 4

    ; Sprite position
    LDA hero_x
    STA $D000       
    LDA hero_y
    STA $D001

    JSR .f_draw_walls
    JSR .f_highlight
    
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
    lda #$10
    sta $d012		
    							        
    lda #<.f_irq
    ldx #>.f_irq
    sta $0314
    stx $0315
            
    cli			
    rts

.f_irq	

    !ifdef debug {
        LDY $d012
        CPY $d012
        BEQ *-3
        LDA #$01
        STA $d020
    }

    LDY $d012
    CPY $d012
    BEQ *-3
    LDA #0
    STA $d020

    LDA #$00
    STA hero_moved

    LDA hero_x
    STA hero_new_x
    LDA hero_msb_x
    STA hero_new_msb_x
    LDA hero_y
    STA hero_new_y

    ; get joystic button
    JSR .f_get_joystick
    CPX #$01    
    BEQ right
    CPX #$FF
    BEQ left
    JMP up_and_down

right
    ; move right    
    INC hero_moved
    LDA #$01
    STA hero_facing
    LDA hero_x   
    CLC
    ADC #$1    
    BNE end_left_right ; if 0 set sprite msb to 1    
    TAX
    LDA hero_msb_x
    ORA #%00000001    
    STA hero_new_msb_x    
    TXA
    JMP end_left_right

left
    INC hero_moved
    LDA #$00
    STA hero_facing
    LDA hero_x        
    SEC
    SBC #$1        
    BPL end_left_right ; if negative flah set set msb to 0    
    TAX
    LDA hero_msb_x
    AND #%11111110    
    STA hero_new_msb_x    
    TXA

end_left_right
    STA hero_new_x
    ; finalize move (if needed)

up_and_down
    CPY #$01    
    BEQ down
    CPY #$FF    
    BEQ up
    JMP end_up_down

up
    INC hero_moved
    LDA hero_y      
    SEC    
    SBC #$1 
    STA hero_new_y    
    JMP end_up_down

down
    INC hero_moved
    LDA hero_y 
    CLC
    ADC #$1
    STA hero_new_y
    STA hero_y
    

end_up_down

    ; check if the sprite has been moved
    LDA hero_moved
    CMP #$00
    BEQ no_move

end_move

    ; check collision
    JSR .f_check_collision
    CMP $01
    BEQ no_move
        
    LDA hero_new_x
    STA $D000
    STA hero_x

    LDA hero_new_msb_x
    STA $D010
    STA hero_msb_x

    LDA hero_new_y
    STA $D001
    STA hero_y

    LDA $D001
    STA hero_old_y
    
    JSR .f_clear_highlight
    JSR .f_highlight
    
no_move

irq_end    
    ; reset interrupt
    ASL $d019        

    !ifdef debug {
        ; LDY $d012
        ; CPY $d012
        ; BEQ *-3
        LDA #$00
        STA $d020
    }

    JMP $ea7e

.f_check_collision

    LDA hero_new_x  ; sprite X coordinate
    SEC
    SBC #$18        ; X border width 
    STA tmp    
    LDA hero_new_msb_x  ; sprite X high bit
    AND #$01
    SBC #$00
    LSR
    LDA tmp
    ROR        
    LSR
    LSR
    TAY ; column
    LDA hero_new_y
    SEC    
    SBC #$32        ; Y border width
    LSR
    LSR
    LSR
    TAX ; row
    INY
    JSR .f_get_char
    CMP #wall
    BEQ hit
    LDA $00
    RTS
hit
    LDA $01
    RTS

.f_draw_walls
    LDA #wall
    LDX #$10
    DEX             ; 1 byte
    STA $0400, x    ; 3 byte
    BNE * - 4       ; jump 4 byte back (avoid to use label)

    LDX #$10
    DEX             
    STA $07C0, x    
    BNE * - 4

    ; left
    STA $0518
    STA $0540
    STA $0568
    STA $0590
    STA $05B8
    STA $05E0
    STA $0608
    
    ; righ
    STA $053F
    STA $0567
    STA $058F
    STA $05B7
    STA $05DF
    STA $0607
    STA $062F
    

    RTS

.f_highlight
    JSR .f_get_hero_sprite_row_column
    STX sprite_char_x
    STY sprite_char_y         
    
    INY
    TXA
    // multiply x 8
    ASL
    ASL
    ASL
    STA tmp_A
    LDA #$00
    JSR .f_put_char
    LDA marker
    INX    
    JSR .f_put_char
    INX
    JSR .f_put_char
    DEX
    DEX
    INY
    JSR .f_put_char
    INX    
    JSR .f_put_char
    INX    
    JSR .f_put_char 
    ; Shoot
    DEX
    DEX
    INY
    INX
    LDA $D001
    STA hero_old_y
    SEC
    SBC border_width_y
    SEC
    SBC tmp_A
    CMP #$04
    BPL add_another_one
    CMP #$02
    BPL set_low_bullet
    ; middle
    LDA #68
    JMP put_char
set_low_bullet    
    LDA #67
    JMP put_char
add_another_one
    INX     
    CMP #$06
    BPL set_upper_bullet
    LDA #68
    JMP put_char
set_upper_bullet
    LDA #69
    JMP put_char
put_char
    ; 67 low
    ; 68 middle
    ; 69 top
        
    JSR .f_put_char

    RTS

.f_clear_highlight
    
    LDX sprite_char_x
    LDY sprite_char_y
    LDA #$20    
    INY   
    JSR .f_put_char
    INX    
    JSR .f_put_char
    INX
    JSR .f_put_char
    DEX
    DEX
    INY
    JSR .f_put_char
    INX    
    JSR .f_put_char
    INX    
    JSR .f_put_char  
    ; shoot   
    DEX
    DEX
    INY
    JSR .f_put_char
    INX    
    JSR .f_put_char
    INX    
    JSR .f_put_char    
    JSR .f_put_char

    RTS



.f_clear        
    LDX #$00
    LDA #$20
clear_loop
    STA $0400,x
    STA $0500,x
    STA $0600,x
    CPX #$E8
    BCS clear_last_line    
    STA $0700, x
clear_last_line
    DEX    
    BNE clear_loop
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



marker
    !byte $E0 ; dotted square

#wall   
    !byte $E6 ; square

tmp 
    !byte $00

dx 
    !byte $00
dy 
    !byte $01

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


hero_x
    !byte $80

hero_msb_x
    !byte $00

hero_y
    !byte $80

hero_new_x
    !byte $00

hero_new_msb_x
    !byte $00

hero_new_y
    !byte $00

hero_old_y
    !byte $00

sprite_char_x
    !byte $00

sprite_char_y
    !byte $00

hero_moved 
    !byte $00

hero_facing
    !byte $01 ; right 

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

tmp_A
    !byte $00

border_width_x
    !byte $18

border_width_y
    !byte $32