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
    ADC #$05
    TAX
    JMP reset_enemy_array
reset_enemy_array_completed        
    ; use zero page accordingly to the currenet level
    LDA #<enemies_level_1
    STA $FB; Zero page
    LDA #>enemies_level_1
    STA $FC; Zero page
    LDY #$FF
    ; initialize array index to 0
    LDA #$00
    STA enemy_array_index
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
    CPX #$00
    BEQ skip_enemies_in_room
    DEX ; use zero based index (CPX #$FF)                     
get_next_enemy
    CPX #$FF
    BEQ enemies_positioning_completed    
    JSR .f_get_enemy_array_index           
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

.f_get_enemy_array_index    
    STX tmp_X
    STA tmp_A
    LDA #$00
    STA enemy_array_index
-
    CPX #$00
    BNE +
    LDA tmp_A
    LDX tmp_X
    RTS
+
    DEX
    INC enemy_array_index 
    INC enemy_array_index 
    INC enemy_array_index 
    INC enemy_array_index 
    INC enemy_array_index
    JMP -

.f_init_enemy
    ; SPRITE #
    INY
    LDA ($FB), y
    STA enemy_sprite
    CMP #generator
    BNE +
    LDA generator_destroyed
    CMP #$01
    BNE +
    ; skip sprite
    INY
    INY
    INY
    INY
    INY
    RTS
+
    LDA enemy_sprite
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
    JSR .f_get_enemy_hits ; in A hit points
    JSR .f_store_enemy_data

    ; Print sprite index
    ; STX tmp_X
    ; STY tmp_Y
    ; JSR .f_get_enemy_sprite_row_column
    ; LDA tmp_X
    ; JSR .f_put_char
    ; LDX tmp_X
    ; LDY tmp_Y
    RTS

; Return enemy hits point according to the enemy type
.f_get_enemy_hits
    LDA enemy_sprite
    CMP #drone_inactive
    BNE +
    LDA #$04
    RTS
+
    CMP #reaver_inactive
    BNE +
    LDA #$08
    RTS
+
    CMP #crusher_inactive
    BNE +
    LDA #$10
    RTS
+
    CMP #hunter_inactive
    BNE +
    LDA #$20
    RTS
+
    CMP #summoner
    BNE +
    LDA #$20
    RTS
+
    CMP #generator
    BNE +
    LDA #$40 // 64
    RTS    
+
    LDA #$04
    RTS

.f_store_enemy_data
    STY tmp_Y
    LDY enemy_array_index
    STA enemies, y
    INY
    STY enemy_array_index
    LDY tmp_Y
    RTS

.f_move_enemies
    // wait "enemy_activation_wait" cycles to activate enemies
    LDX enemy_activation_wait
    CPX #$FF
    BEQ +
    DEC enemy_activation_wait
+
    LDX drone_move_wait
    CPX #$FF
    BEQ +
    DEC drone_move_wait  
+
    // loop all enemies
    LDX #$00
    STX enemy_index
-
    STX enemy_array_index ; <-- start of enemy array 
    LDA enemies, x
    CMP #$00
    BEQ move_enemy_end    
    CMP #$FF
    BEQ move_enemy_end
   
    STX tmp_X
    STA enemy_sprite
    INX 
    LDA enemies, x
    STA enemy_x
    INX 
    LDA enemies, x
    STA enemy_y
    INX 
    LDA enemies, x
    STA enemy_msb

    LDA enemy_sprite
    CMP #sprite_exposion_frame_1
    BNE +
    JSR .f_exposion_animation
    JMP ++
+    
    CMP #sprite_exposion_frame_2
    BNE +
    JSR .f_exposion_animation
    JMP ++
+    
    CMP #sprite_exposion_frame_3
    BNE +
    JSR .f_exposion_animation
    JMP ++
+
    CMP #sprite_enemy_killed
    BEQ ++
    CMP #generator
    BEQ ++
    CMP #summoner
    BEQ ++
    
    ; get enemy row and column
    LDA enemy_index
    JSR .f_get_enemy_sprite_row_column 
    STX enemy_row
    STY enemy_column   
    ; get hero row and column
    JSR .f_get_hero_sprite_row_column
    STX hero_row
    STY hero_column
    
    JSR .f_move_enemy_left_right
    JSR .f_move_enemy_up_down

++    
    ; next enemy
    LDX tmp_X
    LDA #$05
    JSR .f_inc_X
    INC enemy_index
    JMP -

; ******************
; ** LEFT & RIGHT **
; ******************

.f_move_enemy_left_right
    ; LEFT / RIGHT
    ; try to avoid bounce
    LDA hero_column
    CMP enemy_column ; hero_column >= enemy_column
    BEQ + ; skip equal
    BPL move_enemy_right
    ; move enemy left    
    JSR .f_move_enemy_left    
    JMP +
move_enemy_right
    ; move enemy right
    JSR .f_move_enemy_right  
+
    RTS

.f_move_enemy_left
    LDA enemy_sprite
    CMP #drone_inactive
    BNE +
    ; activate    
    LDA #drone_left
    JSR .f_activate_enemy_sprite
    RTS
+
    CMP #reaver_inactive
    BNE +
    LDA #reaver_left    
    JSR .f_activate_enemy_sprite
    RTS
+
    ; DRONE
    ; to be rotated
    CMP #drone_right
    BNE +
    LDA #drone_left
    JSR .f_update_enemy_sprite
    JMP ++
+
    CMP #drone_left
    BNE +++
++
    ; move drone
    LDA drone_move_wait
    CMP #$00
    BEQ +
    RTS
+   
    JSR .f_move_left_enemy_sprite
    RTS
+++ 
    ; REAVER
    ; to be rotated
    CMP #reaver_right
    BNE +
    LDA #reaver_left
    JSR .f_update_enemy_sprite
    JMP ++
+
    CMP #reaver_left
    BNE +++
++
    ; move reaver
    JSR .f_move_left_enemy_sprite
+++    
    RTS

.f_move_enemy_right
    LDA enemy_sprite
    CMP #drone_inactive
    BNE +
    LDA #drone_right
    JSR .f_activate_enemy_sprite
    RTS    
+    
    CMP #reaver_inactive
    BNE +
    LDA #reaver_right
    JSR .f_activate_enemy_sprite
    RTS
+
    ; to be rotated
    CMP #drone_left
    BNE +
    LDA #drone_right
    JSR .f_update_enemy_sprite
    JMP ++

+
    CMP #drone_right
    BNE +++
++
    ; move drone    
    LDA drone_move_wait
    CMP #$FF
    BEQ +
    RTS
+
    JSR .f_move_right_enemy_sprite
    RTS    
+++
    ; REAVER
    ; to be rotated
    CMP #reaver_left
    BNE +
    LDA #reaver_right
    JSR .f_update_enemy_sprite
    JMP ++
+
    CMP #reaver_right
    BNE +++
++
    ; move reaver
    JSR .f_move_right_enemy_sprite
+++    

    RTS


.f_move_left_enemy_sprite
    STA tmp_A
    LDA enemy_index    
    TAY
    LDA enemy_x
    ; subtract
    SEC
    SBC #$01 ; # of pixel to move enemy      
    STA enemy_x      
    BCS +
    ; update msb
    STA tmp    
    LDA $D010    
    AND enemies_sprite_clear_mask, y
    STA $D010
    LDA #$00
    STA enemy_msb
    LDA tmp    
+
    ; calculate sprite registry offset
    LDA enemy_index
    ASL
    TAY
    LDA enemy_x
    ; store new position
    STA $D004, y

    ; update enemies array
    LDY tmp_X
    INY
    STA enemies, y    
    LDA tmp_A
    RTS

.f_move_right_enemy_sprite
    STA tmp_A
    LDA enemy_index    
    TAY
    LDA enemy_x    
    CLC
    ADC #$01 ; # of pixel to move enemy                
    BCC +   
    ; update msb
    STA enemy_x
    STA tmp
    LDA $D010
    ORA enemies_sprite_mask, y
    STA $D010
    LDA #$00
    STA enemy_msb
    LDA tmp    
+
    ; calculate sprite registry offset
    STA enemy_x
    LDA enemy_index
    ASL
    TAY
    LDA enemy_x
    ; store new position
    STA $D004, y

    ; update enemies array
    LDY tmp_X
    INY
    STA enemies, y    
    LDA tmp_A
    RTS

; ***************
; ** UP & DOWN **
; ***************
.f_move_enemy_up_down
    ; UP / DOWN
    LDA hero_row
    CMP enemy_row
    BEQ + ; skip equal
    BPL move_enemy_down ; hero_row >= enemy_row => down
    ; move enemy up
    LDX enemy_row
    LDY enemy_column
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    INY 
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    INY 
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    JSR .f_move_enemy_up
    JMP +
move_enemy_down
    ; move enemy down
    LDX enemy_row
    LDY enemy_column
    INX
    INX
    INX
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    INY 
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    INY 
    ;JSR .f_put_char
    JSR .f_get_char
    CMP #wall
    BEQ +
    JSR .f_move_enemy_down
+
    RTS

.f_move_enemy_down
    LDA enemy_sprite
    CMP #drone_inactive
    BNE +
    RTS
+
    CMP #reaver_inactive
    BNE +
    RTS
+
    CMP #drone_left
    BEQ ++
    CMP #drone_right 
    BNE +++    
++
    LDA drone_move_wait
    CMP #$FF
    BEQ +
    RTS
+
    JSR .f_move_down_enemy_sprite
    RTS
+++
    JSR .f_move_down_enemy_sprite
    ; check next enemy type
    RTS

.f_move_enemy_up
    LDA enemy_sprite
    CMP #drone_inactive
    BNE +
    RTS
+
    CMP #reaver_inactive
    BNE +
    RTS
+
    CMP #drone_left
    BEQ ++
    CMP #drone_right 
    BNE +++    
++
    LDA drone_move_wait
    CMP #$FF
    BEQ +
    RTS
+
    JSR .f_move_up_enemy_sprite
    RTS
+++
    JSR .f_move_up_enemy_sprite
    ; check next enemy type
    RTS


.f_move_down_enemy_sprite
    STA tmp_A
    LDA enemy_index    
    TAY
    LDA enemy_y    
    CLC
    ADC #$01 
    STA enemy_y

    LDA enemy_index
    ASL
    TAY
    LDA enemy_y
    ; store new position
    STA $D005, y

    ; update enemies array
    LDY tmp_X
    INY
    INY
    STA enemies, y    

    LDA tmp_A
    RTS

.f_move_up_enemy_sprite
    STA tmp_A
    LDA enemy_index    
    TAY
    LDA enemy_y    
    SEC
    SBC #$01
    STA enemy_y

    LDA enemy_index
    ASL
    TAY
    LDA enemy_y
    ; store new position
    STA $D005, y

    ; update enemies array
    LDY tmp_X
    INY
    INY
    STA enemies, y    

    LDA tmp_A
    RTS

move_enemy_end;
    ; drone can
    LDX drone_move_wait
    CPX #$FF
    BEQ +
    RTS
+    
    LDX drone_move_wait_inital_value
    STX drone_move_wait
    RTS

.f_activate_enemy_sprite
    LDY enemy_activation_wait
    CPY #$FF
    BEQ +
    RTS  
+  
    JSR .f_update_enemy_sprite    
    RTS

; A new sprite (use enemy_index to determinate di sprite index)
; enemy_array_index start of enemy array row
.f_update_enemy_sprite    
    ; update sprite
    STA tmp_A
    CLC
    ADC #$80    
    LDX enemy_index    
    STA $07FA, x
    ; update sprite in enemy array
    LDA tmp_A
    LDX enemy_array_index    
    STA enemies, x
    LDx tmp_X
    RTS

.f_get_enemy_sprite_row_column
    CLC
    ADC #$02
    JSR .f_get_sprite_row_column
    RTS

.f_exposion_animation
       
    LDY enemy_sprite
    INY 
    TYA ; new explosion frame
    CMP #sprite_enemy_killed
    BNE +
    STA tmp_A
    LDY enemy_index
    LDA $D015
    AND enemies_sprite_clear_mask, y
    STA $D015
    LDA tmp_A
    JMP ++
+
    ; update sprite and return
    JSR .f_update_enemy_sprite    
++    
    LDX tmp_X
    STA enemies, x
    LDY tmp_Y
    RTS