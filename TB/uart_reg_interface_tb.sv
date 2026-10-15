`timescale 1ns/1ps

module uart_reg_interface_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst_n;


    // ============================================================
    // HOST / CPU INTERFACE
    // ============================================================

    logic [2:0] addr;
    logic       wr_en;
    logic       rd_en;
    logic [7:0] wr_data;

    logic [7:0] rd_data;


    // ============================================================
    // REGISTER INPUTS
    // ============================================================

    logic [7:0] lsr;
    logic [7:0] mcr;
    logic [7:0] msr;
    logic [7:0] scr;

    logic [7:0] lcr;
    logic [7:0] fcr;

    logic [7:0] dll;
    logic [7:0] dlm;


    // ============================================================
    // RX INPUT
    // ============================================================

    logic [7:0] rx_data;
    logic       rx_data_valid;


    // ============================================================
    // TX OUTPUTS
    // ============================================================

    logic       tx_write;
    logic [7:0] tx_data;


    // ============================================================
    // RX OUTPUTS
    // ============================================================

    logic rx_read;


    // ============================================================
    // REGISTER WRITE ENABLES
    // ============================================================

    logic lcr_wr_en;
    logic fcr_wr_en;

    logic dll_wr_en;
    logic dlm_wr_en;

    logic mcr_wr_en;
    logic scr_wr_en;


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT
    // ============================================================

    uart_reg_interface dut (

        .clk                (clk),
        .rst_n              (rst_n),

        .addr               (addr),
        .wr_en              (wr_en),
        .rd_en              (rd_en),
        .wr_data            (wr_data),

        .rd_data            (rd_data),

        .lsr                (lsr),
        .mcr                (mcr),
        .msr                (msr),
        .scr                (scr),

        .lcr                (lcr),
        .fcr                (fcr),

        .dll                (dll),
        .dlm                (dlm),

        .rx_data            (rx_data),
        .rx_data_valid      (rx_data_valid),

        .tx_write           (tx_write),
        .tx_data            (tx_data),

        .rx_read            (rx_read),

        .lcr_wr_en          (lcr_wr_en),
        .fcr_wr_en          (fcr_wr_en),

        .dll_wr_en          (dll_wr_en),
        .dlm_wr_en          (dlm_wr_en),

        .mcr_wr_en          (mcr_wr_en),
        .scr_wr_en          (scr_wr_en)

    );


    // ============================================================
    // CLOCK
    // 50 MHz
    // ============================================================

    initial begin

        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end

    end


    // ============================================================
    // CHECK SIGNAL TASK
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
    // CHECK BYTE TASK
    // ============================================================

    task check_byte;

        input logic [7:0] actual;
        input logic [7:0] expected;
        input string test_name;

        begin

            if (actual == expected) begin

                $display(
                    "PASS: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    actual
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    actual
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // INITIAL TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        rst_n = 1'b0;

        addr   = 3'h0;
        wr_en  = 1'b0;
        rd_en  = 1'b0;
        wr_data = 8'h00;

        lsr = 8'h60;
        mcr = 8'h00;
        msr = 8'h00;
        scr = 8'h00;

        lcr = 8'h00;
        fcr = 8'h00;

        dll = 8'h01;
        dlm = 8'h00;

        rx_data       = 8'h00;
        rx_data_valid = 1'b0;

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
        // THR WRITE
        //
        // DLAB = 0
        // Address = 0x00
        // Write = 0x41
        //
        // Expected:
        // tx_write = 1
        // tx_data  = 0x41
        // ========================================================

        addr    = 3'h0;
        wr_data = 8'h41;
        wr_en   = 1'b1;

        #1;

        check_signal(
            tx_write,
            1'b1,
            "THR write enable"
        );

        check_byte(
            tx_data,
            8'h41,
            "THR write data"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 2
        // RBR READ
        //
        // DLAB = 0
        // Address = 0x00
        // RX data = 0x55
        //
        // Expected:
        // rd_data = 0x55
        // rx_read = 1
        // ========================================================

        rx_data = 8'h55;

        addr = 3'h0;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h55,
            "RBR read data"
        );

        check_signal(
            rx_read,
            1'b1,
            "RBR read enable"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 3
        // LCR WRITE
        //
        // Address = 0x03
        // Write = 0x83
        //
        // Expected:
        // lcr_wr_en = 1
        // ========================================================

        addr    = 3'h3;
        wr_data = 8'h83;
        wr_en   = 1'b1;

        #1;

        check_signal(
            lcr_wr_en,
            1'b1,
            "LCR write enable"
        );

        wr_en = 1'b0;


        // ========================================================
        // IMPORTANT
        //
        // Simulate LCR[7] = DLAB = 1
        // ========================================================

        lcr = 8'h83;


        // ========================================================
        // TEST 4
        // DLL WRITE
        //
        // DLAB = 1
        // Address = 0x00
        //
        // Expected:
        // dll_wr_en = 1
        // tx_write  = 0
        // ========================================================

        addr    = 3'h0;
        wr_data = 8'h1B;
        wr_en   = 1'b1;

        #1;

        check_signal(
            dll_wr_en,
            1'b1,
            "DLL write enable"
        );

        check_signal(
            tx_write,
            1'b0,
            "DLL write blocks THR"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 5
        // DLM WRITE
        //
        // DLAB = 1
        // Address = 0x01
        //
        // Expected:
        // dlm_wr_en = 1
        // ========================================================

        addr    = 3'h1;
        wr_data = 8'h00;
        wr_en   = 1'b1;

        #1;

        check_signal(
            dlm_wr_en,
            1'b1,
            "DLM write enable"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 6
        // DLL READ
        //
        // DLAB = 1
        // Address = 0x00
        // DLL = 0x1B
        //
        // Expected = 0x1B
        // ========================================================

        dll = 8'h1B;

        addr  = 3'h0;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h1B,
            "DLL read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 7
        // DLM READ
        //
        // DLAB = 1
        // Address = 0x01
        // DLM = 0x00
        //
        // Expected = 0x00
        // ========================================================

        dlm = 8'h00;

        addr  = 3'h1;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h00,
            "DLM read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 8
        // FCR WRITE
        //
        // Address = 0x02
        // Write = 0x07
        //
        // Expected:
        // fcr_wr_en = 1
        // ========================================================

        // Return DLAB to 0
        lcr = 8'h03;

        addr    = 3'h2;
        wr_data = 8'h07;
        wr_en   = 1'b1;

        #1;

        check_signal(
            fcr_wr_en,
            1'b1,
            "FCR write enable"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 9
        // LCR READ
        //
        // Address = 0x03
        // LCR = 0x03
        //
        // Expected = 0x03
        // ========================================================

        addr  = 3'h3;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h03,
            "LCR read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 10
        // MCR WRITE
        //
        // Address = 0x04
        //
        // Expected:
        // mcr_wr_en = 1
        // ========================================================

        addr    = 3'h4;
        wr_data = 8'h03;
        wr_en   = 1'b1;

        #1;

        check_signal(
            mcr_wr_en,
            1'b1,
            "MCR write enable"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 11
        // MCR READ
        //
        // Address = 0x04
        // MCR = 0x03
        //
        // Expected = 0x03
        // ========================================================

        mcr = 8'h03;

        addr  = 3'h4;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h03,
            "MCR read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 12
        // LSR READ
        //
        // Address = 0x05
        // LSR = 0x61
        //
        // Expected = 0x61
        // ========================================================

        lsr = 8'h61;

        addr  = 3'h5;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h61,
            "LSR read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 13
        // MSR READ
        //
        // Address = 0x06
        // MSR = 0x90
        //
        // Expected = 0x90
        // ========================================================

        msr = 8'h90;

        addr  = 3'h6;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h90,
            "MSR read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 14
        // SCR WRITE
        //
        // Address = 0x07
        //
        // Expected:
        // scr_wr_en = 1
        // ========================================================

        addr    = 3'h7;
        wr_data = 8'hA5;
        wr_en   = 1'b1;

        #1;

        check_signal(
            scr_wr_en,
            1'b1,
            "SCR write enable"
        );

        wr_en = 1'b0;


        // ========================================================
        // TEST 15
        // SCR READ
        //
        // Address = 0x07
        // SCR = 0xA5
        //
        // Expected = 0xA5
        // ========================================================

        scr = 8'hA5;

        addr  = 3'h7;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'hA5,
            "SCR read"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 16
        // IER READ
        //
        // Address = 0x01
        // DLAB = 0
        //
        // Interrupts skipped.
        //
        // Expected = 0x00
        // ========================================================

        lcr = 8'h03;

        addr  = 3'h1;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h00,
            "IER read - interrupts skipped"
        );

        rd_en = 1'b0;


        // ========================================================
        // TEST 17
        // IIR READ
        //
        // Address = 0x02
        //
        // Interrupts skipped.
        //
        // Expected = 0x00
        // ========================================================

        addr  = 3'h2;
        rd_en = 1'b1;

        #1;

        check_byte(
            rd_data,
            8'h00,
            "IIR read - interrupts skipped"
        );

        rd_en = 1'b0;


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("     REGISTER INTERFACE TEST SUMMARY");
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
            $display("   ALL REGISTER INTERFACE TESTS PASSED");
            $display("************************************");

        end
        else begin

            $display("************************************");
            $display("   SOME REGISTER INTERFACE TESTS FAILED");
            $display("************************************");

        end


        #100;

        $finish;

    end

endmodule