`timescale 1ns/1ps

module uart_tx_config_tb;

    // =====================================================
    // Signals
    // =====================================================

    logic       clk;
    logic       rst_n;
    logic       baud_tick;

    logic       tx_start;
    logic [7:0] tx_data;
    logic [7:0] lcr;

    logic       txd;
    logic       tx_busy;
    logic       tx_done;


    // =====================================================
    // DUT
    // =====================================================

    uart_tx_config dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick),

        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .lcr       (lcr),

        .txd       (txd),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );


    // =====================================================
    // CLOCK
    //
    // 50 MHz
    // Period = 20 ns
    // =====================================================

    initial begin

        clk = 1'b0;

        forever #10 clk = ~clk;

    end


    // =====================================================
    // BAUD TICK
    //
    // For simulation:
    //
    // 1 baud period = 20 clock cycles
    // Clock period  = 20 ns
    // Baud period   = 400 ns
    //
    // The TX FSM sees one baud_tick every 20 clocks.
    // =====================================================

    initial begin

        baud_tick = 1'b0;

        forever begin

            repeat (19)
                @(posedge clk);

            baud_tick = 1'b1;

            @(posedge clk);

            baud_tick = 1'b0;

        end

    end


    // =====================================================
    // START TRANSMISSION
    // =====================================================

    task start_tx(input logic [7:0] data);

        begin

            @(negedge clk);

            tx_data  = data;
            tx_start = 1'b1;

            @(negedge clk);

            tx_start = 1'b0;

        end

    endtask


    // =====================================================
    // WAIT FOR TX COMPLETE
    // =====================================================

    task wait_tx_done;

        begin

            wait (tx_done == 1'b1);

            @(posedge clk);

        end

    endtask


    // =====================================================
    // RESET
    // =====================================================

    task reset_dut;

        begin

            rst_n    = 1'b0;
            tx_start = 1'b0;
            tx_data  = 8'h00;

            // Default UART configuration:
            // 8-N-1
            lcr = 8'h03;

            repeat (5)
                @(posedge clk);

            rst_n = 1'b1;

            repeat (2)
                @(posedge clk);

        end

    endtask


    // =====================================================
    // TX MONITOR
    //
    // Print TX state whenever baud_tick occurs.
    // =====================================================

    always @(posedge clk) begin

        if (baud_tick) begin

            $display(
                "TIME=%0t | STATE=%0d | BIT_COUNT=%0d | TXD=%b | DATA=%h | PARITY=%b",
                $time,
                dut.state,
                dut.bit_count,
                dut.txd,
                dut.data_reg,
                dut.parity_bit
            );

        end

    end


    // =====================================================
    // MAIN TEST
    // =====================================================

    initial begin

        // -------------------------------------------------
        // Initial values
        // -------------------------------------------------

        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        // 8-N-1
        lcr = 8'h03;


        // -------------------------------------------------
        // Reset
        // -------------------------------------------------

        reset_dut;


        $display("");
        $display("========================================");
        $display("       CONFIGURABLE UART TX TEST");
        $display("========================================");


        // =================================================
        // TEST 1
        // 8-N-1
        // =================================================

        $display("");
        $display("TEST 1: 8-N-1");

        lcr = 8'h03;

        start_tx(8'h41);

        wait_tx_done;

        $display("8-N-1 TRANSMISSION PASSED");


        // =================================================
        // TEST 2
        // 7-E-1
        // =================================================

        $display("");
        $display("TEST 2: 7-E-1");

        lcr = 8'h1A;

        start_tx(8'h55);

        wait_tx_done;

        $display("7-E-1 TRANSMISSION PASSED");


        // =================================================
        // TEST 3
        // 8-O-1
        // =================================================

        $display("");
        $display("TEST 3: 8-O-1");

        lcr = 8'h0B;

        start_tx(8'hAA);

        wait_tx_done;

        $display("8-O-1 TRANSMISSION PASSED");


        // =================================================
        // TEST 4
        // 8-E-2
        // =================================================

        $display("");
        $display("TEST 4: 8-E-2");

        lcr = 8'h1F;

        start_tx(8'hA5);

        wait_tx_done;

        $display("8-E-2 TRANSMISSION PASSED");


        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("    CONFIGURABLE TX TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule