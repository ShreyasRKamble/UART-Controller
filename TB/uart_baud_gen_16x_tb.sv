`timescale 1ns/1ps

module uart_baud_gen_16x_tb;

    logic clk;
    logic rst_n;

    logic sample_tick;

    integer tick_count;

    // =====================================================
    // DUT
    // =====================================================

    uart_baud_gen_16x #(
        .CLOCK_FREQ(50_000_000),
        .BAUD_RATE (115_200)
    ) dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .sample_tick (sample_tick)
    );

    // =====================================================
    // 50 MHz clock
    // Period = 20 ns
    // =====================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end

    // =====================================================
    // Count sample ticks
    // =====================================================

    always @(posedge clk) begin

        if (!rst_n) begin
            tick_count <= 0;
        end

        else if (sample_tick) begin
            tick_count <= tick_count + 1;
        end

    end

    // =====================================================
    // Test
    // =====================================================

    initial begin

        rst_n     = 1'b0;
        tick_count = 0;

        // Reset
        #100;

        rst_n = 1'b1;

        // Run for approximately 10 UART bit periods
        #100_000;

        $display("");
        $display("========================================");
        $display("       16X BAUD GENERATOR TEST");
        $display("========================================");

        $display("Clock Frequency = 50 MHz");
        $display("Baud Rate       = 115200");
        $display("Oversampling    = 16X");
        $display("Sample Ticks    = %0d", tick_count);

        $display("========================================");

        $stop;

    end

endmodule