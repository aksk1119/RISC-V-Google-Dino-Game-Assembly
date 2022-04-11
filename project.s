#####################################################################################
#
# final_iosystem.s
#
# This program is written using the enhanced instruction set used in the final
# processor lab.
#
# - Clear the screen with a color and foreground based on switches
#   - Place default character to display at given location
#   (upon startup and when BTNC is pressed)
# - Change defaults for each subsequent press of btnc without other button
#   2: change the character that is moved in the screen by switches
#   3: change the foregound of the character
#   4: change the background of the character
# - Move a given character around the screen with four direction buttons
#
#
#
# Memory Organization:
#   0x0000-0x1fff : text
#   0x2000-0x3fff : data
#   0x7f00-0x7fff : I/O
#   0x8000- : VGA
#
# Registers:
#  x1(ra):  Return address
#  x2(sp):  Stack Pointer
#  x3(gp):  Data segment pointer
#  x4(tp):  I/O base address
#  x8(s0):  VGA base address
#
#  x3(gp):  I/O base address
#  x4(tp):  VGA Base address
#
#
######################################################################################


.globl  main

.text

# I/O address offset constants
    .eqv LED_OFFSET 0x0
    .eqv SWITCH_OFFSET 0x4
    .eqv SEVENSEG_OFFSET 0x18
    .eqv BUTTON_OFFSET 0x24
    .eqv CHAR_COLOR_OFFSET 0x34
    .eqv TIMER 0x30

# I/O mask constants
    .eqv BUTTON_C_MASK 0x01
    .eqv BUTTON_L_MASK 0x02
    .eqv BUTTON_D_MASK 0x04
    .eqv BUTTON_R_MASK 0x08
    .eqv BUTTON_U_MASK 0x10

    
    .eqv COLUMN_MASK 0x1fc
    .eqv COLUMN_SHIFT 2
    .eqv ROW_MASK 0x3e00
    .eqv ROW_SHIFT 9
    .eqv LAST_COLUMN 76                 # 79 - last two columns don't show on screen
    .eqv LAST_ROW 29                    # 31 - last two rows don't show on screen

    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512
    .eqv STARTING_LOC 0xb850
    .eqv SEGMENT_TIMER_INTERVAL 100

    # Graphic basics
    .eqv CHAR_SPACE 0x20 
    .eqv CHAR_MASK 0x0000007f
    .eqv EMPTY_SPACE 0x00000f00

    # Dinosaur Constants
    .eqv DINOSAUR_RUN1_L  0x000fff03
    .eqv DINOSAUR_RUN1_R  0x000fff04
    .eqv DINOSAUR_RUN2_L  0x000fff05
    .eqv DINOSAUR_RUN2_R  0x000fff06
    .eqv DINOSAUR_DUCK1_L 0x000fff07
    .eqv DINOSAUR_DUCK1_R 0x000fff08
    .eqv DINOSAUR_DUCK2_L 0x000fff09
    .eqv DINOSAUR_DUCK2_R 0x000fff0a
    .eqv DINOSAUR_JUMP_L  0x000fff0b
    .eqv DINOSAUR_JUMP_R  0x000fff0c

    .eqv DINOSAUR_RUN_ST  0x00000000
    .eqv DINOSAUR_JUMP_ST 0x00000001
    .eqv DINOSAUR_DUCK_ST 0x00000002

    .eqv RUN_1_ST 0x00000001
    .eqv RUN_2_ST 0x00000002

    .eqv DINOSAUR_RUN_ROW  27
    .eqv DINOSAUR_JUMP_ROW 26
    .eqv DINOSAUR_COLUMN   34

    .eqv JUMP_AIR_TICKS     3
    .eqv JUMP_FALLING_TICKS 4
    .eqv JUMP_GROUND_TICKS  6

    # Obstacles
    .eqv SLIME_SPAWN  0xb850 // TODO Fix the address.
    .eqv BAT_SPAWN  0xb850   // TODO Fix the address.
    .eqv CHAR_BAT   0x000fff02 // TODO Draw new character.
    .eqv CHAR_SLIME 0x000fff01 // TODO Draw new character.

main:
	# Setup the stack: sp = 0x3ffc
    li sp, 0x3ffc
	#lui sp, 4		# 4 << 12 = 0x4000
	#addi sp, sp, -4		# 0x4000 - 4 = 0x3ffc
	# setup the global pointer to the data segment (2<<12 = 0x2000)
	lui gp, 2
    # Prepare I/O base address
    li tp, 0x7f00
    # Prepare VGA base address
    li s0, 0x8000

    ## Array of obstacles to be generated
    

    # Set the color from the switches
    # jal ra, SET_COLOR_FROM_SWITCHES
    # jal ra, SET_COLOR_FROM_STARTING_LOC

RESTART:

    # Clear timer and seven segment display
    sw x0, SEVENSEG_OFFSET(tp)
    sw x0, TIMER(tp)

PROC_BUTTONS:

    # Wait for a button press
    jal ra, PROCESS_BUTTONS

    # If return is zero, process another button
    beq x0, a0, PROC_BUTTONS

    # If return is non-zero, restart
    # jal REACH_END
    j RESTART


################################################################################
# This procedure will check the timere and update the seven segment display
# if the timer has reached another tick value.
################################################################################
UPDATE_TIMER:
    lw t0, TIMER(tp)
    li t1, SEGMENT_TIMER_INTERVAL
    blt t0, t1, UT_DONE
    # timer has reached tick, incremenet seven segmeent display and clear timer
    sw x0, TIMER(tp)
    lw t0, SEVENSEG_OFFSET(tp)
    addi t0, t0, 2
    sw t0, SEVENSEG_OFFSET(tp)

LED_FOR_STATUS:
    lw t3, %lo(DINOSAUR_STATUS)(gp)
    li t0, DINOSAUR_JUMP_ST
    beq t3, t0, STATUS_JUMP_LED
    li t0, DINOSAUR_DUCK_ST
    beq t3, t0, STATUS_DUCK_LED
STATUS_RUN_LED:
    li t0, 0x0001
    sw t0, LED_OFFSET(tp)
    j UPDATE_GRAPHIC
STATUS_JUMP_LED:
    li t0, 0x0002
    sw t0, LED_OFFSET(tp)
    j UPDATE_GRAPHIC
STATUS_DUCK_LED:
    li t0, 0x0004
    sw t0, LED_OFFSET(tp)

UPDATE_GRAPHIC:
    # Update the Graphic
    addi sp, sp, -4	    # Make room to save values on the stack
	sw ra, 0(sp)		# Copy return address to stack
    jal ra, DINOSAUR_CONTROL
    lw ra, 0(sp)		# Restore return address
	addi sp, sp, 4		# Update stack pointer

UT_DONE:
    jalr x0, ra, 0


################################################################################
# Push Buttons
################################################################################

PROCESS_BUTTONS:
    # setup stack frame and save return address
	addi sp, sp, -4	    # Make room to save values on the stack
	sw ra, 0(sp)		# Copy return address to stack

    # Start out making sure the buttons are not being pressed
    # (process buttons only once per press)
PB_1:
    # Update the timer
    jal UPDATE_TIMER
    lw t0, BUTTON_OFFSET(tp)
    # Keep jumping back while a button is being pressed
    bne x0, t0, PB_1

    # A button not being pressed

    # Now wait until a button is pressed
PB_2:
    jal UPDATE_TIMER
    lw t0, BUTTON_OFFSET(tp)
    # Keep jumping back until a button is pressed
    
    # If any button is pressed, go check which button it is.
    # Don't change state if dinosaur is already jumping.
    li t1, DINOSAUR_JUMP_ST
    beq t3, t1, PB_2
    
    # If any button is pressed, go check which button is pressed.
    bne x0, t0, PB_CHECK_BTNU

    # If not, if current state is duck, set state to Run state.
    lw t3, %lo(DINOSAUR_STATUS)(gp)
    li t1, DINOSAUR_DUCK_ST
    beq t3, t1, PB_CHECK_NO_BUTTON

    j PB_2 # Keep looping through this part until there is a button pressed.

PB_CHECK_BTNU:
    addi t1, x0, BUTTON_U_MASK
    bne t0, t1, PB_CHECK_BTND
    # Code for BTNU
    
    # Reset dinosaur jump height.
    add s1, x0, x0
    # Updating dinosaur status to Jump.
    li t0, DINOSAUR_JUMP_ST
    addi t2, gp, %lo(DINOSAUR_STATUS)
    sw t0, 0(t2)

    j PB_CHECK_BTN_DONE

# some button is being pressed.
PB_CHECK_BTND:
    addi t1, x0, BUTTON_D_MASK
    bne t0, t1, PB_CHECK_NO_BUTTON
    # Code for BTND
    # Updating dinosaur status to Duck.
    li t0, DINOSAUR_DUCK_ST
    addi t2, gp, %lo(DINOSAUR_STATUS)
    sw t0, 0(t2)

    j PB_CHECK_BTN_DONE

PB_CHECK_NO_BUTTON:
    # Updating dinosaur status to RUN.

    li t0, DINOSAUR_RUN_ST
    addi t2, gp, %lo(DINOSAUR_STATUS)
    sw t0, 0(t2)

PB_CHECK_BTN_DONE:
    # Restore stack
	lw ra, 0(sp)		# Restore return address
	addi sp, sp, 4		# Update stack pointer

    jalr x0, ra, 0


################################################################################
# The Dinasaur movement state machine
################################################################################
DINOSAUR_CONTROL:
    # This chooses state based off status.
    lw t0, %lo(DINOSAUR_STATUS)(gp)
    li t1, DINOSAUR_JUMP_ST
    beq t0, t1, DINOSAUR_JUMP
    li t1, DINOSAUR_DUCK_ST
    beq t0, t1, DINOSAUR_DUCK

########################################
# Run State
########################################
DINOSAUR_RUN:
    lw t0, %lo(DINOSAUR_RUN_STATUS)(gp)
    li t1, RUN_1_ST
    beq t0, t1, DRAW_RUN2

DRAW_RUN1:
    li t0, RUN_1_ST
    addi t2, gp, %lo(DINOSAUR_RUN_STATUS)
    sw t0, 0(t2)

    # Draw Left side
    lw t0, %lo(RUN1_L)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

    # Draw Right side
    lw t0, %lo(RUN1_R)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    addi t1, t1, 4
    sw t0, 0(t1)

    beq x0, x0, DINOSAUR_CONTROL_DONE

DRAW_RUN2:
    li t0, RUN_2_ST
    addi t2, gp, %lo(DINOSAUR_RUN_STATUS)
    sw t0, 0(t2)

    # Draw Left side
    lw t0, %lo(RUN2_L)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

    # Draw Right side
    lw t0, %lo(RUN2_R)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    addi t1, t1, 4
    sw t0, 0(t1)

    beq x0, x0, DINOSAUR_CONTROL_DONE

########################################
# Jump State
########################################
DINOSAUR_JUMP:
    addi s1, s1, 1
    # If over 6 ticks passed, go to run state.
    addi t0, x0, JUMP_GROUND_TICKS
    blt s1, t0, JUMP_STATUS_CHECK
    li t0, DINOSAUR_RUN_ST
    addi t2, gp, %lo(DINOSAUR_STATUS)
    sw t0, 0(t2)
    j DINOSAUR_RUN

JUMP_STATUS_CHECK:
    # If over 4 ticks passed, get down.
    li t0, JUMP_FALLING_TICKS
    bge s1, t0, JUMP_POS_DOWN
    # If over 2 ticks passed, stay up.
    li t0, JUMP_AIR_TICKS
    bge s1, t0, DRAW_JUMP

JUMP_POS_UP:
    lw s2, %lo(DINOSAUR_LOC)(gp)
    addi t1, s2, NEG_ADDRESSES_PER_ROW
    addi t2, gp, %lo(DINOSAUR_LOC)
    sw t1, 0(t2)
    j DRAW_JUMP

JUMP_POS_DOWN:
    lw s2, %lo(DINOSAUR_LOC)(gp)
    addi t1, s2, ADDRESSES_PER_ROW
    addi t2, gp, %lo(DINOSAUR_LOC)
    sw t1, 0(t2)

DRAW_JUMP:
    # Draw an empty char to the prev position.
    lw t0, %lo(EMPTY_TILE)(gp)              # Load character value to write
    sw t0, 0(s2)                        # Draw Left side
    addi t1, s2, 4                      
    sw t0, 0(t1)                        # Draw Right side

    # Draw Left side
    lw t0, %lo(JUMP_L)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

    # Draw Right side
    lw t0, %lo(JUMP_R)(gp)                   # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    addi t1, t1, 4
    sw t0, 0(t1)

    beq x0, x0, DINOSAUR_CONTROL_DONE

########################################
# Duck State
########################################
DINOSAUR_DUCK:
    lw t0, %lo(DINOSAUR_RUN_STATUS)(gp)
    li t1, RUN_1_ST
    beq t0, t1, DRAW_DUCK2

DRAW_DUCK1:
    li t0, RUN_1_ST
    addi t2, gp, %lo(DINOSAUR_RUN_STATUS)
    sw t0, 0(t2)

    # Draw Left side
    lw t0, %lo(DUCK1_L)(gp)                  # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

    # Draw Right side
    lw t0, %lo(DUCK1_R)(gp)                  # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    addi t1, t1, 4
    sw t0, 0(t1)

    beq x0, x0, DINOSAUR_CONTROL_DONE

DRAW_DUCK2:
    li t0, RUN_2_ST
    addi t2, gp, %lo(DINOSAUR_RUN_STATUS)
    sw t0, 0(t2)

    # Draw Left side
    lw t0, %lo(DUCK2_L)(gp)                  # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

    # Draw Right side
    lw t0, %lo(DUCK2_R)(gp)                  # Load character value to write
    lw t1, %lo(DINOSAUR_LOC)(gp)             # Load address of character location
    addi t1, t1, 4
    sw t0, 0(t1)

DINOSAUR_CONTROL_DONE:
    jalr x0, ra, 0


################################################################################
# Obstacles 
################################################################################
## Designate a register to be the pointer of the obstacle array
## Create a pointer for the obstacle position array
## Create an array that will hold all of the column position values of the obstacles
## When a value in the obstacle position array reaches 0, change the index of all the values in the array, shifting them forward to the beginning.
## In other words, delete and shift to save space.

############################
# Update Obstacle Position
#
# This will update obstacle positions 
# and move the sprite to the next tile.
#
############################


## Erase obstacle, update pointer, draw obstacle



###################################
# Erase Obstacle
# This will erase the old obstacle
#
###################################
ERASE_OBSTACLE:

UPDATE_OBSTACLE_POSITION:

OBSTACLE_POSITION_LOOP:

    bne t0, x0, OBSTACLE_POSITION_LOOP

############################
# Draw Obstacle
#
# a0: type of obstacle
#  -> 0: Slime
#  -> 1: Bat
#
############################
DRAW_OBSTACLE:

DRAW_SLIME:
    lw t0, %lo(SLIME_SPRITE)(gp)                # Load character value to write
    lw t1, %lo(SLIME_SPAWN_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)
DRAW_BAT:
    lw t0, %lo(BAT_SPRITE)(gp)                # Load character value to write
    lw t1, %lo(BAT_SPAWN_LOC)(gp)             # Load address of character location
    sw t0, 0(t1)

############################
# Draw Obstacle
#
# a0: Index of the obstacle in the array.
#
############################


############################
# Collision check
############################
COLLISION_CHECK:
    addi t0, gp, %lo(DINOSAUR_LOC)
    addi t0, t0, 8
    lw t1, 0(t0)
    andi t1, t1, CHAR_MASK
    li t0, CHAR_SPACE
    bne t0, t1, GAMEOVER

COLLISION_CHECK_DONE:
    jalr x0, ra, 0

############################
# Game Over
############################
GAMEOVER:




################################################################################
# Data segment
################################################################################

.data
# This stores the value of the character that represents the destination
DINOSAUR_LOC:
    .word STARTING_LOC

# Dinosaur status
DINOSAUR_STATUS:
    .word DINOSAUR_RUN_ST

# Dinosaur run status (to make animation)
DINOSAUR_RUN_STATUS:
    .word RUN_1_ST

# Holders for the sprite.
RUN1_L:
    .word DINOSAUR_RUN1_L
RUN1_R:
    .word DINOSAUR_RUN1_R
RUN2_L:
    .word DINOSAUR_RUN2_L
RUN2_R:
    .word DINOSAUR_RUN2_R
JUMP_L:
    .word DINOSAUR_JUMP_L
JUMP_R:
    .word DINOSAUR_JUMP_R
DUCK1_L:
    .word DINOSAUR_DUCK1_L
DUCK1_R:
    .word DINOSAUR_DUCK1_R
DUCK2_L:
    .word DINOSAUR_DUCK2_L
DUCK2_R:
    .word DINOSAUR_DUCK2_R
EMPTY_TILE:
    .word EMPTY_SPACE

# The location where bats are spawned.
BAT_SPAWN_LOC:
    .word BAT_SPAWN

# The location where slimes are spawned.
SLIME_SPAWN_LOC:
    .word SLIME_SPAWN

# The Character for slime.
SLIME_SPRITE:
    .word CHAR_SLIME

# The Character for bat.
BAT_SPRITE:
    .word CHAR_BAT

# Use this array to hold the obstacle position.
# This currently holds 10 obstacles.
OBSTACLE_TYPE_ARRAY:
    .word 1 1 1 1 1 1 1 1 1 1 1

OBSTACLE_POS_ARRAY:
    .word 0 0 0 0 0 0 0 0 0 0 0
######################################################################################
