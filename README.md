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


