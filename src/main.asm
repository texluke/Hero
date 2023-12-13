
; Hero C64
;


*= $2000
!bin "../resources/sprites.bin"

*= $2800
!bin "../resources/chars.bin"

*= $5000
!bin "../resources/level_1.bin"

; current_room
;     !byte $00
; current_room
;     !byte $09


; Symbols


; !set new_room = $09


*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main


!set debug = $01

main
    ; set font at $2800
    LDA $D018	   
    AND #$F1  
    ORA #$0A 
    STA $D018   

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
    LDA #$80
    STA $D000    
    STA $D001

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

    ; set interrupt as consumed
    INC $d019                  

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
    
    JMP $ea7e
  
.f_end_irq        
    JSR .f_draw_bar

    ; set interrupt as completed
    INC $d019                                                         		          
    ; set next interrupt
    LDA #$20				
    STA $d012	
    LDA #<.f_game_irq
    LDX #>.f_game_irq
    STA $0314
    STX $0315
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
    room_address = $5000 + ((current_room - $01) * $3e8)

    LDA #$00
    TAX
draw_room_loop
    LDA room_address, x
    STA $0400, x
    LDA room_address + $100, x
    STA $0500, x
    LDA room_address + $200, x
    STA $0600, x
    CPX #$E8
    BCS draw_room_last_line
    LDA room_address + $300, x
    STA $0700, x
draw_room_last_line
    DEX
    BNE draw_room_loop
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
.f_move_hero
    ; LDA $d01f
    ; LSR
    ; BCC nobcollision
	; RTS
nobcollision
    JSR .f_get_joystick
    CPX #$01    
    BEQ hero_right
    CPX #$FF    
    BEQ hero_left
    JMP hero_moved_left_right
hero_right    
    LDA $D000
    CLC
    ADC #$2    
    STA $D000
    JMP hero_moved_left_right
hero_left    
    LDA $D000
    SEC
    SBC #$2
    STA $D000    
hero_moved_left_right
    CPY #$01    
    BEQ hero_down
    CPY #$FF    
    BEQ hero_up
    JMP hero_moved_up_down
hero_down    
    LDA $D001
    CLC
    ADC #$2
    STA $D001
    JMP hero_moved_up_down
hero_up    
    LDA $D001
    SEC
    SBC #$2
    STA $D001   
hero_moved_up_down
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
                      ;

; Variables
refresh_room  ; set to $01 if screen need to be refreshed
    !byte $01

dx 
    !byte $00
dy 
    !byte $01

border_with_y
    !byte $50

border_with_x
    !byte $20

; Symbols
!set current_room = $09
!set level_width = $03
!set level_heigh = $03    

