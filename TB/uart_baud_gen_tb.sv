`timescale 1ns/1ps

module uart_baud_gen_tb;

    // -------------------------------------------------
    // Clock and reset
    // -------------------------------------------------

    logic clk;
    logic rst_n;

    // -------------------------------------------------
    // DUT output
    // -------------------------------------------------

    logic baud_tick;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    uart_baud_gen #(
        .CLOCK_FREQ(50_000_000),
        .BAUD_RATE(115_200)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );

    // -------------------------------------------------
    // 50 MHz clock
    // Period = 20 ns
    // -------------------------------------------------

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------

    initial begin

        rst_n = 1'b0;

        // Hold reset
        #100;

        rst_n = 1'b1;

        // Run long enough to observe several ticks
        #10_000;

        $stop;

    end

endmodule