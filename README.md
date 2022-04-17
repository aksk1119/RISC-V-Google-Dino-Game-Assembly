java -jar ../resources/rars1_4.jar mc CompactTextAtZero a \
  dump .text HexText final_iosystem_text.mem \
  dump .data HexText final_iosystem_data.mem \
  dump .text SegmentWindow final_iosystem_s.txt \
  final_iosystem.s

vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateMem final.dcp final_iosystem_text.mem final_iosystem_data.mem final.bit final.dcp

vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateFont final.dcp project_font.txt final.bit final.dcp

vivado -mode batch -source ../resources/load_mem.tcl -tclargs updateBackground final.dcp project_background.txt final.bit final.dcp


