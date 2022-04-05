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
    .eqv PLAYER_IDLE_ROW 28
    .eqv PLAYER_JUMP_ROW 27
    .eqv ADDRESSES_PER_ROW 512
    .eqv NEG_ADDRESSES_PER_ROW -512
    .eqv STARTING_LOC 0x8204
    .eqv ENDING_LOC 0xb700              # 64, 27 or 0x8000+64*4+27*512=0xb700
    .eqv SEGMENT_TIMER_INTERVAL 100

    # Parameters for the MOVE_CHARACTER subroutine
    .eqv MC_WRITE_NEW_CHARACTER 0x1
    .eqv MC_RESTORE_OLD_CHARACTER 0x2
    .eqv MC_RESTORE_OLD_WRITE_NEW_CHARACTER 0x3


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

    # Set the color from the switches
    #jal ra, SET_COLOR_FROM_SWITCHES
    jal ra, SET_COLOR_FROM_STARTING_LOC

RESTART:

    # Clear timer and seven segment display
    sw x0, SEVENSEG_OFFSET(tp)
    sw x0, TIMER(tp)

    # Write ending character at given location
    # lw t0, %lo(ENDING_CHARACTER)(gp)                   # Load character value to write
    # lw t1, %lo(ENDING_CHARACTER_LOC)(gp)               # Load address of character location
    # sw t0, 0(t1)

    # Write moving character at starting location
    li a0, STARTING_LOC
    li a1, MC_WRITE_NEW_CHARACTER
    jal MOVE_CHARACTER

PROC_BUTTONS:

    # Wait for a button press
    jal ra, PROCESS_BUTTONS

    # If return is zero, process another button
    beq x0, a0, PROC_BUTTONS

    # If return is non-zero, restart
    jal REACH_END
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
    // Update the Graphic

    lw 

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
    
    j PB_DONE_BTN_CHECK

PB_CHECK_BTNU:
    addi t1, x0, BUTTON_U_MASK
    bne t0, t1, PB_CHECK_BTNC
    # Code for BTNU - Move pointer up
    
    j PB_DONE_BTN_CHECK


PB_CHECK_BTNC:
    addi t1, x0, BUTTON_C_MASK
    # This branch will only be taken if multiple buttons are pressed
    bne t0, t1, PB_DONE_BTN_CHECK
    # Code for BTNC


PB_DONE_BTN_CHECK:
    # See if the new location is the end location
    lw t1, %lo(ENDING_CHARACTER_LOC)(gp)               # Load address of end location
    bne t1, a0, PB_EXIT_NOT_AT_END
    # Reached the end - return a 1
    addi a0, x0, 1
    beq x0, x0, PB_EXIT

PB_EXIT_NOT_AT_END:
    # return 0 - not reached end
    mv a0, x0

PB_EXIT:
    # Restore stack
	lw ra, 0(sp)		# Restore return address
	addi sp, sp, 4		# Update stack pointer

    jalr x0, ra, 0


################################################################################
#
################################################################################
REACH_END:
    # Display the end character
    li t0, CHAR_Z_MAGENTA
    lw t1, %lo(ENDING_CHARACTER_LOC)(gp)               # Load address of end location
    sw t0, 0(t1)

    # Wait for no button (so last button doesn't count)
RE_1:
    lw t0, BUTTON_OFFSET(tp)
    # Keep jumping back while a button is being pressed
    bne x0, t0, RE_1
    # A button not being pressed
    # Now wait until a button is pressed
RE_2:
    lw t0, BUTTON_OFFSET(tp)
    # Keep jumping back until a button is pressed
    beq x0, t0, RE_2

    jalr x0, ra, 0



########################################
# Data segment
########################################

.data
# This stores the value of the character that represents the destination
PLAYER_STARTING_LOC:
    .word STARTING_LOC

# This stores the value of the character that will move around
MOVING_CHARACTER:
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
######################################################################################
