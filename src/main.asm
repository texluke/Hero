
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
        
    ; Configure sprite colors
    LDA #$01         ; Set sprite color to white (color index 15)
    STA $D027        ; Store color information for sprite 0

    ; Enable high-resolution mode for sprite 0
    LDA $D01C        ; Load current value from VIC-II Control Register 4
    AND #%11111110   ; Set bit 0 to 0 for sprite 0 high res
    STA $D01C        ; Store modified value back to Control Register 4

    ; Enable sprites
    LDA $D015        ; Load current value from Control Register 4
    ORA #%00000001   ; Set bit 0 to enable sprites
    STA $D015        ; Store modified value back to Control Register 4

    ; Sprite position
    LDA hero_x
    STA $D000   
    ; LDA 01 
    ; STA $D010
    LDA hero_y
    STA $D001

    JSR .f_get_sprite_row_column
    LDA #$29
    JSR .f_put_char
   
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

    ; jsr $1003	; play			
    
    LDX refresh_room
    CPX #$00
    BEQ no_refres_needed
    DEC refresh_room    
    JSR .f_draw_room 

no_refres_needed
    JSR .f_move_hero

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
  
.f_end_irq        
    JSR .f_draw_bar
                                          		          
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
    LDA $8300, x
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

.f_move_hero
    LDA #$00
    STA hero_moved

    LDA hero_x
    STA hero_new_x
    LDA hero_x_msb
    STA hero_new_x_msb
    LDA hero_y
    STA hero_new_y

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
    ORA #$01
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
    AND #$FE
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
    BEQ hero_no_move

    ; check collision
    JSR .f_check_backgroud_collision
    CMP #$01
    BEQ hero_no_move

   ; if no collision, finalize move
    LDA hero_new_x
    STA hero_x
    STA $D000
    LDA hero_new_x_msb
    STA hero_x_msb
    STA $D010
    LDA hero_new_y
    STA hero_y
    STA $D001
    ; smoke

    ; room switch
    LDA hero_x
    CMP #$00
    BNE hero_no_move
    LDX current_room
    DEX
    STX current_room
    LDX #$01
    STX refresh_room
hero_no_move
    RTS


.f_check_backgroud_collision
    LDA hero_new_x
    SEC
    SBC border_width_x    
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
    LDA hero_new_y
    SEC    
    SBC border_width_y
    LSR
    LSR
    LSR
    TAX ; row   
    INY    
    JSR .f_get_char
    CMP #$29
    BEQ hit        
    INX
    JSR .f_get_char
    CMP #$29
    BEQ hit    
    INX
    JSR .f_get_char
    CMP #$29
    BEQ hit        
    DEX
    DEX
    INY    
    JSR .f_get_char
    CMP #$29
    BEQ hit        
    INX
    JSR .f_get_char
    CMP #$29
    BEQ hit    
    INX
    JSR .f_get_char
    CMP #$29
    BEQ hit
    LDA #$00
    JMP f_check_backgroud_collision_end
hit
    LDA #$01
f_check_backgroud_collision_end
    RTS

.f_get_sprite_row_column
    ; Parameter
    ;   A => Sprite index
    ; Return 
    ;   X => ROW
    ;   Y => COLUMN      
    ; (hate this but works better and faster then using switched index)    
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
tmp
    !byte $00

refresh_room  ; set to $01 if screen need to be refreshed
    !byte $01

dx 
    !byte $00
dy 
    !byte $01

hero_facing
    !byte $01 ; right

hero_facing_switched
    !byte $00

hero_moved
    !byte $00

hero_x
    !byte $50

hero_x_msb
    !byte $00

hero_y
    !byte $86

hero_new_x
    !byte $00

hero_new_x_msb
    !byte $00

hero_new_y
    !byte $A0

hero_intial_x
    !byte $00

hero_intial_x_msb
    !byte $00

hero_intial_y
    !byte $00

hero_initial_column
    !byte $00

hero_initial_row
    !byte $00

border_width_x
    !byte $18

border_width_y
    !byte $32

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

; Symbols
current_room 
    !byte $09
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