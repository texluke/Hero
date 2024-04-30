

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

.f_get_hero_sprite_row_column
    STA tmp_A
    LDA #$00
    JSR .f_get_sprite_row_column
    LDA tmp_A
    RTS

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

