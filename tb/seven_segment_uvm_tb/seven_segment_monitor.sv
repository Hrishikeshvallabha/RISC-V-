class seven_segment_monitor extends uvm_monitor;
virtual seven_segment_if vif;
uvm_analysis_port #(seven_segment_item) ap;
`uvm_component_utils(seven_segment_monitor)
function new(string n,uvm_component p); super.new(n,p); ap=new("ap",this); endfunction
endclass
