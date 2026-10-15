`timescale 1ns/1ps

module uart_rx_16x_tb;

    // =====================================================
    // SIGNALS
    // =====================================================

    logic       clk;
    logic       rst_n;

    logic       sample_tick;
    logic       rxd;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;
    logic       framing_error;

    integer i;


    // =====================================================
    // DUT
    // =====================================================

    uart_rx_16x dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_tick   (sample_tick),
        .rxd           (rxd),
        .rx_data       (rx_data),
        .rx_valid      (rx_valid),
        .rx_busy       (rx_busy),
        .framing_error (framing_error)
    );


    // =====================================================
    // 50 MHz CLOCK
    //
    // Clock period = 20 ns
    // =====================================================

    initial begin

        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end

    end


    // =====================================================
    // 16× SAMPLE TICK GENERATOR
    //
    // 50 MHz / (115200 × 16)
    // ? 27 clock cycles
    //
    // One sample tick ? 540 ns
    // 16 sample ticks ? 8.64 us
    // =====================================================

    initial begin

        sample_tick = 1'b0;

        forever begin

            repeat (26)
                @(posedge clk);

            @(posedge clk);
            sample_tick = 1'b1;

            @(posedge clk);
            sample_tick = 1'b0;

        end

    end


    // =====================================================
    // UART BIT TASK
    //
    // One UART bit = 16 sample periods
    //
    // 16 × 27 clocks = 432 clocks
    // 432 × 20 ns = 8.64 us
    // =====================================================

    task send_bit(input logic bit_value);

        begin

            // Put bit on serial line
            rxd = bit_value;

            // Hold for one complete UART bit period
            repeat (16 * 27)
                @(posedge clk);

        end

    endtask


    // =====================================================
    // UART BYTE TASK
    //
    // Format:
    //
    // START
    // 8 DATA BITS - LSB FIRST
    // STOP
    //
    // 8-N-1
    // =====================================================

    task send_byte(input logic [7:0] data);

        begin

            // -------------------------
            // START BIT
            // -------------------------

            send_bit(1'b0);


            // -------------------------
            // DATA BITS
            // -------------------------

            for (i = 0; i < 8; i = i + 1) begin

                send_bit(data[i]);

            end


            // -------------------------
            // STOP BIT
            // -------------------------

            send_bit(1'b1);

        end

    endtask


    // =====================================================
    // MAIN TEST
    // =====================================================

    initial begin

        // -------------------------------------------------
        // Initial conditions
        // -------------------------------------------------

        rst_n = 1'b0;
        rxd   = 1'b1;


        // -------------------------------------------------
        // RESET
        // -------------------------------------------------

        #100;

        rst_n = 1'b1;


        // Give RX some time to settle
        repeat (50)
            @(posedge clk);


        // =================================================
        // TEST START
        // =================================================

        $display("");
        $display("========================================");
        $display("       UART RX 16X TEST");
        $display("========================================");


        // =================================================
        // TEST 1
        // Send 0x41 = ASCII 'A'
        // =================================================

        send_byte(8'h41);

        // Allow RX outputs to settle
        #100;


        $display("");
        $display("TEST 1");
        $display("TX BYTE = 0x41");
        $display("RX DATA = 0x%02h", rx_data);


        if (rx_data == 8'h41) begin

            $display("TEST 1 PASSED");

        end

        else begin

            $display("TEST 1 FAILED");

        end


        if (framing_error) begin

            $display("WARNING: FRAMING ERROR");

        end

        else begin

            $display("FRAMING ERROR = 0");

        end


        // =================================================
        // WAIT
        // =================================================

        #5000;


        // =================================================
        // TEST 2
        // Send 0x55
        // =================================================

        send_byte(8'h55);

        #100;


        $display("");
        $display("TEST 2");
        $display("TX BYTE = 0x55");
        $display("RX DATA = 0x%02h", rx_data);


        if (rx_data == 8'h55) begin

            $display("TEST 2 PASSED");

        end

        else begin

            $display("TEST 2 FAILED");

        end


        if (framing_error) begin

            $display("WARNING: FRAMING ERROR");

        end

        else begin

            $display("FRAMING ERROR = 0");

        end


        // =================================================
        // TEST 3
        // Send 0xAA
        // =================================================

        #5000;

        send_byte(8'hAA);

        #100;


        $display("");
        $display("TEST 3");
        $display("TX BYTE = 0xAA");
        $display("RX DATA = 0x%02h", rx_data);


        if (rx_data == 8'hAA) begin

            $display("TEST 3 PASSED");

        end

        else begin

            $display("TEST 3 FAILED");

        end


        // =================================================
        // TEST COMPLETE
        // =================================================

        #5000;

        $display("");
        $display("========================================");
        $display("       RX 16X TEST COMPLETE");
        $display("========================================");


        $stop;

    end

endmodule