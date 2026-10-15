`timescale 1ns/1ps

module uart_divisor_tb;

    logic        clk;
    logic        rst_n;

    logic        dll_wr_en;
    logic [7:0]  dll_wr_data;

    logic        dlm_wr_en;
    logic [7:0]  dlm_wr_data;

    logic [15:0] divisor;
    logic [7:0]  dll;
    logic [7:0]  dlm;

    // =====================================================
    // DUT
    // =====================================================

    uart_divisor dut (
        .clk        (clk),
        .rst_n      (rst_n),

        .dll_wr_en  (dll_wr_en),
        .dll_wr_data(dll_wr_data),

        .dlm_wr_en  (dlm_wr_en),
        .dlm_wr_data(dlm_wr_data),

        .divisor    (divisor),

        .dll        (dll),
        .dlm        (dlm)
    );

    // =====================================================
    // CLOCK
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // =====================================================
    // WRITE DLL
    // =====================================================

    task write_dll(input logic [7:0] data);

        begin

            @(negedge clk);

            dll_wr_en   = 1'b1;
            dll_wr_data = data;

            @(posedge clk);

            @(negedge clk);

            dll_wr_en   = 1'b0;
            dll_wr_data = 8'h00;

        end

    endtask

    // =====================================================
    // WRITE DLM
    // =====================================================

    task write_dlm(input logic [7:0] data);

        begin

            @(negedge clk);

            dlm_wr_en   = 1'b1;
            dlm_wr_data = data;

            @(posedge clk);

            @(negedge clk);

            dlm_wr_en   = 1'b0;
            dlm_wr_data = 8'h00;

        end

    endtask

    // =====================================================
    // TEST
    // =====================================================

    initial begin

        rst_n       = 1'b0;

        dll_wr_en   = 1'b0;
        dll_wr_data = 8'h00;

        dlm_wr_en   = 1'b0;
        dlm_wr_data = 8'h00;

        // =================================================
        // RESET
        // =================================================

        #100;

        rst_n = 1'b1;

        repeat (5)
            @(posedge clk);

        $display("");
        $display("========================================");
        $display("          UART DIVISOR TEST");
        $display("========================================");

        // =================================================
        // TEST 1: RESET
        // =================================================

        $display("");
        $display("TEST 1: RESET");

        if ((dll == 8'h01) &&
            (dlm == 8'h00) &&
            (divisor == 16'h0001))

            $display("RESET TEST PASSED");

        else
            $display(
                "RESET TEST FAILED: DLL=%02h DLM=%02h DIV=%04h",
                dll, dlm, divisor
            );

        // =================================================
        // TEST 2: DLL ONLY
        // =================================================

        $display("");
        $display("TEST 2: DLL WRITE");

        write_dll(8'h0C);

        if ((dll == 8'h0C) &&
            (dlm == 8'h00) &&
            (divisor == 16'h000C))

            $display("DLL TEST PASSED");

        else
            $display(
                "DLL TEST FAILED: DLL=%02h DLM=%02h DIV=%04h",
                dll, dlm, divisor
            );

        // =================================================
        // TEST 3: DLM WRITE
        // =================================================

        $display("");
        $display("TEST 3: DLM WRITE");

        write_dlm(8'h12);

        if ((dll == 8'h0C) &&
            (dlm == 8'h12) &&
            (divisor == 16'h120C))

            $display("DLM TEST PASSED");

        else
            $display(
                "DLM TEST FAILED: DLL=%02h DLM=%02h DIV=%04h",
                dll, dlm, divisor
            );

        // =================================================
        // TEST 4: FULL 16-BIT DIVISOR
        // =================================================

        $display("");
        $display("TEST 4: 16-BIT DIVISOR");

        write_dll(8'h34);
        write_dlm(8'h12);

        if (divisor == 16'h1234)
            $display("16-BIT DIVISOR TEST PASSED");
        else
            $display(
                "16-BIT DIVISOR TEST FAILED: DIV=%04h",
                divisor
            );

        // =================================================
        // TEST 5: ANOTHER DIVISOR
        // =================================================

        $display("");
        $display("TEST 5: SECOND DIVISOR");

        write_dll(8'h80);
        write_dlm(8'h01);

        if (divisor == 16'h0180)
            $display("SECOND DIVISOR TEST PASSED");
        else
            $display(
                "SECOND DIVISOR TEST FAILED: DIV=%04h",
                divisor
            );

        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("       DIVISOR TEST COMPLETE");
        $display("========================================");

        #100;

        $stop;

    end

endmodule