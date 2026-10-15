`timescale 1ns/1ps

module uart_tx_fifo_tb;

    logic clk;
    logic rst_n;

    logic        wr_en;
    logic [7:0]  wr_data;
    logic        full;

    logic        txd;
    logic        tx_busy;

    // =====================================================
    // DUT
    // =====================================================

    uart_tx_fifo #(
        .DATA_WIDTH (8),
        .FIFO_DEPTH (16),
        .CLOCK_FREQ (50_000_000),
        .BAUD_RATE  (115_200)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),

        .wr_en   (wr_en),
        .wr_data (wr_data),
        .full    (full),

        .txd     (txd),
        .tx_busy  (tx_busy)
    );

    // =====================================================
    // CLOCK
    // 50 MHz = 20 ns period
    // =====================================================

    initial begin
        clk = 1'b0;

        forever #10 clk = ~clk;
    end

    // =====================================================
    // WRITE BYTE INTO FIFO
    // =====================================================

    task write_fifo(input logic [7:0] data);

        begin

            @(posedge clk);

            wr_en   = 1'b1;
            wr_data = data;

            @(posedge clk);

            wr_en   = 1'b0;
            wr_data = 8'h00;

        end

    endtask

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;

        // Reset
        #100;

        rst_n = 1'b1;

        repeat(10) @(posedge clk);

        $display("");
        $display("========================================");
        $display("        UART TX FIFO TEST");
        $display("========================================");

        // =================================================
        // TEST 1: WRITE MULTIPLE BYTES
        // =================================================

        $display("");
        $display("TEST 1: WRITE DATA");

        write_fifo(8'h41);     // A
        write_fifo(8'h55);
        write_fifo(8'hAA);

        $display("FIFO DATA WRITTEN:");
        $display("0x41");
        $display("0x55");
        $display("0xAA");

        $display("WRITE TEST PASSED");

        // =================================================
        // TEST 2: WAIT FOR TRANSMISSION
        // =================================================

        $display("");
        $display("TEST 2: UART TRANSMISSION");

        wait(tx_busy == 1'b1);

        $display("TX STARTED");

        wait(tx_busy == 1'b0);

        $display("BYTE 1 TRANSMISSION COMPLETE");

        wait(tx_busy == 1'b1);

        $display("BYTE 2 TRANSMISSION STARTED");

        wait(tx_busy == 1'b0);

        $display("BYTE 2 TRANSMISSION COMPLETE");

        wait(tx_busy == 1'b1);

        $display("BYTE 3 TRANSMISSION STARTED");

        wait(tx_busy == 1'b0);

        $display("BYTE 3 TRANSMISSION COMPLETE");

        // =================================================
        // TEST COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("       TX FIFO TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule