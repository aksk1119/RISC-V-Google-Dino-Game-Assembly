<h1>About</h1>
This project is implementing RISC-V functions using SystemVerilog.<br>
For this project, Digilent's BASYS 3 has been used as a board. <br>
(For more information about BASYS 3, click <a href="https://digilent.com/shop/basys-3-artix-7-fpga-trainer-board-recommended-for-introductory-users/">Here</a>.)<br>


<h1>Vivado Commands</h1>

<h3>Generate .mem files</h3>
java -jar ../resources/rars1_4.jar mc CompactTextAtZero a \ <br>
  dump .text HexText final_iosystem_text.mem \ <br>
  dump .data HexText final_iosystem_data.mem \ <br>
  dump .text SegmentWindow final_iosystem_s.txt \ <br>
  final_iosystem.s

<h3>Apply the .mem files to .dcp file</h3>
vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateMem final.dcp final_iosystem_text.mem final_iosystem_data.mem final.bit final.dcp

<h3>Add Font memory to the .dcp file</h3>
vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateFont final.dcp project_font.txt final.bit final.dcp

<h3>Add background memory to .dcp file</h3>
vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateBackground final.dcp project_background.txt final.bit final.dcp

<h1>Instructions For the Game</h1>
The project we have created is a game from Google - it is the dinosaur
game that you play when you do not have connection to the internet. 
The object of the game is to avoid the obstacles (bats and rocks) that come
at you and get as far as you can. Whenever you get past an obstacle, your 
score is incremented by 2.

The controls for this game are simple. BTNU is a jump - your dinosaur will
jump over obstacles into the air and come back down. BTND is a duck - your 
dinosaur will duck under obstacles. BTNC is a reset - when you die, the game
will stop until you press BTNC. Once you do, the game will start over from
the beginning.

Bats will kill you when they reach you unless you duck under them. If you 
are running or jumping, the bat will kill you. Rocks will kill you when they 
reach you unless you are jumping over them. If you are running or ducking, 
the rock will kill you.
