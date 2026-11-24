// ============================================================================
// File: soc_peripheral_tests.sv
// Project: RISC-V SoC UVM Verification Environment
// Description: UVM tests targeting individual peripheral subsystems:
//              Reset, GPIO, UART, SPI, Timer, PWM, and 7-Segment Display.
// ============================================================================

`ifndef SOC_PERIPHERAL_TESTS_SV
`define SOC_PERIPHERAL_TESTS_SV

// ----------------------------------------------------------------------------
// Test: soc_reset_test
// ----------------------------------------------------------------------------
class soc_reset_test extends soc_base_test;
    `uvm_component_utils(soc_reset_test)

    function new(string name = "soc_reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SOC_RESET_TEST", "Executing Power-On Reset & Initialization Test", UVM_LOW)
        #200ns;
        `uvm_info("SOC_RESET_TEST", "Verifying all subsystems released cleanly from reset", UVM_LOW)
        #500ns;
        phase.drop_objection(this);
    endtask
endclass : soc_reset_test

// ----------------------------------------------------------------------------
// Test: gpio_basic_test
// ----------------------------------------------------------------------------
class gpio_basic_test extends soc_base_test;
    `uvm_component_utils(gpio_basic_test)

    function new(string name = "gpio_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_sequence seq;
        phase.raise_objection(this);
        `uvm_info("GPIO_BASIC_TEST", "Executing GPIO Basic Alternating Pattern Test", UVM_LOW)
        seq = gpio_sequence::type_id::create("seq");
        seq.start(env.vseqr.gpio_seqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass : gpio_basic_test

// ----------------------------------------------------------------------------
// Sequence: gpio_random_seq
// ----------------------------------------------------------------------------
class gpio_random_seq extends uvm_sequence #(gpio_seq_item);
    `uvm_object_utils(gpio_random_seq)
    function new(string name = "gpio_random_seq");
        super.new(name);
    endfunction
    virtual task body();
        for (int i = 0; i < 10; i++) begin
            gpio_seq_item item = gpio_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize()) `uvm_fatal("RND", "Randomization failed")
            finish_item(item);
            #100ns;
        end
    endtask
endclass : gpio_random_seq

// ----------------------------------------------------------------------------
// Test: gpio_random_test
// ----------------------------------------------------------------------------
class gpio_random_test extends soc_base_test;
    `uvm_component_utils(gpio_random_test)

    function new(string name = "gpio_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        gpio_random_seq seq;
        phase.raise_objection(this);
        `uvm_info("GPIO_RAND_TEST", "Executing GPIO Randomized Pin Stimulation Test", UVM_LOW)
        seq = gpio_random_seq::type_id::create("seq");
        seq.start(env.vseqr.gpio_seqr);
        #500ns;
        phase.drop_objection(this);
    endtask
endclass : gpio_random_test

// ----------------------------------------------------------------------------
// Test: uart_tx_test
// ----------------------------------------------------------------------------
class uart_tx_test extends soc_base_test;
    `uvm_component_utils(uart_tx_test)

    function new(string name = "uart_tx_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("UART_TX_TEST", "Executing UART Transmitter Verification Test", UVM_LOW)
        // Wait for CPU boot and UART telemetry output
        #50us;
        phase.drop_objection(this);
    endtask
endclass : uart_tx_test

// ----------------------------------------------------------------------------
// Test: uart_rx_test
// ----------------------------------------------------------------------------
class uart_rx_test extends soc_base_test;
    `uvm_component_utils(uart_rx_test)

    function new(string name = "uart_rx_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_basic_seq seq;
        phase.raise_objection(this);
        `uvm_info("UART_RX_TEST", "Executing UART Receiver Stimulation Test", UVM_LOW)
        seq = uart_basic_seq::type_id::create("seq");
        seq.start(env.vseqr.uart_seqr);
        #10us;
        phase.drop_objection(this);
    endtask
endclass : uart_rx_test

// ----------------------------------------------------------------------------
// Test: uart_error_test
// ----------------------------------------------------------------------------
class uart_error_test extends soc_base_test;
    `uvm_component_utils(uart_error_test)

    function new(string name = "uart_error_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        uart_error_seq seq;
        phase.raise_objection(this);
        `uvm_info("UART_ERR_TEST", "Executing UART Error & Framing Fault Test", UVM_LOW)
        seq = uart_error_seq::type_id::create("seq");
        seq.start(env.vseqr.uart_seqr);
        #10us;
        phase.drop_objection(this);
    endtask
endclass : uart_error_test

// ----------------------------------------------------------------------------
// Test: spi_basic_test
// ----------------------------------------------------------------------------
class spi_basic_test extends soc_base_test;
    `uvm_component_utils(spi_basic_test)

    function new(string name = "spi_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_sensor_profile_seq seq;
        phase.raise_objection(this);
        `uvm_info("SPI_BASIC_TEST", "Executing SPI Temperature Sensor Basic Transfer Test", UVM_LOW)
        seq = spi_sensor_profile_seq::type_id::create("seq");
        seq.start(env.vseqr.spi_seqr);
        #20us;
        phase.drop_objection(this);
    endtask
endclass : spi_basic_test

// ----------------------------------------------------------------------------
// Test: spi_temperature_test
// ----------------------------------------------------------------------------
class spi_temperature_test extends soc_base_test;
    `uvm_component_utils(spi_temperature_test)

    function new(string name = "spi_temperature_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_sensor_profile_seq seq;
        phase.raise_objection(this);
        `uvm_info("SPI_TEMP_TEST", "Executing SPI Multi-Tier Temperature Sweep Test", UVM_LOW)
        seq = spi_sensor_profile_seq::type_id::create("seq");
        seq.start(env.vseqr.spi_seqr);
        #40us;
        phase.drop_objection(this);
    endtask
endclass : spi_temperature_test

// ----------------------------------------------------------------------------
// Test: timer_basic_test
// ----------------------------------------------------------------------------
class timer_basic_test extends soc_base_test;
    `uvm_component_utils(timer_basic_test)

    function new(string name = "timer_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        timer_pulse_seq seq;
        phase.raise_objection(this);
        `uvm_info("TIMER_BASIC_TEST", "Executing Timer Measurement & Capture Pulse Test", UVM_LOW)
        seq = timer_pulse_seq::type_id::create("seq");
        seq.start(env.vseqr.timer_seqr);
        #5us;
        phase.drop_objection(this);
    endtask
endclass : timer_basic_test

// ----------------------------------------------------------------------------
// Test: timer_interrupt_test
// ----------------------------------------------------------------------------
class timer_interrupt_test extends soc_base_test;
    `uvm_component_utils(timer_interrupt_test)

    function new(string name = "timer_interrupt_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        timer_pulse_seq seq;
        phase.raise_objection(this);
        `uvm_info("TIMER_INT_TEST", "Executing Timer Interrupt Generation Test", UVM_LOW)
        seq = timer_pulse_seq::type_id::create("seq");
        seq.start(env.vseqr.timer_seqr);
        #10us;
        phase.drop_objection(this);
    endtask
endclass : timer_interrupt_test

// ----------------------------------------------------------------------------
// Test: pwm_basic_test
// ----------------------------------------------------------------------------
class pwm_basic_test extends soc_base_test;
    `uvm_component_utils(pwm_basic_test)

    function new(string name = "pwm_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("PWM_BASIC_TEST", "Executing PWM Fan Controller Basic Waveform Test", UVM_LOW)
        // Monitor at least 4 full PWM cycles (256 cycles * 10ns = 2.56us per PWM period)
        #15us;
        phase.drop_objection(this);
    endtask
endclass : pwm_basic_test

// ----------------------------------------------------------------------------
// Test: pwm_boundary_test
// ----------------------------------------------------------------------------
class pwm_boundary_test extends soc_base_test;
    `uvm_component_utils(pwm_boundary_test)

    function new(string name = "pwm_boundary_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("PWM_BOUND_TEST", "Executing PWM Boundary Duty-Cycle Verification Test", UVM_LOW)
        #25us;
        phase.drop_objection(this);
    endtask
endclass : pwm_boundary_test

// ----------------------------------------------------------------------------
// Test: display_basic_test
// ----------------------------------------------------------------------------
class display_basic_test extends soc_base_test;
    `uvm_component_utils(display_basic_test)

    function new(string name = "display_basic_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("DISP_BASIC_TEST", "Executing Seven-Segment Display Multiplexing Test", UVM_LOW)
        // Refresh division = 10 cycles per digit * 4 digits = 40 cycles (400ns)
        #10us;
        phase.drop_objection(this);
    endtask
endclass : display_basic_test

`endif // SOC_PERIPHERAL_TESTS_SV
