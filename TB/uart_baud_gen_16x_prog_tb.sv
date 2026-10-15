`timescale 1ns/1ps

module uart_baud_gen_16x_prog_tb;

    logic        clk;
    logic        rst_n;
    logic [15:0] divisor;
    logic        sample_tick;

    integer tick_count;
    time previous_tick;
    time current_tick;
    time tick_period;

    // =====================================================
    // DUT
    // =====================================================

    uart_baud_gen_16x_prog dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .divisor    (divisor),
        .sample_tick(sample_tick)
    );

    // =====================================================
    // 50 MHz CLOCK
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // =====================================================
    // MEASURE SAMPLE TICK PERIOD
    // =====================================================

    always @(posedge sample_tick) begin

        current_tick = $time;

        if (tick_count > 0) begin

            tick_period = current_tick - previous_tick;

            $display(
                "SAMPLE TICK: time = %0t ns, period = %0t ns, divisor = %0d",
                current_tick,
                tick_period,
                divisor
            );

        end

        previous_tick = current_tick;
        tick_count = tick_count + 1;

    end

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_n          = 1'b0;
        divisor        = 16'd27;
        tick_count     = 0;
        previous_tick  = 0;

        // =================================================
        // RESET
        // =================================================

        #100;

        rst_n = 1'b1;

        $display("");
        $display("========================================");
        $display("   PROGRAMMABLE 16X BAUD GENERATOR");
        $display("========================================");

        // =================================================
        // TEST 1: DIVISOR = 27
        // Expected: 27 clocks × 20 ns = 540 ns
        // =================================================

        $display("");
        $display("TEST 1: DIVISOR = 27");

        tick_count = 0;

        repeat (5)
            @(posedge sample_tick);

        $display("DIVISOR 27 TEST COMPLETE");

        // =================================================
        // TEST 2: DIVISOR = 50
        // Expected: 50 clocks × 20 ns = 1000 ns
        // =================================================

        $display("");
        $display("TEST 2: DIVISOR = 50");

        rst_n = 1'b0;

        #40;

        divisor = 16'd50;

        tick_count = 0;

        rst_n = 1'b1;

        repeat (5)
            @(posedge sample_tick);

        $display("DIVISOR 50 TEST COMPLETE");

        // =================================================
        // TEST 3: DIVISOR = 100
        // Expected: 100 clocks × 20 ns = 2000 ns
        // =================================================

        $display("");
        $display("TEST 3: DIVISOR = 100");

        rst_n = 1'b0;

        #40;

        divisor = 16'd100;

        tick_count = 0;

        rst_n = 1'b1;

        repeat (5)
            @(posedge sample_tick);

        $display("DIVISOR 100 TEST COMPLETE");

        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("   16X BAUD GENERATOR TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule