;
; Hero
;

*= $2000
!bin "../resources/sprites.bin"

*= $2800
!bin "../resources/chars.bin"

*= $8000
!bin "../resources/room.bin"


*=$0801
!byte $0c,$08,$b5,$07,$9e,$20,$32,$30,$36,$32,$00,$00,$00
jmp main

; Constants

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

    ; Print room
    LDA #$00
    TAX

screen_loop
    LDA $8000, x
    STA $0400, x
    LDA $8100, x
    STA $0500, x
    LDA $8200, x
    STA $0600, x
    CPX #$E8
    BCS last_line
    LDA $8300, x
    STA $0700, x
last_line
    DEX
    BNE screen_loop
    
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
    							        
    lda #<.f_play_irq
    ldx #>.f_play_irq
    sta $0314
    stx $0315
            
    cli			
    rts

.f_play_irq	
    
    ; imposta la modalità 40 colonne, azzerando i registri di scroll
    LDA $d016
    ORA #$08
    AND #$f8
    STA $d016

    JSR .f_draw_bar

      
    ; set interrupt as completer
    INC $d019                                                         		          
    ; set next interrupt
    LDA #$45				
    STA $d012	
    LDA #<.f_main_irq
    LDX #>.f_main_irq
    STA $0314
    STX $0315
    JMP $ea7e



.f_main_irq
    ; Interrupt code here
    JSR .f_draw_bar

    ; set interrupt as completed
    INC $d019                                                         		          
    ; set next interrupt
    LDA #$f0				
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
    LDA #<.f_play_irq
    LDX #>.f_play_irq
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
