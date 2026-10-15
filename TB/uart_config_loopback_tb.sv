`timescale 1ns/1ps

module uart_config_loopback_tb;

    // =====================================================
    // Clock
    // =====================================================

    logic clk;
    logic rst_n;

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;   // 100 MHz
    end


    // =====================================================
    // Baud and sample ticks
    //
    // For this test:
    //
    // baud period   = 80 clocks
    // sample period = 5 clocks
    //
    // Therefore:
    //
    // 80 / 5 = 16 samples per UART bit
    // =====================================================

    logic baud_tick;
    logic sample_tick;


    // Baud tick = every 80 clocks
    initial begin

        baud_tick = 1'b0;

        forever begin

            repeat (79) @(posedge clk);

            baud_tick <= 1'b1;

            @(posedge clk);

            baud_tick <= 1'b0;

        end

    end


    // Sample tick = every 5 clocks
    initial begin

        sample_tick = 1'b0;

        forever begin

            repeat (4) @(posedge clk);

            sample_tick <= 1'b1;

            @(posedge clk);

            sample_tick <= 1'b0;

        end

    end


    // =====================================================
    // UART signals
    // =====================================================

    logic [7:0] lcr;

    logic       tx_start;
    logic [7:0] tx_data;

    logic       txd;
    logic       tx_busy;
    logic       tx_done;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;

    logic       parity_error;
    logic       framing_error;


    // =====================================================
    // DUT - TX
    // =====================================================

    uart_tx_config tx_dut (

        .clk        (clk),
        .rst_n      (rst_n),
        .baud_tick  (baud_tick),

        .tx_start   (tx_start),
        .tx_data    (tx_data),
        .lcr        (lcr),

        .txd        (txd),
        .tx_busy    (tx_busy),
        .tx_done    (tx_done)

    );


    // =====================================================
    // DUT - RX
    // =====================================================

    uart_rx_config rx_dut (

        .clk          (clk),
        .rst_n        (rst_n),
        .sample_tick  (sample_tick),

        .rxd          (txd),
        .lcr          (lcr),

        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .rx_busy      (rx_busy),

        .parity_error  (parity_error),
        .framing_error (framing_error)

    );


    // =====================================================
    // Task: send byte
    // =====================================================

    task send_byte(
        input [7:0] data
    );

        begin

            @(negedge clk);

            tx_data  = data;
            tx_start = 1'b1;

            @(negedge clk);

            tx_start = 1'b0;

            wait(tx_done);

        end

    endtask


    // =====================================================
    // Reset
    // =====================================================

    task reset_dut;

        begin

            rst_n = 1'b0;

            tx_start = 1'b0;
            tx_data  = 8'h00;

            lcr = 8'h03;

            repeat (5) @(posedge clk);

            rst_n = 1'b1;

            repeat (5) @(posedge clk);

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        // -------------------------------------------------
        // Initial values
        // -------------------------------------------------

        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        lcr      = 8'h03;


        // -------------------------------------------------
        // Reset
        // -------------------------------------------------

        reset_dut;


        // =================================================
        // TEST 1
        // 8-N-1
        // LCR = 00000011
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 1: 8-N-1");
        $display("========================================");

        lcr = 8'h03;

        send_byte(8'h41);

        wait(rx_valid);

        $display("TX DATA = 0x%02h", 8'h41);
        $display("RX DATA = 0x%02h", rx_data);

        if ((rx_data == 8'h41) &&
            (parity_error == 1'b0) &&
            (framing_error == 1'b0)) begin

            $display("8-N-1 LOOPBACK PASSED");

        end
        else begin

            $display("8-N-1 LOOPBACK FAILED");

        end


        // =================================================
        // TEST 2
        // 7-E-1
        // LCR = 00011010
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 2: 7-E-1");
        $display("========================================");

        lcr = 8'h1A;

        send_byte(8'h55);

        wait(rx_valid);

        $display("TX DATA = 0x%02h", 8'h55);
        $display("RX DATA = 0x%02h", rx_data);

        if ((rx_data[6:0] == 7'h55) &&
            (parity_error == 1'b0) &&
            (framing_error == 1'b0)) begin

            $display("7-E-1 LOOPBACK PASSED");

        end
        else begin

            $display("7-E-1 LOOPBACK FAILED");

        end


        // =================================================
        // TEST 3
        // 8-O-1
        // LCR = 00001011
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 3: 8-O-1");
        $display("========================================");

        lcr = 8'h0B;

        send_byte(8'hAA);

        wait(rx_valid);

        $display("TX DATA = 0x%02h", 8'hAA);
        $display("RX DATA = 0x%02h", rx_data);

        if ((rx_data == 8'hAA) &&
            (parity_error == 1'b0) &&
            (framing_error == 1'b0)) begin

            $display("8-O-1 LOOPBACK PASSED");

        end
        else begin

            $display("8-O-1 LOOPBACK FAILED");

        end


        // =================================================
        // TEST 4
        // 8-E-2
        // LCR = 00011111
        // =================================================

        $display("");
        $display("========================================");
        $display("TEST 4: 8-E-2");
        $display("========================================");

        lcr = 8'h1F;

        send_byte(8'hA5);

        wait(rx_valid);

        $display("TX DATA = 0x%02h", 8'hA5);
        $display("RX DATA = 0x%02h", rx_data);

        if ((rx_data == 8'hA5) &&
            (parity_error == 1'b0) &&
            (framing_error == 1'b0)) begin

            $display("8-E-2 LOOPBACK PASSED");

        end
        else begin

            $display("8-E-2 LOOPBACK FAILED");

        end


        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("UART CONFIGURABLE LOOPBACK COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule