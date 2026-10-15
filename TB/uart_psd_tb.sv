`timescale 1ns/1ps

module uart_psd_tb;

    logic       clk;
    logic       rst_n;
    logic       wr_en;
    logic [7:0] wr_data;

    logic [3:0] psd;
    logic [7:0] psd_reg;

    integer pass_count;
    integer fail_count;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    uart_psd dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .wr_en   (wr_en),
        .wr_data (wr_data),
        .psd     (psd),
        .psd_reg (psd_reg)
    );

    // -------------------------------------------------
    // Clock
    // -------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // -------------------------------------------------
    // Check task
    // -------------------------------------------------

    task automatic check_psd (
        input logic [3:0] expected_psd,
        input logic [7:0] expected_reg,
        input string      test_name
    );

        begin

            #1;

            if ((psd === expected_psd) &&
                (psd_reg === expected_reg)) begin

                $display(
                    "PASS: %-35s PSD = %h, PSD_REG = %02h",
                    test_name,
                    psd,
                    psd_reg
                );

                pass_count = pass_count + 1;

            end

            else begin

                $display(
                    "FAIL: %-35s Expected PSD = %h, PSD_REG = %02h | Got PSD = %h, PSD_REG = %02h",
                    test_name,
                    expected_psd,
                    expected_reg,
                    psd,
                    psd_reg
                );

                fail_count = fail_count + 1;

            end

        end

    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;

        // =================================================
        // TEST 1: RESET
        // =================================================

        #12;

        rst_n = 1'b1;

        @(posedge clk);

        check_psd(
            4'h0,
            8'h00,
            "Reset value"
        );

        // =================================================
        // TEST 2: PSD = 0
        // Division factor = 1
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'h00;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'h0,
            8'h00,
            "PSD=0 -> Divide by 1"
        );

        // =================================================
        // TEST 3: PSD = 1
        // Division factor = 2
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'h01;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'h1,
            8'h01,
            "PSD=1 -> Divide by 2"
        );

        // =================================================
        // TEST 4: PSD = 5
        // Division factor = 6
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'h05;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'h5,
            8'h05,
            "PSD=5 -> Divide by 6"
        );

        // =================================================
        // TEST 5: PSD = 15
        // Division factor = 16
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'h0F;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'hF,
            8'h0F,
            "PSD=15 -> Divide by 16"
        );

        // =================================================
        // TEST 6: Upper bits must be ignored
        // Write FF
        // Expected PSD = F
        // Expected register = 0F
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'hFF;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'hF,
            8'h0F,
            "Upper bits ignored"
        );

        // =================================================
        // TEST 7: Hold previous value
        // =================================================

        @(negedge clk);

        wr_en   = 1'b0;
        wr_data = 8'h03;

        @(posedge clk);

        check_psd(
            4'hF,
            8'h0F,
            "Hold previous value"
        );

        // =================================================
        // TEST 8: Change back to PSD = 3
        // Division factor = 4
        // =================================================

        @(negedge clk);

        wr_en   = 1'b1;
        wr_data = 8'h03;

        @(posedge clk);
        #1;

        wr_en = 1'b0;

        check_psd(
            4'h3,
            8'h03,
            "PSD=3 -> Divide by 4"
        );

        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");
        $display("========================================");
        $display("PSD REGISTER TEST COMPLETE");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("PSD TEST PASSED");
        else
            $display("PSD TEST FAILED");

        $finish;

    end

endmodule