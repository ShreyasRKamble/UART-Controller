`timescale 1ns/1ps

module uart_loopback_tb;

    logic       clk;
    logic       rst_n;

    logic       baud_tick;

    logic       tx_start;
    logic [7:0] tx_data;

    logic       txd;
    logic       tx_busy;
    logic       tx_done;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;
    logic       framing_error;

    // =====================================================
    // BAUD GENERATOR
    // =====================================================

    uart_baud_gen #(
        .CLOCK_FREQ(50_000_000),
        .BAUD_RATE (115_200)
    ) baud_gen (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );

    // =====================================================
    // TX
    // =====================================================

    uart_tx tx (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick),

        .tx_start  (tx_start),
        .tx_data   (tx_data),

        .txd       (txd),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    // =====================================================
    // RX
    // =====================================================

    uart_rx rx (
        .clk           (clk),
        .rst_n         (rst_n),
        .baud_tick     (baud_tick),

        .rxd           (txd),

        .rx_data       (rx_data),
        .rx_valid      (rx_valid),
        .rx_busy       (rx_busy),
        .framing_error (framing_error)
    );

    // =====================================================
    // 50 MHz CLOCK
    // =====================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        // Reset
        #100;

        rst_n = 1'b1;

        #100;

        $display("");
        $display("========================================");
        $display("       UART TX -> RX LOOPBACK");
        $display("========================================");

        // -------------------------------------------------
        // Send byte A
        // -------------------------------------------------

        tx_data  = 8'h41;
        tx_start = 1'b1;

        #100;

        tx_start = 1'b0;

        // Wait for RX to receive byte
        wait(rx_valid);

        $display("TX DATA = 0x%02h", tx_data);
        $display("RX DATA = 0x%02h", rx_data);

        if (rx_data == tx_data) begin
            $display("LOOPBACK TEST 1 PASSED");
        end
        else begin
            $display("LOOPBACK TEST 1 FAILED");
        end

        if (framing_error) begin
            $display("ERROR: FRAMING ERROR");
        end

        // -------------------------------------------------
        // Wait before next byte
        // -------------------------------------------------

        #10_000;

        // -------------------------------------------------
        // Send byte 55
        // -------------------------------------------------

        tx_data  = 8'h55;
        tx_start = 1'b1;

        #100;

        tx_start = 1'b0;

        wait(rx_valid);

        $display("");
        $display("TX DATA = 0x%02h", tx_data);
        $display("RX DATA = 0x%02h", rx_data);

        if (rx_data == tx_data) begin
            $display("LOOPBACK TEST 2 PASSED");
        end
        else begin
            $display("LOOPBACK TEST 2 FAILED");
        end

        // -------------------------------------------------
        // Finish
        // -------------------------------------------------

        #10_000;

        $display("");
        $display("========================================");
        $display("       LOOPBACK TEST COMPLETE");
        $display("========================================");

        $stop;

    end

endmodule