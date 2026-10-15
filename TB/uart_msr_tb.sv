`timescale 1ns/1ps

module uart_msr_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst_n;


    // ============================================================
    // MODEM INPUTS
    // ============================================================

    logic cts;
    logic dsr;
    logic ri;
    logic dcd;


    // ============================================================
    // MSR READ ENABLE
    // ============================================================

    logic rd_en;


    // ============================================================
    // MSR OUTPUT
    // ============================================================

    logic [7:0] msr;


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT
    // ============================================================

    uart_msr dut (

        .clk    (clk),
        .rst_n  (rst_n),

        .cts    (cts),
        .dsr    (dsr),
        .ri     (ri),
        .dcd     (dcd),

        .rd_en  (rd_en),

        .msr    (msr)

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
    // CHECK MSR TASK
    // ============================================================

    task check_msr;

        input logic [7:0] expected;
        input string test_name;

        begin

            #1;

            if (msr == expected) begin

                $display(
                    "PASS: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    msr
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    msr
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // READ MSR
    //
    // Reading MSR clears only the delta flags:
    //
    // DCTS
    // DDSR
    // TERI
    // DDCD
    //
    // It does NOT clear the current modem status bits.
    // ============================================================

    task read_msr;

        begin

            @(negedge clk);

            rd_en = 1'b1;

            @(posedge clk);

            #1;

            rd_en = 1'b0;

            @(negedge clk);

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // ========================================================
        // INITIALIZATION
        // ========================================================

        rst_n = 1'b0;

        cts = 1'b0;
        dsr = 1'b0;
        ri  = 1'b0;
        dcd = 1'b0;

        rd_en = 1'b0;

        pass_count = 0;
        fail_count = 0;


        // ========================================================
        // RESET
        // ========================================================

        #50;

        rst_n = 1'b1;

        // Allow previous-state registers to settle
        @(posedge clk);
        #1;


        // ========================================================
        // TEST 1
        // RESET VALUE
        //
        // CTS = 0
        // DSR = 0
        // RI  = 0
        // DCD = 0
        //
        // Expected = 0x00
        // ========================================================

        check_msr(
            8'h00,
            "Reset value"
        );


        // ========================================================
        // TEST 2
        // CTS RISING TRANSITION
        //
        // CTS: 0 -> 1
        //
        // Current CTS = 1  -> bit 4
        // Delta CTS   = 1  -> bit 0
        //
        // Expected = 0x11
        // ========================================================

        @(negedge clk);

        cts = 1'b1;

        @(posedge clk);
        #1;

        check_msr(
            8'h11,
            "CTS rising transition"
        );


        // Clear delta flags
        read_msr;


        // ========================================================
        // TEST 3
        // CTS STABLE AFTER CLEAR
        //
        // CTS remains 1.
        //
        // Current CTS = 1
        // Delta CTS   = 0
        //
        // Expected = 0x10
        // ========================================================

        check_msr(
            8'h10,
            "CTS stable after clear"
        );


        // ========================================================
        // TEST 4
        // CTS FALLING TRANSITION
        //
        // CTS: 1 -> 0
        //
        // Current CTS = 0
        // Delta CTS   = 1
        //
        // Expected = 0x01
        // ========================================================

        @(negedge clk);

        cts = 1'b0;

        @(posedge clk);
        #1;

        check_msr(
            8'h01,
            "CTS falling transition"
        );


        read_msr;


        // ========================================================
        // TEST 5
        // DSR RISING TRANSITION
        //
        // DSR: 0 -> 1
        //
        // Current DSR = 1  -> bit 5 = 0x20
        // Delta DSR   = 1  -> bit 1 = 0x02
        //
        // Expected = 0x22
        // ========================================================

        @(negedge clk);

        dsr = 1'b1;

        @(posedge clk);
        #1;

        check_msr(
            8'h22,
            "DSR rising transition"
        );


        read_msr;


        // ========================================================
        // TEST 6
        // DSR STABLE AFTER CLEAR
        //
        // DSR remains HIGH.
        //
        // Current DSR = 1
        // Delta DSR   = 0
        //
        // Expected = 0x20
        // ========================================================

        check_msr(
            8'h20,
            "DSR stable after clear"
        );


        // ========================================================
        // TEST 7
        // RI RISING EDGE
        //
        // RI: 0 -> 1
        //
        // Current RI = 1 -> bit 6 = 0x40
        //
        // Rising edge does NOT set TERI.
        //
        // DSR is STILL HIGH:
        // DSR = 1 -> bit 5 = 0x20
        //
        // Expected:
        //
        // 0x40 + 0x20 = 0x60
        // ========================================================

        @(negedge clk);

        ri = 1'b1;

        @(posedge clk);
        #1;

        check_msr(
            8'h60,
            "RI rising edge"
        );


        // ========================================================
        // TEST 8
        // RI FALLING EDGE
        //
        // RI: 1 -> 0
        //
        // Current RI = 0
        // TERI = 1 -> bit 2 = 0x04
        //
        // DSR is STILL HIGH:
        // DSR = 1 -> bit 5 = 0x20
        //
        // Expected:
        //
        // 0x04 + 0x20 = 0x24
        // ========================================================

        @(negedge clk);

        ri = 1'b0;

        @(posedge clk);
        #1;

        check_msr(
            8'h24,
            "RI falling edge / TERI"
        );


        read_msr;


        // ========================================================
        // TEST 9
        // DCD RISING TRANSITION
        //
        // DCD: 0 -> 1
        //
        // Current DCD = 1 -> bit 7 = 0x80
        // Delta DCD   = 1 -> bit 3 = 0x08
        //
        // DSR is STILL HIGH:
        // DSR = 1 -> bit 5 = 0x20
        //
        // Expected:
        //
        // 0x80 + 0x20 + 0x08 = 0xA8
        // ========================================================

        @(negedge clk);

        dcd = 1'b1;

        @(posedge clk);
        #1;

        check_msr(
            8'hA8,
            "DCD rising transition"
        );


        read_msr;


        // ========================================================
        // TEST 10
        // CURRENT MODEM STATUS
        //
        // CTS = 0
        // DSR = 1
        // RI  = 0
        // DCD = 1
        //
        // DCD = 0x80
        // DSR = 0x20
        //
        // Expected = 0xA0
        // ========================================================

        check_msr(
            8'hA0,
            "Current modem status"
        );


        // ========================================================
        // TEST 11
        // MULTIPLE MODEM TRANSITIONS
        //
        // CTS: 0 -> 1
        // DSR: 1 -> 0
        // DCD: 1 -> 0
        // RI remains 0
        //
        // Current:
        // CTS = 1 -> 0x10
        //
        // Delta:
        // DCTS = 1 -> 0x01
        // DDSR = 1 -> 0x02
        // DDCD = 1 -> 0x08
        //
        // Total:
        //
        // 0x10 + 0x01 + 0x02 + 0x08
        // = 0x1B
        // ========================================================

        @(negedge clk);

        cts = 1'b1;
        dsr = 1'b0;
        dcd = 1'b0;

        @(posedge clk);
        #1;

        check_msr(
            8'h1B,
            "Multiple modem transitions"
        );


        read_msr;


        // ========================================================
        // TEST 12
        // DELTA FLAGS CLEARED
        //
        // Current:
        // CTS = 1
        // DSR = 0
        // RI  = 0
        // DCD = 0
        //
        // Only current CTS remains.
        //
        // Expected = 0x10
        // ========================================================

        check_msr(
            8'h10,
            "Delta flags cleared"
        );


        // ========================================================
        // TEST 13
        // MULTIPLE STATUS CHANGES
        //
        // Current state before test:
        //
        // CTS = 1
        // DSR = 0
        // RI  = 0
        // DCD = 0
        //
        // Change:
        //
        // CTS: 1 -> 1  = no delta
        // DSR: 0 -> 1  = DDSR
        // RI : 0 -> 1  = rising, no TERI
        // DCD: 0 -> 1  = DDCD
        //
        // Current:
        // CTS = 1 -> 0x10
        // DSR = 1 -> 0x20
        // RI  = 1 -> 0x40
        // DCD = 1 -> 0x80
        //
        // Current total = F0
        //
        // Delta:
        // DDSR = 1 -> 0x02
        // DDCD = 1 -> 0x08
        //
        // Expected = F0 + 0x0A = FA
        // ========================================================

        @(negedge clk);

        cts = 1'b1;
        dsr = 1'b1;
        ri  = 1'b1;
        dcd = 1'b1;

        @(posedge clk);
        #1;

        check_msr(
            8'hFA,
            "Multiple status changes"
        );


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("          MSR TEST SUMMARY");
        $display("========================================");

        $display(
            "PASS COUNT = %0d",
            pass_count
        );

        $display(
            "FAIL COUNT = %0d",
            fail_count
        );

        $display("========================================");
        $display("");


        if (fail_count == 0) begin

            $display("************************************");
            $display("       ALL MSR TESTS PASSED");
            $display("************************************");

        end
        else begin

            $display("************************************");
            $display("       SOME MSR TESTS FAILED");
            $display("************************************");

        end


        #100;

        $finish;

    end

endmodule