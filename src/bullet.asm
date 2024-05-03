; Move active bullets in bullets array
.f_move_bullets
    LDX #$00
move_next_bullet
    STX tmp_X
    LDA bullets, x
    CMP #active_bullet
    BEQ move_bullet
    CMP #exploded_bullet
    BEQ move_explosion
    CMP #$FF ; end of array
    BNE move_to_next_bullet
    RTS
move_bullet
    JSR .f_move_bullet 
    JMP move_to_next_bullet
move_explosion
    INX 
    LDA bullets, x
    INX 
    LDY bullets, x
    TAX
    LDA #$00
    JSR .f_put_char
    JSR .f_clear_bullet    
move_to_next_bullet        
    LDX tmp_X
    LDA #$05    
    JSR .f_inc_X    
    JMP move_next_bullet
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
    LDX tmp_X ; start of the bullet data row
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
    RTS

.f_check_hero_bullets_collision
    LDX #$00
check_next_bullet
    STX tmp_X 
    LDA bullets, x
    CMP #$01
    BEQ check_collision
    CMP #$FF ; end of array
    BNE check_to_next_bullet
    RTS
check_collision
    ; init bullet data
    INX ; X
    LDA bullets, x
    STA bullet_x
    INX ; Y
    LDA bullets, x
    STA bullet_y
    INX ; char
    LDA bullets, x
    STA bullet_char
    INX ; direction (need to bouce back the enemy)
    LDA bullets, x
    STA bullet_direction
    
    ; loop enemies    
    LDY #$00
    LDA #$01
    STA enemy_index
check_enemy    
    STY tmp_Y
    LDA enemies, y
    CMP #$FF
    BEQ check_to_next_bullet
    CMP #$00
    BEQ check_next_enemy            
    STA enemy_sprite
    INY
    LDA enemies, y
    STA enemy_x
    INY
    LDA enemies, y
    STA enemy_y
    INY
    LDA enemies, y
    STA enemy_msb
    INY
    LDA enemies, y
    STA enemy_hits
    JSR .f_check_enemy_bullet_collision    

check_next_enemy
    LDY tmp_Y
    LDA #$05
    JSR .f_inc_Y
    INC enemy_index
    JMP check_enemy
    
check_to_next_bullet
    LDX tmp_X
    LDA #$05    
    JSR .f_inc_X    
    JMP check_next_bullet
end_of_check
    RTS

.f_check_enemy_bullet_collision
    LDA enemy_index
    JSR .f_get_enemy_sprite_row_column
    ; row
    INX
    CPX bullet_x
    BEQ check_y
    INX
    CPX bullet_x
    BEQ check_y
    INX
    CPX bullet_x
    BEQ check_y
    RTS
check_y
    CPY bullet_y
    BEQ kill_it
    INY 
    CPY bullet_y
    BEQ kill_it
    INY 
    CPY bullet_y
    BEQ kill_it
    RTS

kill_it    
    LDA #$38
    JSR .f_put_char
    LDX tmp_X
    LDA #exploded_bullet
    STA bullets, x    
    RTS