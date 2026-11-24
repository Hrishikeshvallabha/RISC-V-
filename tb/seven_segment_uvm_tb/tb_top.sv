module tb_top;
import uvm_pkg::*; import seven_segment_pkg::*;
seven_segment_if vif();
initial run_test("seven_segment_test");
endmodule
