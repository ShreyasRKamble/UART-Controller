`timescale 1ns/1ps

module uart_rx_config_tb;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    logic clk;
    logic rst_n;

    logic sample_tick;
    logic rxd;

    logic [7:0] lcr;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;
    logic       parity_error;
    logic       framing_error;


    // ============================================================
    // TEST RESULT CAPTURE
    // ============================================================

    logic       rx_seen;

    logic [7:0] captured_rx_data;
    logic       captured_parity_error;
    logic       captured_framing_error;


    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT
    // ============================================================

    uart_rx_config dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .sample_tick    (sample_tick),
        .rxd            (rxd),
        .lcr            (lcr),
        .rx_data        (rx_data),
        .rx_valid       (rx_valid),
        .rx_busy        (rx_busy),
        .parity_error   (parity_error),
        .framing_error  (framing_error)
    );


    // ============================================================
    // CLOCK
    // 50 MHz
    // Period = 20 ns
    // ============================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end


    // ============================================================
    // SAMPLE TICK
    //
    // One sample tick every 40 ns.
    //
    // 16 sample ticks = 640 ns / UART bit
    // ============================================================

    initial begin
        sample_tick = 1'b0;

        forever begin

            @(negedge clk);
            sample_tick = 1'b1;

            @(negedge clk);
            sample_tick = 1'b0;

        end

    end


    // ============================================================
    // RX VALID MONITOR
    //
    // Capture the one-clock rx_valid pulse.
    // ============================================================

    always @(posedge rx_valid) begin

        #1;

        rx_seen = 1'b1;

        captured_rx_data       = rx_data;
        captured_parity_error  = parity_error;
        captured_framing_error = framing_error;

        $display("");
        $display("RX VALID DETECTED");
        $display("RX DATA       = 0x%02h", rx_data);
        $display("PARITY ERROR  = %b", parity_error);
        $display("FRAMING ERROR = %b", framing_error);

    end


    // ============================================================
    // SEND ONE UART BIT
    //
    // Each bit = 640 ns
    // 16 sample ticks per bit
    // ============================================================

    task send_bit(input logic bit_value);

        begin

            @(negedge clk);

            rxd = bit_value;

            repeat (32)
                @(posedge clk);

        end

    endtask


    // ============================================================
    // WAIT AFTER FRAME
    // ============================================================

    task wait_for_rx;

        begin

            repeat (10)
                @(posedge clk);

        end

    endtask


    // ============================================================
    // RESET RX
    // ============================================================

    task reset_rx;

        begin

            rst_n = 1'b0;

            rxd = 1'b1;

            rx_seen = 1'b0;

            captured_rx_data       = 8'h00;
            captured_parity_error  = 1'b0;
            captured_framing_error = 1'b0;

            #100;

            rst_n = 1'b1;

            #100;

        end

    endtask


    // ============================================================
    // TEST 1
    //
    // 8-O-1
    //
    // DATA = 0x55
    //
    // 0x55 = 01010101
    //
    // LSB first:
    // 1 0 1 0 1 0 1 0
    //
    // Number of ones = 4
    //
    // Odd parity requires parity bit = 1
    //
    // Frame:
    //
    // START
    // 0
    //
    // DATA
    // 1 0 1 0 1 0 1 0
    //
    // PARITY
    // 1
    //
    // STOP
    // 1
    // ============================================================

    task test_8o1;

        begin

            $display("");
            $display("========================================");
            $display("TEST 1: 8-O-1");
            $display("========================================");

            lcr = 8'h0B;

            reset_rx;

            $display("TX DATA       = 0x55");
            $display("EXPECTED DATA = 0x55");
            $display("EXPECTED PARITY = 1");
            $display("");

            // START
            send_bit(1'b0);

            // DATA 0x55
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);

            // ODD PARITY
            send_bit(1'b1);

            // STOP
            send_bit(1'b1);

            rxd = 1'b1;

            wait_for_rx;

            if (rx_seen &&
                captured_rx_data == 8'h55 &&
                captured_parity_error == 1'b0 &&
                captured_framing_error == 1'b0) begin

                $display("8-O-1 TEST PASSED");
                pass_count = pass_count + 1;

            end
            else begin

                $display("8-O-1 TEST FAILED");
                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // TEST 2
    //
    // 8-E-2
    //
    // DATA = 0x55
    //
    // Number of ones = 4
    // Even parity = 0
    //
    // Two stop bits = 1, 1
    // ============================================================

    task test_8e2;

        begin

            $display("");
            $display("========================================");
            $display("TEST 2: 8-E-2");
            $display("========================================");

            lcr = 8'h1F;

            reset_rx;

            $display("TX DATA       = 0x55");
            $display("EXPECTED DATA = 0x55");
            $display("EXPECTED PARITY = 0");
            $display("STOP BITS = 2");
            $display("");

            // START
            send_bit(1'b0);

            // DATA 0x55
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);

            // EVEN PARITY
            send_bit(1'b0);

            // STOP 1
            send_bit(1'b1);

            // STOP 2
            send_bit(1'b1);

            rxd = 1'b1;

            wait_for_rx;

            if (rx_seen &&
                captured_rx_data == 8'h55 &&
                captured_parity_error == 1'b0 &&
                captured_framing_error == 1'b0) begin

                $display("8-E-2 TEST PASSED");
                pass_count = pass_count + 1;

            end
            else begin

                $display("8-E-2 TEST FAILED");
                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // TEST 3
    //
    // 7-E-1 WITH WRONG PARITY
    //
    // DATA = 0x55
    //
    // 7 data bits:
    //
    // D0-D6 = 1 0 1 0 1 0 1
    //
    // Number of ones = 4
    //
    // Correct EVEN parity = 0
    //
    // We intentionally transmit parity = 1.
    //
    // Expected:
    //
    // parity_error = 1
    // ============================================================

    task test_bad_parity;

        begin

            $display("");
            $display("========================================");
            $display("TEST 3: 7-E-1 BAD PARITY");
            $display("========================================");

            lcr = 8'h1A;

            reset_rx;

            $display("TX DATA       = 0x55");
            $display("CORRECT PARITY = 0");
            $display("SENT PARITY    = 1");
            $display("EXPECTED parity_error = 1");
            $display("");

            // START
            send_bit(1'b0);

            // 7 DATA BITS
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);

            // WRONG PARITY
            send_bit(1'b1);

            // STOP
            send_bit(1'b1);

            rxd = 1'b1;

            wait_for_rx;

            if (rx_seen &&
                captured_rx_data == 8'h55 &&
                captured_parity_error == 1'b1 &&
                captured_framing_error == 1'b0) begin

                $display("BAD PARITY TEST PASSED");
                pass_count = pass_count + 1;

            end
            else begin

                $display("BAD PARITY TEST FAILED");
                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // TEST 4
    //
    // 8-N-1 BAD STOP
    //
    // DATA = 0x41
    //
    // Correct stop = 1
    //
    // We intentionally send stop = 0.
    //
    // Expected:
    //
    // framing_error = 1
    // ============================================================

    task test_bad_stop;

        begin

            $display("");
            $display("========================================");
            $display("TEST 4: 8-N-1 BAD STOP");
            $display("========================================");

            lcr = 8'h03;

            reset_rx;

            $display("TX DATA       = 0x41");
            $display("EXPECTED STOP = 1");
            $display("SENT STOP     = 0");
            $display("EXPECTED framing_error = 1");
            $display("");

            // START
            send_bit(1'b0);

            // DATA = 0x41
            send_bit(1'b1);       // D0
            send_bit(1'b0);       // D1
            send_bit(1'b0);       // D2
            send_bit(1'b0);       // D3
            send_bit(1'b0);       // D4
            send_bit(1'b0);       // D5
            send_bit(1'b1);       // D6
            send_bit(1'b0);       // D7

            // BAD STOP
            send_bit(1'b0);

            rxd = 1'b1;

            wait_for_rx;

            if (rx_seen &&
                captured_rx_data == 8'h41 &&
                captured_parity_error == 1'b0 &&
                captured_framing_error == 1'b1) begin

                $display("BAD STOP TEST PASSED");
                pass_count = pass_count + 1;

            end
            else begin

                $display("BAD STOP TEST FAILED");
                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n = 1'b0;
        rxd   = 1'b1;
        lcr   = 8'h03;

        #100;

        rst_n = 1'b1;

        #100;

        $display("");
        $display("========================================");
        $display("     UART RX CONFIGURATION TEST");
        $display("========================================");
        $display("");


        // --------------------------------------------------------
        // RUN ALL TESTS
        // --------------------------------------------------------

        test_8o1;

        test_8e2;

        test_bad_parity;

        test_bad_stop;


        // --------------------------------------------------------
        // FINAL SUMMARY
        // --------------------------------------------------------

        $display("");
        $display("");
        $display("========================================");
        $display("          FINAL TEST SUMMARY");
        $display("========================================");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin

            $display("");
            $display("************************************");
            $display(" ALL RX CONFIG TESTS PASSED");
            $display("************************************");
            $display("");

        end
        else begin

            $display("");
            $display("************************************");
            $display(" SOME RX TESTS FAILED");
            $display("************************************");
            $display("");

        end


        #100;

        $finish;

    end

endmodule