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
djrr    
        lda $dc00     ; get input from port 2 only
djrrb   
        ldy #0        ; this routine reads and decodes the
        ldx #0        ; joystick/firebutton input data in
        lsr           ; the accumulator. this least significant
        bcs djr0      ; 5 bits contain the switch closure
        dey           ; information. if a switch is closed then it
djr0    
        lsr           ; produces a zero bit. if a switch is open then
        bcs djr1      ; it produces a one bit. The joystick dir-
        iny           ; ections are right, left, forward, backward
djr1    
        lsr           ; bit3=right, bit2=left, bit1=backward,
        bcs djr2      ; bit0=forward and bit4=fire button.
        dex           ; at rts time dx and dy contain 2's compliment
djr2    
        lsr           ; direction numbers i.e. $ff=-1, $00=0, $01=1.
        bcs djr3      ; dx=1 (move right), dx=-1 (move left),
        inx           ; dx=0 (no x change). dy=-1 (move up screen),
djr3
        lsr           ; dy=0 (move down screen), dy=0 (no y change).
        stx dx        ; the forward joystick position corresponds
        sty dy        ; to move up the screen and the backward
        rts           ; position to move down screen.

; 
; Parameters
;   [A] value to added
inc_value_x !byte $00
.f_inc_X
    STA inc_value_x
    TXA
    CLC
    ADC inc_value_x
    TAX    
    RTS

; 
; Parameters
;   [A] value to added
inc_value_y !byte $00
.f_inc_Y
    STA inc_value_y
    TYA
    CLC
    ADC inc_value_y
    TAY    
    RTS