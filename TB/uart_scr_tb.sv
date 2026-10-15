`timescale 1ns/1ps

module uart_scr_tb;

    logic       clk;
    logic       rst_n;
    logic       wr_en;
    logic [7:0] wr_data;
    logic [7:0] scr;

    integer pass_count;
    integer fail_count;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    uart_scr dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .scr     (scr)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------
    // Test task
    // -------------------------------------------------

    task automatic check_scr(
        input logic [7:0] expected,
        input string test_name
    );

        begin
            #1;

            if (scr === expected) begin
                $display("PASS: %-30s SCR = %02h",
                         test_name, scr);
                pass_count = pass_count + 1;
            end

            else begin
                $display("FAIL: %-30s Expected = %02h, Got = %02h",
                         test_name, expected, scr);
                fail_count = fail_count + 1;
            end
        end

    endtask

    // -------------------------------------------------
    // Stimulus
    // -------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;

        // ---------------------------------------------
        // Reset
        // ---------------------------------------------

        #12;
        rst_n = 1'b1;

        @(posedge clk);
        check_scr(8'h00, "Reset value");

        // ---------------------------------------------
        // Write 0xA5
        // ---------------------------------------------

        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'hA5;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_scr(8'hA5, "Write A5");

        // ---------------------------------------------
        // Hold value
        // ---------------------------------------------

        @(negedge clk);
        wr_data = 8'h00;

        @(posedge clk);

        check_scr(8'hA5, "Hold previous value");

        // ---------------------------------------------
        // Write 0x5A
        // ---------------------------------------------

        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'h5A;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_scr(8'h5A, "Write 5A");

        // ---------------------------------------------
        // Write FF
        // ---------------------------------------------

        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'hFF;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_scr(8'hFF, "Write FF");

        // ---------------------------------------------
        // Write 00
        // ---------------------------------------------

        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'h00;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_scr(8'h00, "Write 00");

        // ---------------------------------------------
        // Final result
        // ---------------------------------------------

        $display("");
        $display("========================================");
        $display("SCRATCH PAD TEST COMPLETE");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("SCR TEST PASSED");
        else
            $display("SCR TEST FAILED");

        $finish;

    end

endmodule