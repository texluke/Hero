; Move active bullets in bullets array
.f_move_bullets
    LDX #$00
-
    ; bullet loop
    STX tmp_X
    LDA bullets, x
    CMP #active_bullet
    BEQ +
    CMP #exploded_bullet
    BEQ ++
    CMP #$FF ; end of array
    BNE ++++
    RTS
+   ; move bullet
    JSR .f_move_bullet
    JMP ++++
++  ; handle explosion
    INX
    LDA bullets, x ; row
    STA tmp_A      ; save X in A (use later to put char)
    INX
    LDY bullets, x ; columns
    INX
    LDA bullets, x ; char
    CMP #explosion_frame_3 ; last frame
    BEQ +++
    INC bullets, x
    LDA bullets, x
    LDX tmp_A       ; restore row
    JSR .f_put_char
    JMP ++++
+++
    LDX tmp_A      ; restore row
    LDA #empty
    JSR .f_put_char
    JSR .f_clear_bullet
++++
    ; go to next bullet
    LDX tmp_X
    LDA #$05
    JSR .f_inc_X
    JMP -
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
    LDA #empty
    LDX bullet_x
    LDY bullet_y
    JSR .f_put_char
    LDA bullet_direction
    CMP #$01
    BEQ +
    ; bullet left
    DEY
    JMP ++
+
    ; bullet right
    INY
++
    JSR .f_get_char
    CMP #wall
    BEQ +
    CMP #barrier
    BEQ +
    CMP #powerup
    BEQ +
    CPY #$FF
    BEQ +
    CPY #$27
    BEQ +
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
+
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
--
    STX tmp_X
    LDA bullets, x
    CMP #$01
    BEQ +
    CMP #$FF ; end of array
    BNE +++
    RTS
+
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
    STY enemy_index
-   ; check enemy
    STY tmp_Y
    LDA enemies, y
    CMP #$FF
    BEQ +++
    CMP #$00
    BEQ +++
    CMP #sprite_exposion_frame_1
    BEQ ++
    CMP #sprite_exposion_frame_2
    BEQ ++
    CMP #sprite_exposion_frame_3
    BEQ ++
    CMP #sprite_enemy_killed
    BEQ ++

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

++
    LDY tmp_Y ; <-- start of enememies matrix line
    LDA #$05
    JSR .f_inc_Y
    INC enemy_index
    JMP -

+++ ; next bullet
    LDX tmp_X
    LDA #$05
    JSR .f_inc_X
    JMP --
    RTS

.f_check_enemy_bullet_collision

    LDA enemy_index
    JSR .f_get_enemy_sprite_row_column

    ; handle special enemy collision (bounding box)
    LDA enemy_sprite
    CMP #generator
    BNE +
    JSR .f_check_generator_bullet_collision
    CMP #$01
    BEQ ++
    RTS
+
    CMP #summoner
    BNE +
    JSR .f_check_summoner_bullet_collision
    CMP #$01
    BEQ ++
    RTS
+

    JSR .f_check_generic_enemy_bullet_collision
    CMP #$01
    BEQ ++
    RTS

++
    ; Hit
    LDA enemy_hits
    LDX hero_powerup
    CPX #$01
    BEQ +
    SEC
    SBC #$01
    JMP ++
+
    SEC
    SBC #02
++
    STA enemy_hits
    CMP #$00
    BNE +

    ; enemy destroyed, show explosion
    LDX bullet_x
    LDY bullet_y
    LDA #empty
    JSR .f_put_char
    JSR .f_clear_bullet
    LDY tmp_Y
    STY enemy_array_index
    LDA #sprite_exposion_frame_1
    JSR .f_update_enemy_sprite
    JSR .f_post_enemy_destroyed
    JMP ++ ; update remaining hits to zero
+
    ; enemy hit, show impact explosion
    LDX bullet_x
    LDY bullet_y
    LDA #explosion_frame_1
    JSR .f_put_char
    LDA #exploded_bullet
    LDX tmp_X
    STA bullets, x
    INX
    INX
    INX
    LDA #explosion_frame_1
    STA bullets, x

    ; save new hits point
++
    LDY tmp_Y
    INY
    INY
    INY
    INY
    LDA enemy_hits
    STA enemies, y
    RTS


.f_post_enemy_destroyed
    LDA enemy_sprite
    CMP #generator
    BNE +
    LDA #$01
    STA generator_destroyed
    BEQ ++
    RTS 
+
    RTS

.f_check_generic_enemy_bullet_collision

    LDA #$00 ; no hit
    ; row
    INX
    CPX bullet_x
    BEQ +
    INX
    CPX bullet_x
    BEQ +
    INX
    CPX bullet_x
    BEQ +
    RTS
+
    ; right
    CPY bullet_y
    BEQ ++
    INY
    CPY bullet_y
    BEQ ++
    INY
    CPY bullet_y
    BEQ ++
    INY
    CPY bullet_y
    BEQ ++
    RTS
++
    LDA #$01 ; hit
    RTS

initial_x
    !byte $00
initial_y
    !byte $00

enemy_initial_x
    !byte $00
enemy_initial_y
    !byte $01

.f_check_generator_bullet_collision

    LDA #$00 ; no hit

    ; left side (top)
    INY    
    INY
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+
    DEY
    INX
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+
    DEY
    INX
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+    
    INX
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+
    INX
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+
    
    INY
    INY
    INX
    CPX bullet_x
    BNE +
    CPY bullet_y
    BNE + ; jump to right side
++  
    ; collision detect
    LDA #$01
    RTS

+
    ; right side
    INY
    INY
    INY
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
+
    DEX 
    INY       
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++    
+
    DEX     
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++    
+
    DEX     
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++    
+
    DEX         
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++    
+
    DEX
    DEY         
    CPX bullet_x
    BNE +
    CPY bullet_y
    BEQ ++
    RTS
++  
    LDA #$01
    RTS

.f_check_summoner_bullet_collision
    RTS

