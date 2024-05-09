

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
    BEQ +
    CPX #$FF
    BEQ ++
    JMP hero_move_up_down

+
    ; MOVE RIGHT
    LDA hero_moved
    ORA #$01
    STA hero_moved
    LDA #$01 ; facing right
    JSR .f_update_facing
    LDA hero_x
    CLC
    ADC #$2
    BNE +++
    TAX
    LDA hero_x_msb
    ORA #%00000001
    STA hero_new_x_msb
    TXA
    JMP +++
++
    ; MOVE LEFT
    LDA hero_moved
    ORA #$02
    STA hero_moved
    LDA #$00 ; facing right
    JSR .f_update_facing
    LDA hero_x
    SEC
    SBC #$2
    BPL +++
    TAX
    LDA hero_x_msb
    AND #%11111110
    STA hero_new_x_msb
    TXA
+++
    STA hero_new_x

hero_move_up_down
    CPY #$01
    BEQ +
    CPY #$FF
    BEQ ++
    JMP end_hero_move
+
    ; MOVE DOWN
    LDA hero_moved
    ORA #$04
    STA hero_moved
    LDA hero_y
    CLC
    ADC #$2
    JMP +++
++
    ; MOVE UP
    LDA hero_moved
    ORA #$08
    STA hero_moved
    LDA hero_y
    SEC
    SBC #$2
+++
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
    BNE +
    ; COOLLIDE!!!!
    LDA $D015        ; show bubble on collision
    ORA #%00000011
    STA $D015
    RTS ; no move, return

    ; room switching
+
    ; LEFT
    LDA hero_new_x
    CMP #$0E
    BNE ++
    LDA hero_new_x_msb
    AND #$01
    CMP #$00
    BEQ room_left
++
    ; RIGHT
    LDA hero_new_x
    CMP #$44
    BNE +++
    LDA hero_new_x_msb
    AND #$01
    CMP #$01
    BEQ room_right
+++
    ; UP
    LDA hero_new_y
    CMP #$32
    BNE ++++    
    LDA hero_moved
    AND #$08
    CMP #$00
    BNE room_up
++++
    ; DOWN    
    LDA hero_new_y
    CMP #$E6
    BNE +
    LDA hero_moved
    AND #$04
    CMP #$00
    BNE room_down
    JMP +

; ROOM SWITCHING
room_left
    LDA #$42
    STA hero_new_x
    LDA hero_new_x_msb
    ORA #$01
    STA hero_new_x_msb
    ; switch room left
    DEC current_room
    INC refresh_room
    JMP +
room_right
    LDA #$12
    STA hero_new_x
    LDA hero_new_x_msb
    AND #$FE
    STA hero_new_x_msb
    ; switch room left
    INC current_room
    INC refresh_room
    JMP +
room_up
    LDA #$E4
    STA hero_new_y
    DEC current_room
    DEC current_room
    DEC current_room
    INC refresh_room
    JMP +
room_down
    LDA #$34
    STA hero_new_y
    INC current_room
    INC current_room
    INC current_room
    INC refresh_room

+
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
    BEQ +
    LDA $D010
    AND #%11111100 ; force 1 msb for sprite 2 (bubble)
    JMP ++
+
    ; MSB
    LDA $D010
    ORA #%00000011 ; force 1 msb for sprite 2 (bubble)
++
    ; SAVE MSB
    STA $D010    
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
    CMP #free_bullet
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
    ; in A the facing to be stored
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

