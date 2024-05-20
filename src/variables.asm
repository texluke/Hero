; Variables

; temporary 
tmp
    !byte $00

tmp_A
    !byte $00

tmp_X
    !byte $00

tmp_Y
    !byte $00

; Room
current_room 
    !byte $08

refresh_room  ; set to $01 if screen need to be refreshed
    !byte $01

barrier_opened
    !byte $01

genertor_destroyed
    !byte $00

; joystick variables
dx 
    !byte $0046
dy 
    !byte $00

button_pressed   
    !byte $00

hero_facing
    !byte $01 ; right

hero_facing_switched
    !byte $00

hero_moved
    !byte $00

no_smokes
    !byte $02

smokes 
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
    !byte $FF, $FF
smoke_index_in
    !byte $00
smoke_index_out
    !byte $FF

; EXPLOSIONS
explosions
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $00, $00, $00, $00
    !byte $FF

; HERO BULLETS
bullets
    ; active, x, y, char, direction
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00
    !byte $00, $00, $00, $00, $00    
    !byte $FF

bullet_x 
    !byte $00
bullet_y
    !byte $00
bullet_char
    !byte $00
bullet_direction
    !byte $00

; Symbols
current_level 
    !byte $01

sprite_mask
    !byte %00000001    
    !byte %00000010
enemies_sprite_mask     
    !byte %00000100
    !byte %00001000
    !byte %00010000
    !byte %00100000
    !byte %01000000
    !byte %10000000

sprite_clear_mask
    !byte %11111110
    !byte %11111101
enemies_sprite_clear_mask         
    !byte %11111011
    !byte %11110111
    !byte %11101111
    !byte %11011111
    !byte %10111111
    !byte %01111111

enemies_level_1    
    !byte $01,      $01
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   generator,         $40,    $6C,    $00,     $01
    !byte $02,      $02               
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   reaver_inactive,   $3A,    $8A,    $00,     $00            
        !byte   hunter_inactive,   $A4,    $80,    $00,     $00                    
    !byte $03,      $02        
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $00,    $62,    $01,     $00   
        !byte   summoner,          $E0,    $80,    $00,     $01
    !byte $04,      $03
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $9A,    $7A,    $00,     $00   
        !byte   drone_inactive,    $3A,    $62,    $01,     $00   
        !byte   reaver_inactive,   $20,    $BC,    $00,     $00            
    !byte $05,      $02    
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $EA,    $88,    $00,     $00   
        !byte   crusher_inactive,  $3A,    $5A,    $01,     $00   
    !byte $06,      $00    
    !byte $07,      $03
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $20,    $C6,    $00,     $00   
        !byte   drone_inactive,    $9C,    $BC,    $00,     $00
        !byte   drone_inactive,    $20,    $3A,    $00,     $00
    !byte $08,      $00
        ; STARTING ROOM NO ENEMIS                   
    !byte $09,      $01
        ;       SPRITE             X       Y       MSB      STRETCHED
        !byte   drone_inactive,    $9C,    $C8,    $00,     $00   
        ; !byte   drone_inactive,    $30,    $60,    $01,     $00   
        ; !byte   reaver_inactive,   $30,    $C0,    $01,     $00   

enemy_array_index
    !byte $00

enemy_index
    !byte $00

enemy_sprites
    ; two dummy byte to speed up the sprite calculation
    !byte   $00, $00
enemies
    ;       SPRITE  X       Y       MSB     HITS
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00 
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00
    !byte   $00,    $00,    $00,    $00,    $00    
    !byte   $FF

enemy_sprite
    !byte $00

enemy_x
    !byte $00

enemy_y
    !byte $00

enemy_msb
    !byte $00

enemy_hits
    !byte $00

enemy_row
    !byte $00

enemy_column
    !byte $00

enemy_activation

; Hero position
; X
hero_x
    !byte $A0

hero_x_msb
    !byte $00

hero_new_x
    !byte $00

hero_new_x_msb
    !byte $00

; Y
hero_y
    !byte $96

hero_new_y
    !byte $00

hero_row
    !byte $00
hero_column
    !byte $00

hero_powerup
    !byte $00

!set level_width = $03
!set level_heigh = $03    

hero_shoot_wait 
    !byte $00

enemy_activation_wait_inial_value
    !byte $20
enemy_activation_wait
    !byte $00

drone_move_wait_inital_value
    !byte $02
drone_move_wait
    !byte $00

SCRN  = $0400
ScreenRAMRowTableLow
        !byte <SCRN+(40*00),<SCRN+(40*01),<SCRN+(40*02),<SCRN+(40*03),<SCRN+(40*04),<SCRN+(40*05),<SCRN+(40*06),<SCRN+(40*07)
        !byte <SCRN+(40*08),<SCRN+(40*09),<SCRN+(40*10),<SCRN+(40*11),<SCRN+(40*12),<SCRN+(40*13),<SCRN+(40*14),<SCRN+(40*15)
        !byte <SCRN+(40*16),<SCRN+(40*17),<SCRN+(40*18),<SCRN+(40*19),<SCRN+(40*20),<SCRN+(40*21),<SCRN+(40*22),<SCRN+(40*23)
        !byte <SCRN+(40*24)

ScreenRAMRowTableHigh
        !byte >SCRN+(40*00),>SCRN+(40*01),>SCRN+(40*02),>SCRN+(40*03),>SCRN+(40*04),>SCRN+(40*05),>SCRN+(40*06),>SCRN+(40*07)
        !byte >SCRN+(40*08),>SCRN+(40*09),>SCRN+(40*10),>SCRN+(40*11),>SCRN+(40*12),>SCRN+(40*13),>SCRN+(40*14),>SCRN+(40*15)
        !byte >SCRN+(40*16),>SCRN+(40*17),>SCRN+(40*18),>SCRN+(40*19),>SCRN+(40*20),>SCRN+(40*21),>SCRN+(40*22),>SCRN+(40*23)
        !byte >SCRN+(40*24)

LEVEL = $5000
LEVEL_1_Low
    !byte <LEVEL+(0*$3e8),<LEVEL+(1*$3e8),<LEVEL+(2*$3e8),<LEVEL+(3*$3e8),<LEVEL+(4*$3e8)
    !byte <LEVEL+(5*$3e8),<LEVEL+(6*$3e8),<LEVEL+(7*$3e8),<LEVEL+(8*$3e8)
LEVEL_1_High
    !byte >LEVEL+(0*$3e8),>LEVEL+(1*$3e8),>LEVEL+(2*$3e8),>LEVEL+(3*$3e8),>LEVEL+(4*$3e8)
    !byte >LEVEL+(5*$3e8),>LEVEL+(6*$3e8),>LEVEL+(7*$3e8),>LEVEL+(8*$3e8)