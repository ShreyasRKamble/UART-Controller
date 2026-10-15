`timescale 1ns/1ps

module uart_rx_synchronizer_tb;

    // -------------------------------------------------
    // Clock and reset
    // -------------------------------------------------

    logic clk;
    logic rst_n;

    // -------------------------------------------------
    // DUT signals
    // -------------------------------------------------

    logic rxd;
    logic rxd_sync;

    // -------------------------------------------------
    // Test counters
    // -------------------------------------------------

    integer pass_count;
    integer fail_count;

    // -------------------------------------------------
    // DUT
    // -------------------------------------------------

    uart_rx_synchronizer dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .rxd     (rxd),
        .rxd_sync(rxd_sync)
    );

    // -------------------------------------------------
    // 50 MHz clock
    // 20 ns period
    // -------------------------------------------------

    initial begin
        clk = 1'b0;

        forever #10 clk = ~clk;
    end

    // -------------------------------------------------
    // Test procedure
    // -------------------------------------------------

    initial begin

        pass_count = 0;
        fail_count = 0;

        // Initial UART RX idle state
        rxd = 1'b1;

        // -------------------------------------------------
        // Reset
        // -------------------------------------------------

        rst_n = 1'b0;

        repeat (2)
            @(posedge clk);

        #1;

        if (rxd_sync === 1'b1) begin
            $display("PASS: Reset output = 1");
            pass_count++;
        end
        else begin
            $display("FAIL: Reset output = %b", rxd_sync);
            fail_count++;
        end

        // Release reset
        rst_n = 1'b1;

        // -------------------------------------------------
        // Test 1: RXD remains HIGH
        // -------------------------------------------------

        rxd = 1'b1;

        repeat (2)
            @(posedge clk);

        #1;

        if (rxd_sync === 1'b1) begin
            $display("PASS: RXD HIGH synchronized correctly");
            pass_count++;
        end
        else begin
            $display("FAIL: RXD HIGH synchronization");
            fail_count++;
        end

        // -------------------------------------------------
        // Test 2: RXD changes HIGH -> LOW
        // -------------------------------------------------

        rxd = 1'b0;

        // After first clock, FF1 captures LOW.
        @(posedge clk);
        #1;

        if (rxd_sync === 1'b1) begin
            $display("PASS: First stage delay observed");
            pass_count++;
        end
        else begin
            $display("FAIL: Synchronizer changed too early");
            fail_count++;
        end

        // After second clock, FF2 captures FF1.
        @(posedge clk);
        #1;

        if (rxd_sync === 1'b0) begin
            $display("PASS: RXD LOW synchronized after 2 clocks");
            pass_count++;
        end
        else begin
            $display("FAIL: RXD LOW synchronization");
            fail_count++;
        end

        // -------------------------------------------------
        // Test 3: RXD changes LOW -> HIGH
        // -------------------------------------------------

        rxd = 1'b1;

        @(posedge clk);
        #1;

        if (rxd_sync === 1'b0) begin
            $display("PASS: Rising transition delayed correctly");
            pass_count++;
        end
        else begin
            $display("FAIL: Rising transition changed too early");
            fail_count++;
        end

        @(posedge clk);
        #1;

        if (rxd_sync === 1'b1) begin
            $display("PASS: RXD HIGH synchronized after 2 clocks");
            pass_count++;
        end
        else begin
            $display("FAIL: RXD HIGH synchronization");
            fail_count++;
        end

        // -------------------------------------------------
        // Test 4: Multiple transitions
        // -------------------------------------------------

        rxd = 1'b0;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        if (rxd_sync === 1'b0) begin
            $display("PASS: Second LOW transition synchronized");
            pass_count++;
        end
        else begin
            $display("FAIL: Second LOW transition");
            fail_count++;
        end

        rxd = 1'b1;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        if (rxd_sync === 1'b1) begin
            $display("PASS: Second HIGH transition synchronized");
            pass_count++;
        end
        else begin
            $display("FAIL: Second HIGH transition");
            fail_count++;
        end

        // -------------------------------------------------
        // Final result
        // -------------------------------------------------

        $display("----------------------------------------");
        $display("PASS COUNT = %0d", pass_count);
        $display("FAIL COUNT = %0d", fail_count);
        $display("----------------------------------------");

        if (fail_count == 0)
            $display("UART RX SYNCHRONIZER TEST PASSED");
        else
            $display("UART RX SYNCHRONIZER TEST FAILED");

        $finish;

    end

endmodule