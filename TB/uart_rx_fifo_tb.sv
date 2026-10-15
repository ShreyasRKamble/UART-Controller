`timescale 1ns/1ps

module uart_rx_fifo_tb;

    logic clk;
    logic rst_n;

    logic        rd_en;
    logic [7:0]  rd_data;
    logic        empty;

    logic        rxd;

    logic        full;
    logic        rx_valid;
    logic        framing_error;

    integer i;

    // =====================================================
    // DUT
    // =====================================================

    uart_rx_fifo #(
        .DATA_WIDTH (8),
        .FIFO_DEPTH (16),
        .CLOCK_FREQ (50_000_000),
        .BAUD_RATE  (115_200)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),

        .rd_en         (rd_en),
        .rd_data       (rd_data),
        .empty         (empty),

        .rxd           (rxd),

        .full          (full),
        .rx_valid      (rx_valid),
        .framing_error (framing_error)
    );

    // =====================================================
    // 50 MHz CLOCK
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // =====================================================
    // SEND ONE UART BIT
    //
    // 50 MHz / 115200 / 16 ? 27 clocks/sample
    // 16 samples/bit
    // =====================================================

    task send_bit(input logic bit_value);

        begin
            rxd = bit_value;

            repeat (16 * 27)
                @(posedge clk);
        end

    endtask

    // =====================================================
    // SEND ONE UART BYTE
    //
    // 8-N-1
    // Start = 0
    // Data  = LSB first
    // Stop  = 1
    // =====================================================

    task send_byte(input logic [7:0] data);

        begin

            // Start bit
            send_bit(1'b0);

            // Data bits
            for (i = 0; i < 8; i = i + 1)
                send_bit(data[i]);

            // Stop bit
            send_bit(1'b1);

        end

    endtask

    // =====================================================
    // READ ONE BYTE FROM FIFO
    // =====================================================

    task read_fifo;

        begin

            @(posedge clk);

            rd_en = 1'b1;

            @(posedge clk);

            rd_en = 1'b0;

            #1;

            $display("RX FIFO DATA = 0x%02h", rd_data);

        end

    endtask

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_n = 1'b0;
        rxd   = 1'b1;
        rd_en = 1'b0;

        // Reset
        #100;

        rst_n = 1'b1;

        repeat (50)
            @(posedge clk);

        $display("");
        $display("========================================");
        $display("        UART RX FIFO TEST");
        $display("========================================");

        // =================================================
        // TEST 1
        // =================================================

        $display("");
        $display("TEST 1: RECEIVE MULTIPLE BYTES");

        send_byte(8'h41);

        #100;

        $display("RX BYTE 1 = 0x%02h", rd_data);

        send_byte(8'h55);

        #100;

        $display("RX BYTE 2 RECEIVED");

        send_byte(8'hAA);

        #100;

        $display("RX BYTE 3 RECEIVED");

        // Give FIFO time to settle
        repeat (20)
            @(posedge clk);

        $display("");
        $display("RX VALID     = %b", rx_valid);
        $display("FIFO EMPTY   = %b", empty);
        $display("FRAMING ERROR = %b", framing_error);

        // =================================================
        // TEST 2: READ FIFO
        // =================================================

        $display("");
        $display("TEST 2: READ RX FIFO");

        read_fifo;

        if (rd_data == 8'h41)
            $display("READ 1 PASSED");
        else
            $display("READ 1 FAILED");

        read_fifo;

        if (rd_data == 8'h55)
            $display("READ 2 PASSED");
        else
            $display("READ 2 FAILED");

        read_fifo;

        if (rd_data == 8'hAA)
            $display("READ 3 PASSED");
        else
            $display("READ 3 FAILED");

        // =================================================
        // TEST 3: EMPTY
        // =================================================

        $display("");
        $display("TEST 3: EMPTY CHECK");

        if (empty)
            $display("EMPTY TEST PASSED");
        else
            $display("EMPTY TEST FAILED");

        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("       RX FIFO TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule