`timescale 1ns/1ps

module uart_lcr_tb;

    logic       clk;
    logic       rst_n;
    logic       wr_en;
    logic [7:0] wr_data;
    logic [7:0] lcr;

    // =====================================================
    // DUT
    // =====================================================

    uart_lcr dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .lcr      (lcr)
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
    // WRITE LCR REGISTER
    // =====================================================

    task write_lcr(input logic [7:0] data);

        begin

            // Put data on bus before rising edge
            @(negedge clk);

            wr_en   = 1'b1;
            wr_data = data;

            // DUT samples here
            @(posedge clk);

            // Remove write enable after sampling
            @(negedge clk);

            wr_en   = 1'b0;
            wr_data = 8'h00;

        end

    endtask

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        // Initial values
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;

        // =================================================
        // RESET
        // =================================================

        #100;

        rst_n = 1'b1;

        repeat (5)
            @(posedge clk);

        $display("");
        $display("========================================");
        $display("              LCR TEST");
        $display("========================================");

        // =================================================
        // TEST 1: RESET VALUE
        // =================================================

        $display("");
        $display("TEST 1: RESET");

        if (lcr == 8'h00)
            $display("RESET TEST PASSED");
        else
            $display("RESET TEST FAILED: LCR = 0x%02h", lcr);

        // =================================================
        // TEST 2: 8-N-1
        // =================================================

        $display("");
        $display("TEST 2: WRITE 8-N-1");

        write_lcr(8'h03);

        if (lcr == 8'h03)
            $display("8-N-1 CONFIG PASSED");
        else
            $display(
                "8-N-1 CONFIG FAILED: LCR = 0x%02h",
                lcr
            );

        // =================================================
        // TEST 3: 8-E-1
        // =================================================

        $display("");
        $display("TEST 3: WRITE 8-E-1");

        write_lcr(8'h1B);

        if (lcr == 8'h1B)
            $display("8-E-1 CONFIG PASSED");
        else
            $display(
                "8-E-1 CONFIG FAILED: LCR = 0x%02h",
                lcr
            );

        // =================================================
        // TEST 4: 7-E-1
        // =================================================

        $display("");
        $display("TEST 4: WRITE 7-E-1");

        write_lcr(8'h1A);

        if (lcr == 8'h1A)
            $display("7-E-1 CONFIG PASSED");
        else
            $display(
                "7-E-1 CONFIG FAILED: LCR = 0x%02h",
                lcr
            );

        // =================================================
        // TEST 5: DLAB
        // =================================================

        $display("");
        $display("TEST 5: DLAB");

        write_lcr(8'h83);

        if (lcr == 8'h83)
            $display("DLAB TEST PASSED");
        else
            $display(
                "DLAB TEST FAILED: LCR = 0x%02h",
                lcr
            );

        // =================================================
        // TEST 6: BREAK
        // =================================================

        $display("");
        $display("TEST 6: BREAK");

        write_lcr(8'h43);

        if (lcr == 8'h43)
            $display("BREAK TEST PASSED");
        else
            $display(
                "BREAK TEST FAILED: LCR = 0x%02h",
                lcr
            );

        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("          LCR TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule