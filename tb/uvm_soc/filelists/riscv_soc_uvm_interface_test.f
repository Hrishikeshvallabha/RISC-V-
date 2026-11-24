+define+RV_BUILD_AXI4
+define+RV_OPENSOURCE

+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/interconnect
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/uart
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/include
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/7segment
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/timer
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/include
+incdir+/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/snapshots/default
+incdir+/home/student/Documents/078_H/proj_dir/tb/uvm_soc

+libext+.v+.sv
-y /home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib
-v /home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib/beh_lib.sv
-v /home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib/mem_lib.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/testbench/user_cells.sv

# VeeR EL2 Packages and Infrastructure
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/include/el2_def.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib/el2_assert.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_mubi_pkg.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib/el2_mem_if.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lib/el2_lib.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_mem.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_pic_ctrl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_dma_ctrl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_pmp.sv

# IFU Subsystem
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_aln_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_compress_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_ifc_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_bp_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_ic_mem.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_mem_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu_iccm_mem.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/ifu/el2_ifu.sv

# DEC Subsystem
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_decode_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_gpr_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_ib_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_pmp_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_tlu_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec_trigger.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dec/el2_dec.sv

# EXU Subsystem
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/exu/el2_exu_alu_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/exu/el2_exu_mul_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/exu/el2_exu_div_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/exu/el2_exu.sv

# LSU Subsystem
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_clkdomain.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_addrcheck.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_lsc_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_stbuf.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_buffer.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_bus_intf.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_ecc.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_mem.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_dccm_ctl.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu_trigger.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/lsu/el2_lsu.sv

# Core Top & Debug
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dbg/el2_dbg.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dmi/dmi_mux.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dmi/dmi_wrapper.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dmi/dmi_jtag_to_core_sync.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/dmi/rvjtag_tap.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_veer.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/Cores-VeeR-EL2/design/el2_veer_wrapper.sv

# 2-Master x 8-Slave AXI4 Crossbar Interconnect
/home/student/Documents/078_H/proj_dir/rtl/IP's/interconnect/priority_encoder.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/interconnect/arbiter.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/interconnect/axi_interconnect.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v

# UART Peripheral (M01: 0x4000_0000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/axi_internal_fifo.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/uart_parity_bit_compute.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/uart_receiver.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/uart_transmitter.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/uart_controller.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/uart/axi_uart_top.v

# SPI Temperature Sensor Peripheral (M04: 0x4000_6000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/ratio_clk.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/spi_clk_gen.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/spi_valid_logic.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/spi_fifo.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/spi_exch_byte.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/spi_ctrl.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/axi_spi_ctrl.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/spi/axi_spi_top.v

# PWM Fan Speed Controller (M05: 0x4000_A000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/pwm/myip_v1_0_S00_AXI.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/pwm/myip_v1_0.v

# Seven-Segment Display Controller (M06: 0x4000_C000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/7segment/seven_segment_decoder.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/7segment/seven_segment_mux.v
/home/student/Documents/078_H/proj_dir/rtl/IP's/7segment/axi_seven_segment.v

# GPIO Subsystem (M02: 0x4000_2000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio/axi4lite_slave_adapter.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio/gpio_bit.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio/gpio_wrapper.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio/gpio_regs.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/gpio/gpio_axi.sv

# Hardware Timer Subsystem (M03: 0x4000_4000)
/home/student/Documents/078_H/proj_dir/rtl/IP's/timer/timer_core.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/timer/timer_regs.sv
/home/student/Documents/078_H/proj_dir/rtl/IP's/timer/timer_axi.sv

# SoC Subsystem Modules
/home/student/Documents/078_H/proj_dir/rtl/soc_memory_axi.sv
/home/student/Documents/078_H/proj_dir/rtl/axi_adapter_lsu_64_to_32.sv
/home/student/Documents/078_H/proj_dir/rtl/axi_adapter_ifu_64_to_32.sv
/home/student/Documents/078_H/proj_dir/rtl/axi_arbiter_2to1.sv
/home/student/Documents/078_H/proj_dir/rtl/soc_veer_el2_temperature_fan_top.sv

# Static SystemVerilog Interface
/home/student/Documents/078_H/proj_dir/tb/uvm_soc/interfaces/gpio_uvm_if.sv

# UVM Dynamic Package (Items, Sequencer, Sequence, Driver, Agent, Env, Test)
/home/student/Documents/078_H/proj_dir/tb/uvm_soc/riscv_soc_pkg.sv

# Static Top-Level Testbench
/home/student/Documents/078_H/proj_dir/tb/uvm_soc/tb_riscv_soc_uvm.sv
