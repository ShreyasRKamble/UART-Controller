`timescale 1ns/1ps

module uart_rx_timeout_tb;

    logic clk;
    logic rst_n;

    logic fifo_not_empty;
    logic char_tick;
    logic rx_activity;
    logic rhr_read;

    logic timeout;

    integer pass_count;
    integer fail_count;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    uart_rx_timeout dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .fifo_not_empty (fifo_not_empty),
        .char_tick      (char_tick),
        .rx_activity    (rx_activity),
        .rhr_read       (rhr_read),
        .timeout        (timeout)
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

    task automatic check_timeout (
        input logic expected,
        input string test_name
    );

        begin

            #1;

            if (timeout === expected) begin

                $display(
                    "PASS: %-40s TIMEOUT = %b",
                    test_name,
                    timeout
                );

                pass_count = pass_count + 1;

            end

            else begin

                $display(
                    "FAIL: %-40s Expected = %b, Got = %b",
                    test_name,
                    expected,
                    timeout
                );

                fail_count = fail_count + 1;

            end

        end

    endtask

    // -------------------------------------------------
    // Generate one character tick
    // -------------------------------------------------

    task automatic generate_char_tick;

        begin

            @(negedge clk);

            char_tick = 1'b1;

            @(posedge clk);

            #1;

            char_tick = 1'b0;

        end

    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n          = 1'b0;
        fifo_not_empty = 1'b0;
        char_tick      = 1'b0;
        rx_activity    = 1'b0;
        rhr_read       = 1'b0;

        // =================================================
        // TEST 1: RESET
        // =================================================

        #12;

        rst_n = 1'b1;

        @(posedge clk);

        check_timeout(
            1'b0,
            "Reset timeout"
        );

        // =================================================
        // TEST 2: FIFO EMPTY
        // =================================================

        fifo_not_empty = 1'b0;

        generate_char_tick();

        check_timeout(
            1'b0,
            "FIFO empty does not timeout"
        );

        // =================================================
        // TEST 3: DATA PRESENT
        // First character time
        // =================================================

        fifo_not_empty = 1'b1;

        generate_char_tick();

        check_timeout(
            1'b0,
            "After 1 character time"
        );

        // =================================================
        // TEST 4: Second character time
        // =================================================

        generate_char_tick();

        check_timeout(
            1'b0,
            "After 2 character times"
        );

        // =================================================
        // TEST 5: Third character time
        // =================================================

        generate_char_tick();

        check_timeout(
            1'b0,
            "After 3 character times"
        );

        // =================================================
        // TEST 6: Fourth character time
        // Timeout expected
        // =================================================

        generate_char_tick();

        check_timeout(
            1'b1,
            "After 4 character times"
        );

        // =================================================
        // TEST 7: Timeout remains active
        // =================================================

        generate_char_tick();

        check_timeout(
            1'b1,
            "Timeout remains active"
        );

        // =================================================
        // TEST 8: RHR READ clears timeout
        // =================================================

        @(negedge clk);

        rhr_read = 1'b1;

        @(posedge clk);

        #1;

        rhr_read = 1'b0;

        check_timeout(
            1'b0,
            "RHR read clears timeout"
        );

        // =================================================
        // TEST 9: New character resets timer
        // =================================================

        generate_char_tick();

        generate_char_tick();

        check_timeout(
            1'b0,
            "Two character times after reset"
        );

        @(negedge clk);

        rx_activity = 1'b1;

        @(posedge clk);

        #1;

        rx_activity = 1'b0;

        check_timeout(
            1'b0,
            "New RX activity clears timer"
        );

        // =================================================
        // TEST 10: Four new character times
        // =================================================

        generate_char_tick();
        generate_char_tick();
        generate_char_tick();
        generate_char_tick();

        check_timeout(
            1'b1,
            "New timeout after 4 character times"
        );

        // =================================================
        // TEST 11: FIFO becomes empty
        // =================================================

        @(negedge clk);

        fifo_not_empty = 1'b0;

        @(posedge clk);

        #1;

        check_timeout(
            1'b0,
            "FIFO empty clears timeout"
        );

        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");
        $display("========================================");
        $display("RX TIMEOUT TEST COMPLETE");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("RX TIMEOUT TEST PASSED");
        else
            $display("RX TIMEOUT TEST FAILED");

        $finish;

    end

endmodule