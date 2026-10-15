`timescale 1ns/1ps

module uart_16550_top_tb;

    // =========================================================
    // CLOCK / RESET
    // =========================================================

    logic clk;
    logic rst_n;

    // =========================================================
    // HOST INTERFACE
    // =========================================================

    logic [2:0] addr;
    logic       wr_en;
    logic       rd_en;
    logic [7:0] wr_data;
    logic [7:0] rd_data;

    // =========================================================
    // UART PINS
    // =========================================================

    logic rxd;
    logic txd;

    // =========================================================
    // MODEM SIGNALS
    // =========================================================

    logic cts;
    logic dsr;
    logic ri;
    logic dcd;

    logic dtr;
    logic rts;
    logic out1;
    logic out2;

    // =========================================================
    // TEST COUNTERS
    // =========================================================

    integer pass_count;
    integer fail_count;

    // =========================================================
    // TEST VARIABLES
    // =========================================================

    logic [7:0] read_data;

    // =========================================================
    // DUT
    // =========================================================

    uart_16550_top dut (

        .clk     (clk),
        .rst_n   (rst_n),

        .addr    (addr),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .wr_data (wr_data),
        .rd_data (rd_data),

        .rxd     (rxd),
        .txd     (txd),

        .cts     (cts),
        .dsr     (dsr),
        .ri      (ri),
        .dcd     (dcd),

        .dtr     (dtr),
        .rts     (rts),
        .out1    (out1),
        .out2    (out2)
    );

    // =========================================================
    // 50 MHz CLOCK
    // PERIOD = 20 ns
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #10 clk = ~clk;

    end

    // =========================================================
    // REGISTER WRITE TASK
    //
    // Host places address/data on the negative edge.
    // Write remains asserted for one complete clock cycle.
    // =========================================================

    task automatic write_reg(
        input logic [2:0] address,
        input logic [7:0] data
    );

        begin

            @(negedge clk);

            addr    = address;
            wr_data = data;
            wr_en   = 1'b1;

            @(negedge clk);

            wr_en   = 1'b0;
            addr    = 3'h0;
            wr_data = 8'h00;

        end

    endtask

    // =========================================================
    // REGISTER READ TASK
    //
    // IMPORTANT:
    // rd_en and address are asserted before the active clock
    // edge.
    //
    // Data is sampled AFTER the active clock edge while rd_en
    // is still asserted.
    //
    // This represents the synchronous host read transaction.
    // =========================================================

    task automatic read_reg(
        input  logic [2:0] address,
        output logic [7:0] data
    );

        begin

            // -------------------------------------------------
            // Present address and read enable
            // -------------------------------------------------

            @(negedge clk);

            addr  = address;
            rd_en = 1'b1;

            // -------------------------------------------------
            // Allow DUT to process read transaction
            // -------------------------------------------------

            @(posedge clk);

            // Allow NBA / combinational logic to settle
            #1;

            // -------------------------------------------------
            // Sample read data
            // -------------------------------------------------

            data = rd_data;

            // -------------------------------------------------
            // End read transaction
            // -------------------------------------------------

            @(negedge clk);

            rd_en = 1'b0;
            addr  = 3'h0;

        end

    endtask

    // =========================================================
    // CHECK TASK
    // =========================================================

    task automatic check_value(
        input logic [7:0] actual,
        input logic [7:0] expected,
        input string name
    );

        begin

            if (actual === expected) begin

                $display(
                    "PASS: %s | Expected = 0x%02h | Actual = 0x%02h",
                    name,
                    expected,
                    actual
                );

                pass_count++;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = 0x%02h | Actual = 0x%02h",
                    name,
                    expected,
                    actual
                );

                fail_count++;

            end

        end

    endtask

    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // INITIAL VALUES
        // -----------------------------------------------------

        pass_count = 0;
        fail_count = 0;

        addr    = 3'h0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = 8'h00;

        // UART idle state
        rxd = 1'b1;

        // Modem inputs
        cts = 1'b1;
        dsr = 1'b1;
        ri  = 1'b1;
        dcd = 1'b1;

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        rst_n = 1'b0;

        repeat (5)
            @(posedge clk);

        #1;

        rst_n = 1'b1;

        repeat (5)
            @(posedge clk);

        // -----------------------------------------------------
        // HEADER
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display(" UART 16550 TOP LEVEL TEST");
        $display("========================================");
        $display("");

        // =====================================================
        // TEST 1
        // LCR RESET
        // =====================================================

        $display("----------------------------------------");
        $display("TEST 1: LCR RESET");
        $display("----------------------------------------");

        read_reg(
            3'h3,
            read_data
        );

        check_value(
            read_data,
            8'h00,
            "LCR reset"
        );

        // =====================================================
        // TEST 2
        // DLL / DLM
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 2: DLL / DLM");
        $display("----------------------------------------");

        // -----------------------------------------------------
        // Set DLAB = 1
        // -----------------------------------------------------

        write_reg(
            3'h3,
            8'h80
        );

        // -----------------------------------------------------
        // DLL = 27
        // -----------------------------------------------------

        write_reg(
            3'h0,
            8'h1B
        );

        // -----------------------------------------------------
        // DLM = 0
        // -----------------------------------------------------

        write_reg(
            3'h1,
            8'h00
        );

        // -----------------------------------------------------
        // Read DLL
        // -----------------------------------------------------

        read_reg(
            3'h0,
            read_data
        );

        check_value(
            read_data,
            8'h1B,
            "DLL read/write"
        );

        // -----------------------------------------------------
        // Read DLM
        // -----------------------------------------------------

        read_reg(
            3'h1,
            read_data
        );

        check_value(
            read_data,
            8'h00,
            "DLM read/write"
        );

        // =====================================================
        // TEST 3
        // PSD
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 3: PSD");
        $display("----------------------------------------");

        // PSD accessible at address 5 when DLAB = 1

        write_reg(
            3'h5,
            8'h00
        );

        $display(
            "INFO: PSD configured to 0"
        );

        // =====================================================
        // TEST 4
        // LCR = 8-N-1
        // DLAB = 0
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 4: LCR = 8-N-1");
        $display("----------------------------------------");

        write_reg(
            3'h3,
            8'h03
        );

        read_reg(
            3'h3,
            read_data
        );

        check_value(
            read_data,
            8'h03,
            "LCR = 8-N-1"
        );

        // =====================================================
        // TEST 5
        // ENABLE FIFO
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 5: ENABLE FIFO");
        $display("----------------------------------------");

        write_reg(
            3'h2,
            8'h01
        );

        $display(
            "INFO: TX/RX FIFO enabled"
        );

        // =====================================================
        // TEST 6
        // INTERNAL LOOPBACK
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 6: INTERNAL LOOPBACK");
        $display("----------------------------------------");

        // MCR[4] = 1

        write_reg(
            3'h4,
            8'h10
        );

        $display(
            "INFO: Internal loopback enabled"
        );

        // =====================================================
        // TEST 7
        // TRANSMIT 0x55
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 7: LOOPBACK 0x55");
        $display("----------------------------------------");

        $display(
            "INFO: Writing 0x55 to THR..."
        );

        write_reg(
            3'h0,
            8'h55
        );

        // -----------------------------------------------------
        // UART FRAME TIMING
        //
        // Clock = 50 MHz
        // Divisor = 27
        //
        // Baud:
        //
        // 50 MHz / (16 * 27)
        // ? 115740 baud
        //
        // 10-bit frame:
        //
        // ? 86.4 us
        //
        // Wait generously for complete TX/RX operation.
        // -----------------------------------------------------

        #150_000;

        // =====================================================
        // READ LSR
        // =====================================================

        $display("");
        $display(
            "INFO: Reading LSR after loopback..."
        );

        read_reg(
            3'h5,
            read_data
        );

        $display(
            "INFO: LSR after loopback = 0x%02h",
            read_data
        );

        // =====================================================
        // CHECK DATA READY
        // =====================================================

        if (read_data[0] == 1'b1) begin

            $display(
                "PASS: RX Data Ready asserted"
            );

            pass_count++;

        end
        else begin

            $display(
                "FAIL: RX Data Ready not asserted"
            );

            fail_count++;

        end

        // =====================================================
        // TEST 8
        // READ RBR
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 8: READ RBR");
        $display("----------------------------------------");

        read_reg(
            3'h0,
            read_data
        );

        check_value(
            read_data,
            8'h55,
            "Loopback received 0x55"
        );

        // =====================================================
        // TEST 9
        // CHECK LSR AFTER RBR READ
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 9: LSR AFTER RBR READ");
        $display("----------------------------------------");

        read_reg(
            3'h5,
            read_data
        );

        if (read_data[0] == 1'b0) begin

            $display(
                "PASS: RX Data Ready cleared after RBR read"
            );

            pass_count++;

        end
        else begin

            $display(
                "FAIL: RX Data Ready still asserted"
            );

            fail_count++;

        end

        // =====================================================
        // TEST 10
        // SECOND LOOPBACK BYTE
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 10: LOOPBACK 0xA5");
        $display("----------------------------------------");

        $display(
            "INFO: Writing 0xA5 to THR..."
        );

        write_reg(
            3'h0,
            8'hA5
        );

        // Wait for complete UART frame

        #150_000;

        // -----------------------------------------------------
        // Read RBR
        // -----------------------------------------------------

        read_reg(
            3'h0,
            read_data
        );

        check_value(
            read_data,
            8'hA5,
            "Loopback received 0xA5"
        );

        // =====================================================
        // TEST 11
        // SCRATCHPAD
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 11: SCRATCHPAD");
        $display("----------------------------------------");

        write_reg(
            3'h7,
            8'h5A
        );

        read_reg(
            3'h7,
            read_data
        );

        check_value(
            read_data,
            8'h5A,
            "Scratchpad"
        );

        // =====================================================
        // TEST 12
        // MCR
        // =====================================================

        $display("");
        $display("----------------------------------------");
        $display("TEST 12: MCR");
        $display("----------------------------------------");

        write_reg(
            3'h4,
            8'h1F
        );

        read_reg(
            3'h4,
            read_data
        );

        check_value(
            read_data,
            8'h1F,
            "MCR"
        );

        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");
        $display(" FINAL RESULT");
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

        if (fail_count == 0) begin

            $display("");
            $display(
                "****************************************"
            );

            $display(
                " UART 16550 TOP LEVEL TEST PASSED"
            );

            $display(
                "****************************************"
            );

        end
        else begin

            $display("");
            $display(
                "****************************************"
            );

            $display(
                " UART 16550 TOP LEVEL TEST FAILED"
            );

            $display(
                "****************************************"
            );

        end

        // -----------------------------------------------------
        // END SIMULATION
        // -----------------------------------------------------

        $finish;

    end

endmodule