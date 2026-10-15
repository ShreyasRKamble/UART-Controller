`timescale 1ns/1ps

module uart_lsr_tb;

    // ============================================================
    // SIGNAL DECLARATIONS
    // ============================================================

    logic clk;
    logic rst_n;

    // RX status signals
    logic rx_data_ready;
    logic rx_overrun;
    logic rx_parity_error;
    logic rx_framing_error;
    logic rx_break;

    // TX status signals
    logic tx_fifo_empty;
    logic tx_busy;

    // LSR read enable
    logic rd_en;

    // LSR output
    logic [7:0] lsr;

    // Test counters
    integer pass_count;
    integer fail_count;


    // ============================================================
    // DUT - UART LSR
    // ============================================================

    uart_lsr dut (
        .clk                (clk),
        .rst_n              (rst_n),

        .rx_data_ready      (rx_data_ready),
        .rx_overrun         (rx_overrun),
        .rx_parity_error    (rx_parity_error),
        .rx_framing_error   (rx_framing_error),
        .rx_break           (rx_break),

        .tx_fifo_empty      (tx_fifo_empty),
        .tx_busy            (tx_busy),

        .rd_en              (rd_en),

        .lsr                (lsr)
    );


    // ============================================================
    // CLOCK GENERATION
    // 50 MHz clock
    // Period = 20 ns
    // ============================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end


    // ============================================================
    // CHECK LSR TASK
    // ============================================================

    task check_lsr(
        input logic [7:0] expected,
        input string test_name
    );

        begin

            #1;

            if (lsr == expected) begin

                $display(
                    "PASS: %s | LSR = 0x%02h",
                    test_name,
                    lsr
                );

                pass_count = pass_count + 1;

            end
            else begin

                $display(
                    "FAIL: %s | Expected = 0x%02h | Got = 0x%02h",
                    test_name,
                    expected,
                    lsr
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // CLEAR ERROR FLAGS
    //
    // Reading the LSR clears the latched:
    //   Overrun
    //   Parity
    //   Framing
    //   Break
    // flags.
    // ============================================================

    task clear_lsr_errors;

        begin

            rd_en = 1'b1;

            @(posedge clk);

            #1;

            rd_en = 1'b0;

        end

    endtask


    // ============================================================
    // MAIN TEST SEQUENCE
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIALIZE SIGNALS
        // --------------------------------------------------------

        rst_n = 1'b0;

        rx_data_ready    = 1'b0;
        rx_overrun       = 1'b0;
        rx_parity_error  = 1'b0;
        rx_framing_error = 1'b0;
        rx_break         = 1'b0;

        tx_fifo_empty = 1'b1;
        tx_busy       = 1'b0;

        rd_en = 1'b0;

        pass_count = 0;
        fail_count = 0;


        // ========================================================
        // RESET
        // ========================================================

        #50;

        rst_n = 1'b1;

        #20;


        // ========================================================
        // TEST 1
        // TX IDLE
        //
        // tx_fifo_empty = 1
        // tx_busy       = 0
        //
        // LSR:
        // [6] TEMT = 1
        // [5] THRE = 1
        //
        // Expected = 0x60
        // ========================================================

        check_lsr(
            8'h60,
            "TX idle"
        );


        // ========================================================
        // TEST 2
        // DATA READY
        //
        // rx_data_ready = 1
        //
        // LSR:
        // [0] Data Ready = 1
        // [5] THRE      = 1
        // [6] TEMT      = 1
        //
        // Expected = 0x61
        // ========================================================

        rx_data_ready = 1'b1;

        check_lsr(
            8'h61,
            "Data Ready"
        );


        // ========================================================
        // TEST 3
        // TRANSMITTER BUSY
        //
        // tx_busy = 1
        //
        // LSR:
        // [0] Data Ready = 1
        // [5] THRE       = 1
        // [6] TEMT       = 0
        //
        // Expected = 0x21
        // ========================================================

        tx_busy = 1'b1;

        check_lsr(
            8'h21,
            "TX Busy"
        );

        // Return transmitter to idle
        tx_busy = 1'b0;


        // ========================================================
        // TEST 4
        // PARITY ERROR
        //
        // rx_parity_error = 1
        //
        // LSR:
        // [7] RX FIFO Error = 1
        // [6] TEMT          = 1
        // [5] THRE          = 1
        // [2] Parity Error  = 1
        // [0] Data Ready    = 1
        //
        // Binary:
        //
        // 1 1 1 0 0 1 0 1
        //
        // Hex = E5
        // ========================================================

        rx_parity_error = 1'b1;

        @(posedge clk);

        #1;

        rx_parity_error = 1'b0;

        check_lsr(
            8'hE5,
            "Parity Error"
        );

        // Clear parity error
        clear_lsr_errors;


        // ========================================================
        // TEST 5
        // FRAMING ERROR
        //
        // rx_framing_error = 1
        //
        // LSR:
        // [7] RX FIFO Error = 1
        // [6] TEMT          = 1
        // [5] THRE          = 1
        // [3] Framing Error = 1
        // [0] Data Ready    = 1
        //
        // Expected = E9
        // ========================================================

        rx_framing_error = 1'b1;

        @(posedge clk);

        #1;

        rx_framing_error = 1'b0;

        check_lsr(
            8'hE9,
            "Framing Error"
        );

        // Clear framing error
        clear_lsr_errors;


        // ========================================================
        // TEST 6
        // OVERRUN ERROR
        //
        // rx_overrun = 1
        //
        // LSR:
        // [7] RX FIFO Error = 1
        // [6] TEMT          = 1
        // [5] THRE          = 1
        // [1] Overrun       = 1
        // [0] Data Ready    = 1
        //
        // Expected = E3
        // ========================================================

        rx_overrun = 1'b1;

        @(posedge clk);

        #1;

        rx_overrun = 1'b0;

        check_lsr(
            8'hE3,
            "Overrun Error"
        );

        // Clear overrun error
        clear_lsr_errors;


        // ========================================================
        // TEST 7
        // BREAK DETECT
        //
        // rx_break = 1
        //
        // LSR:
        // [6] TEMT       = 1
        // [5] THRE       = 1
        // [4] Break      = 1
        // [0] Data Ready = 1
        //
        // Expected = 71
        // ========================================================

        rx_break = 1'b1;

        @(posedge clk);

        #1;

        rx_break = 1'b0;

        check_lsr(
            8'h71,
            "Break"
        );

        // Clear break flag
        clear_lsr_errors;


        // ========================================================
        // TEST 8
        // ERROR FLAGS CLEARED
        //
        // After reading LSR, all latched error flags should be 0.
        //
        // Data Ready = 1
        // THRE       = 1
        // TEMT       = 1
        //
        // Expected = 61
        // ========================================================

        check_lsr(
            8'h61,
            "LSR Error Clear"
        );


        // ========================================================
        // TEST 9
        // TX FIFO NOT EMPTY
        //
        // tx_fifo_empty = 0
        //
        // LSR:
        // [0] Data Ready = 1
        // [5] THRE       = 0
        // [6] TEMT       = 0
        //
        // Expected = 01
        // ========================================================

        tx_fifo_empty = 1'b0;

        check_lsr(
            8'h01,
            "TX FIFO Not Empty"
        );


        // ========================================================
        // FINAL TEST SUMMARY
        // ========================================================

        $display("");
        $display("========================================");
        $display("          LSR TEST SUMMARY");
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


        // ========================================================
        // FINAL RESULT
        // ========================================================

        if (fail_count == 0) begin

            $display("************************************");
            $display("       ALL LSR TESTS PASSED");
            $display("************************************");

        end
        else begin

            $display("************************************");
            $display("       SOME LSR TESTS FAILED");
            $display("************************************");

        end


        // Allow waveform to settle
        #100;

        $finish;

    end

endmodule