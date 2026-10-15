`timescale 1ns/1ps

module uart_baud_gen_prog_tb;

    logic        clk;
    logic        rst_n;
    logic [15:0] divisor;
    logic        baud_tick;

    integer tick_count;
    time    previous_tick;
    time    current_tick;
    time    tick_period;

    // =====================================================
    // DUT
    // =====================================================

    uart_baud_gen_prog #(
        .CLOCK_FREQ(50_000_000)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .divisor   (divisor),
        .baud_tick (baud_tick)
    );

    // =====================================================
    // 50 MHz CLOCK
    // 20 ns period
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // =====================================================
    // MONITOR BAUD TICKS
    // =====================================================

    always @(posedge baud_tick) begin

        current_tick = $time;

        if (tick_count > 0) begin

            tick_period = current_tick - previous_tick;

            $display(
                "BAUD TICK: time = %0t ns, period = %0t ns, divisor = %0d",
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

        rst_n     = 1'b0;
        divisor   = 16'd27;
        tick_count = 0;
        previous_tick = 0;

        // =================================================
        // RESET
        // =================================================

        #100;

        rst_n = 1'b1;

        $display("");
        $display("========================================");
        $display("     PROGRAMMABLE BAUD GENERATOR TEST");
        $display("========================================");

        // =================================================
        // TEST 1: DIVISOR = 27
        // =================================================

        $display("");
        $display("TEST 1: DIVISOR = 27");

        tick_count = 0;

        repeat (5)
            @(posedge baud_tick);

        $display("DIVISOR 27 TEST COMPLETE");

        // =================================================
        // TEST 2: DIVISOR = 50
        // =================================================

        $display("");
        $display("TEST 2: DIVISOR = 50");

        // Reset generator before changing divisor
        rst_n = 1'b0;

        #40;

        divisor = 16'd50;

        rst_n = 1'b1;

        tick_count = 0;

        repeat (5)
            @(posedge baud_tick);

        $display("DIVISOR 50 TEST COMPLETE");

        // =================================================
        // TEST 3: DIVISOR = 100
        // =================================================

        $display("");
        $display("TEST 3: DIVISOR = 100");

        rst_n = 1'b0;

        #40;

        divisor = 16'd100;

        rst_n = 1'b1;

        tick_count = 0;

        repeat (5)
            @(posedge baud_tick);

        $display("DIVISOR 100 TEST COMPLETE");

        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("   BAUD GENERATOR TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule