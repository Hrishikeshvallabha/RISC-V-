class seven_segment_driver extends uvm_driver #(seven_segment_item);
virtual seven_segment_if vif;
`uvm_component_utils(seven_segment_driver)
function new(string n,uvm_component p);super.new(n,p);endfunction
task run_phase(uvm_phase phase); forever begin seq_item_port.get_next_item(req); @(posedge vif.clk); seq_item_port.item_done(); end endtask
endclass
