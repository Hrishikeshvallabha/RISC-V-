class seven_segment_test extends uvm_test;
seven_segment_env env;
`uvm_component_utils(seven_segment_test)
function new(string n,uvm_component p);super.new(n,p);endfunction
function void build_phase(uvm_phase phase); env=seven_segment_env::type_id::create("env",this); endfunction
endclass
