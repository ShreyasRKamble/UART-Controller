`timescale 1ns/1ps

module uart_mcr_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst_n;


    // ============================================================
    // WRITE INTERFACE
    // ============================================================

    logic       wr_en;
    logic [7:0] wr_data;


    // ============================================================
    // READ OUTPUT
    // ============================================================

    logic [7:0] mcr;


    // ============================================================
    // OUTPUTS
    // ============================================================

    logic dtr;
    logic rts;
    logic out1;
    logic out2;

    logic loopback;


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT
    // ============================================================

    uart_mcr dut (

        .clk       (clk),
        .rst_n     (rst_n),

        .wr_en     (wr_en),
        .wr_data   (wr_data),

        .mcr       (mcr),

        .dtr       (dtr),
        .rts       (rts),
        .out1      (out1),
        .out2      (out2),

        .loopback  (loopback)

    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end

    end


    // ============================================================
    // CHECK BYTE
    // ============================================================

    task check_byte;

        input logic [7:0] expected;
        input string test_name;

        begin

            #1;

            if (mcr == expected) begin

                $display(
                    "PASS: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    mcr
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    mcr
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK SIGNAL
    // ============================================================

    task check_signal;

        input logic actual;
        input logic expected;
        input string test_name;

        begin

            if (actual == expected) begin

                $display(
                    "PASS: %s | Expected = %b | Got = %b",
                    test_name,
                    expected,
                    actual
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = %b | Got = %b",
                    test_name,
                    expected,
                    actual
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        rst_n = 1'b0;

        wr_en   = 1'b0;
        wr_data = 8'h00;

        pass_count = 0;
        fail_count = 0;


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        #50;

        rst_n = 1'b1;

        #20;


        // ========================================================
        // TEST 1
        // RESET VALUE
        //
        // Expected MCR = 0x00
        // ========================================================

        check_byte(
            8'h00,
            "Reset value"
        );


        // ========================================================
        // TEST 2
        // DTR
        //
        // Bit 0 = 1
        //
        // Expected = 0x01
        // ========================================================

        wr_data = 8'h01;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h01,
            "DTR"
        );

        check_signal(
            dtr,
            1'b1,
            "DTR output"
        );


        // ========================================================
        // TEST 3
        // RTS
        //
        // Bit 1 = 1
        //
        // Expected = 0x02
        // ========================================================

        wr_data = 8'h02;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h02,
            "RTS"
        );

        check_signal(
            rts,
            1'b1,
            "RTS output"
        );


        // ========================================================
        // TEST 4
        // OUT1
        //
        // Bit 2 = 1
        //
        // Expected = 0x04
        // ========================================================

        wr_data = 8'h04;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h04,
            "OUT1"
        );

        check_signal(
            out1,
            1'b1,
            "OUT1 output"
        );


        // ========================================================
        // TEST 5
        // OUT2
        //
        // Bit 3 = 1
        //
        // Expected = 0x08
        // ========================================================

        wr_data = 8'h08;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h08,
            "OUT2"
        );

        check_signal(
            out2,
            1'b1,
            "OUT2 output"
        );


        // ========================================================
        // TEST 6
        // LOOPBACK
        //
        // Bit 4 = 1
        //
        // Expected = 0x10
        // ========================================================

        wr_data = 8'h10;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h10,
            "Loopback"
        );

        check_signal(
            loopback,
            1'b1,
            "Loopback output"
        );


        // ========================================================
        // TEST 7
        // ALL VALID BITS
        //
        // Bits [4:0] = 11111
        //
        // Expected = 0x1F
        // ========================================================

        wr_data = 8'h1F;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h1F,
            "All MCR control bits"
        );


        // ========================================================
        // TEST 8
        // RESERVED BIT MASKING
        //
        // Write 0xFF.
        //
        // Bits [7:5] must remain zero.
        //
        // Expected = 0x1F
        // ========================================================

        wr_data = 8'hFF;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h1F,
            "Reserved bit masking"
        );


        // ========================================================
        // TEST 9
        // CLEAR ALL CONTROL BITS
        // ========================================================

        wr_data = 8'h00;
        wr_en   = 1'b1;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        check_byte(
            8'h00,
            "Clear MCR"
        );


        // ========================================================
        // TEST 10
        // VERIFY OUTPUTS CLEARED
        // ========================================================

        check_signal(
            dtr,
            1'b0,
            "DTR cleared"
        );

        check_signal(
            rts,
            1'b0,
            "RTS cleared"
        );

        check_signal(
            out1,
            1'b0,
            "OUT1 cleared"
        );

        check_signal(
            out2,
            1'b0,
            "OUT2 cleared"
        );

        check_signal(
            loopback,
            1'b0,
            "Loopback cleared"
        );


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("          MCR TEST SUMMARY");
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
            $display("       ALL MCR TESTS PASSED");
            $display("************************************");

        end
        else begin

            $display("************************************");
            $display("       SOME MCR TESTS FAILED");
            $display("************************************");

        end


        #100;

        $finish;

    end

endmodule