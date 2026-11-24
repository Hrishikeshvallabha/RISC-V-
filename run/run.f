#========================================================
# VCS FILE LIST
# Project: VeeR EL2 RISC-V SoC
# Testbench: 2 Master x 8 Slave Interconnect
#========================================================
-full64
-sverilog
#-------------------------
# DUT
#-------------------------
../rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v
../rtl/IP's/interconnect/arbiter.v
../rtl/IP's/interconnect/axi_interconnect.v
../rtl/IP's/interconnect/priority_encoder.v

#-------------------------
# TESTBENCH
#-------------------------
../tb/tb_axi_interconnect_wrap_2x8_ACTIVITY_FIXED.sv
