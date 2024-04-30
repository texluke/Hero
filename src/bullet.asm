.f_move_bullets
    LDX #$00
get_bullet
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
    JMP get_bullet
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