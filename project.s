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

    .eqv CHAR_PLAYER_IDLE 0x61
    .eqv CHAR_PLAYER_IDLE_A 0x77700061
    .eqv CHAR_BAT 0x62
    .eqv CHAR_BAT_A 0x77700062
    .eqv CHAR_SLIME 0x02
    .eqv CHAR_SLIME_A 0x77700002
    .eqv CHAR_SPACE 0x20 
    
    .eqv COLUMN_MASK 0x1fc
    .eqv COLUMN_SHIFT 2
    .eqv ROW_MASK 0x3e00
    .eqv ROW_SHIFT 9
    .eqv LAST_COLUMN 76                 # 79 - last two columns don't show on screen
    .eqv LAST_ROW 29                    # 31 - last two rows don't show on screen

    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512
    .eqv STARTING_LOC 0xb850
    .eqv ENDING_LOC 0xb700              # 64, 27 or 0x8000+64*4+27*512=0xb700
    .eqv SEGMENT_TIMER_INTERVAL 100

    # Parameters for the MOVE_CHARACTER subroutine
    .eqv MC_WRITE_NEW_CHARACTER 0x1
    .eqv MC_RESTORE_OLD_CHARACTER 0x2
    .eqv MC_RESTORE_OLD_WRITE_NEW_CHARACTER 0x3

    # Dinosaur Constants
    .eqv DINASAUR_RUN1_L 0x000fff03
    .eqv DINASAUR_RUN1_R 0x000fff04
    .eqv DINASAUR_RUN2_L 0x000fff05
    .eqv DINASAUR_RUN2_R 0x000fff06
    .eqv DINASAUR_DUCT1_L 0x000fff07
    .eqv DINASAUR_DUCT1_R 0x000fff08
    .eqv DINASAUR_DUCT2_L 0x000fff09
    .eqv DINASAUR_DUCT2_R 0x000fff0a
    .eqv DINASAUR_JUMP_L 0x000fff0b
    .eqv DINASAUR_JUMP_R 0x000fff0c

    .eqv DINOSAUR_IDLE_ROW 0x3600
    .eqv DINOSAUR_JUMP_ROW 0x3800
    .eqv DINOSAUR_COLUMN 34

    # Values of Obstacles
    .eqv SLIME_VALUE 1
    .eqv BAT_VALUE 2

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

    # Write ending character at given location
    # lw t0, %lo(ENDING_CHARACTER)(gp)                   # Load character value to write
    # lw t1, %lo(PLAYER_STARTING_LOC)(gp)               # Load address of character location
    # sw t0, 0(t1)

    # Write moving character at starting location
    # li a0, STARTING_LOC
    # li a1, MC_WRITE_NEW_CHARACTER
    # jal MOVE_CHARACTER

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
    bge t1, t0, UT_DONE
    # timer has reached tick, incremenet seven segmeent display and clear timer
    sw x0, TIMER(tp)
    # lw t0, SEVENSEG_OFFSET(tp)
    # addi t0, t0, 1
    # sw t0, SEVENSEG_OFFSET(tp)

UPDATE_GRAPHIC:
    li t0, LAST_COLUMN
    li t1, 1
    beq t1, t0, UT_DONE
    # Update the Graphic
    

    addi t1, t1, 1
    beq x0, x0, UPDATE_GRAPHIC


UT_DONE:
    jalr x0, ra, 0


################################################################################
#
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
    beq x0, t0, PB_2

    # some button is being pressed.

PB_CHECK_BTND:
    addi t1, x0, BUTTON_D_MASK
    bne t0, t1, PB_CHECK_BTNU
    # Code for BTND - Move pointer down
    
    j PB_EXIT_NOT_AT_END

PB_CHECK_BTNU:
    addi t1, x0, BUTTON_U_MASK
    bne t0, t1, PB_EXIT_NOT_AT_END
    # Code for BTNU - Move pointer up
    jal DINASAUR_JUMP
    
    j PB_EXIT_NOT_AT_END

PB_EXIT_NOT_AT_END:
    # return 0 - not reached end
    mv a0, x0

PB_EXIT:
    # Restore stack
	lw ra, 0(sp)		# Restore return address
	addi sp, sp, 4		# Update stack pointer

    jalr x0, ra, 0


################################################################################
# The Dinasaur movement
################################################################################

########################################
# Jump
########################################
DINASAUR_JUMP:
    # If the current status is not jump,
    # Draw Jump Left
    li t1, STARTING_LOC
    li t2, ROW_MASK
    and t0, t1, t2
    li t1, DINOSAUR_JUMP_ROW
    beq t0, t1, DINOSAUR_JUMP_DONE

    lw t0, %lo(DINOSAUR_LOC)(gp)
    li t1, DINASAUR_JUMP_L
    # Save the value of the displaced character
    sw t1, NEG_ADDRESSES_PER_ROW(t0)
    # Draw Jump Right
    lw t0, %lo(DINOSAUR_LOC)(gp)
    # One next column
    addi t0, t0, 4
    li t1, DINASAUR_JUMP_R
    # Save the value of the displaced character
    sw t1, NEG_ADDRESSES_PER_ROW(t0)

DINOSAUR_JUMP_DONE:
    jalr x0, ra, 0



################################################################################
# Obstacles 
################################################################################


## Designate a register to be the pointer of the obstacle array
## Create a pointer for the obstacle position array
## Create an array that will hold all of the column position values of the obstacles
## When a value in the obstacle position array reaches 0, change the index of all the values in the array, shifting them forward to the beginning.
## In other words, delete and shift to save space.
UPDATE_OBSTACLE_POSITION:

DRAW_OBSTACLE:

ERASE_OBSTACLE:

CHECK_COLLISION:





########################################
# Data segment
########################################

.data
# This stores the value of the character that represents the destination
DINOSAUR_LOC:
    .word STARTING_LOC

# This stores the value of the character that will move around
PLAYER_CHARACTER:
    .word CHAR_PLAYER_IDLE

# The location where bats are spawned.
BAT_SPAWN_LOC:
    .word 

# The location where slimes are spawned.
SLIME_SPAWN_LOC:
    .word

# The Character for slime.
SLIME_CHAR:
    .word CHAR_SLIME

# The Character for bat.
BAT_CHAR:
    .word CHAR_BAT

OBSTACLE_ARRAY:
## use a stack pointer to save a register, and then use said register to incremement an index to add to the array.
## currently holds 10 slimes
.word 1 1 1 1 1 1 1 1 1 1
######################################################################################
