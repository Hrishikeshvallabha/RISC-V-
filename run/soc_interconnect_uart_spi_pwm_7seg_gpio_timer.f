+incdir+../rtl/IP's/interconnect
+incdir+../rtl/IP's/uart
+incdir+../rtl/IP's/spi/include
+incdir+../rtl/IP's/7segment
+incdir+../rtl/IP's/gpio
+incdir+../rtl/IP's/timer

../rtl/IP's/interconnect/priority_encoder.v
../rtl/IP's/interconnect/arbiter.v
../rtl/IP's/interconnect/axi_interconnect.v
../rtl/IP's/interconnect/axi_interconnect_wrap_2x8.v

../rtl/IP's/uart/axi_internal_fifo.v
../rtl/IP's/uart/uart_parity_bit_compute.v
../rtl/IP's/uart/uart_receiver.v
../rtl/IP's/uart/uart_transmitter.v
../rtl/IP's/uart/uart_controller.v
../rtl/IP's/uart/axi_uart_top.v

../rtl/IP's/spi/ratio_clk.v
../rtl/IP's/spi/spi_clk_gen.v
../rtl/IP's/spi/spi_valid_logic.v
../rtl/IP's/spi/spi_fifo.v
../rtl/IP's/spi/spi_exch_byte.v
../rtl/IP's/spi/spi_ctrl.v
../rtl/IP's/spi/axi_spi_ctrl.v
../rtl/IP's/spi/axi_spi_top.v

../rtl/IP's/pwm/myip_v1_0_S00_AXI.v
../rtl/IP's/pwm/myip_v1_0.v

../rtl/IP's/7segment/seven_segment_decoder.v
../rtl/IP's/7segment/seven_segment_mux.v
../rtl/IP's/7segment/axi_seven_segment.v

../rtl/IP's/gpio/axi4lite_slave_adapter.sv
../rtl/IP's/gpio/gpio_bit.sv
../rtl/IP's/gpio/gpio_wrapper.sv
../rtl/IP's/gpio/gpio_regs.sv
../rtl/IP's/gpio/gpio_axi.sv

../rtl/IP's/timer/timer_core.sv
../rtl/IP's/timer/timer_regs.sv
../rtl/IP's/timer/timer_axi.sv

../rtl/soc_interconnect_uart_spi_pwm_7seg_gpio_timer_top.sv

../tb/tb_soc_interconnect_uart_spi_pwm_7seg_gpio_timer.sv
