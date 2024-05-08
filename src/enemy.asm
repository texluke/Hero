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
    DEX ; use zero based index (CPX #$FF)
get_next_enemy
    CPX #$FF
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
    STA $07FA, x  ; start from sprite 3, $07FA, X: 1-> N
    ; Calculate sprite coordinate registry offset
    STX tmp_X
    ; DEX
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

.f_move_enemies
    // loop all enemies
    LDX #$00
-
    LDA enemies, x
    CMP #$00
    BEQ ++
    CMP #$FF
    BNE +
    LDA #$00
    RTS
+
    STX tmp_X
    LDA #$00
    JSR .f_get_enemy_sprite_row_column
    ; LDA #$05
    ; JSR .f_put_char
    LDX tmp_X

++    
    LDA #$05
    JSR .f_inc_X
    JMP -

.f_get_enemy_sprite_row_column
    CLC
    ADC #$02
    JSR .f_get_sprite_row_column
    RTS