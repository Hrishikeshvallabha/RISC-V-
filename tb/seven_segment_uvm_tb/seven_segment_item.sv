class seven_segment_item extends uvm_sequence_item;

  bit [3:0] an;
  bit [6:0] seg;

  `uvm_object_utils(seven_segment_item)

  function new(string name="seven_segment_item"); super.new(name); endfunction
endclass
