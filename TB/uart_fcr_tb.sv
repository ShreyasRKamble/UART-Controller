`timescale 1ns/1ps

module uart_fcr_tb;

    logic clk;
    logic rst_n;

    logic       wr_en;
    logic [7:0] wr_data;

    logic [7:0] fcr;

    logic       fifo_enable;
    logic       rx_fifo_reset;
    logic       tx_fifo_reset;

    logic [1:0] rx_trigger_level;


    // ============================================================
    // DUT
    // ============================================================

    uart_fcr dut (
        .clk             (clk),
        .rst_n           (rst_n),

        .wr_en           (wr_en),
        .wr_data         (wr_data),

        .fcr             (fcr),

        .fifo_enable     (fifo_enable),
        .rx_fifo_reset   (rx_fifo_reset),
        .tx_fifo_reset   (tx_fifo_reset),

        .rx_trigger_level(rx_trigger_level)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever
            #10 clk = ~clk;

    end


    // ============================================================
    // WRITE FCR
    // ============================================================

    task write_fcr(input logic [7:0] data);

        begin

            @(negedge clk);

            wr_en   = 1'b1;
            wr_data = data;

            @(posedge clk);

            #1;

            wr_en = 1'b0;

        end

    endtask


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;


        // Reset
        #50;

        rst_n = 1'b1;

        #20;


        // --------------------------------------------------------
        // TEST 1
        // FIFO disabled
        // --------------------------------------------------------

        write_fcr(8'h00);

        if (fcr == 8'h00)
            $display("TEST 1 PASS: FIFO disabled");
        else
            $display("TEST 1 FAIL");


        // --------------------------------------------------------
        // TEST 2
        // FIFO enable
        // --------------------------------------------------------

        write_fcr(8'h01);

        if (fifo_enable == 1'b1)
            $display("TEST 2 PASS: FIFO enabled");
        else
            $display("TEST 2 FAIL");


        // --------------------------------------------------------
        // TEST 3
        // RX FIFO reset
        // --------------------------------------------------------

        write_fcr(8'h03);

        if (rx_fifo_reset == 1'b1)
            $display("TEST 3 PASS: RX FIFO reset");
        else
            $display("TEST 3 FAIL");


        // --------------------------------------------------------
        // TEST 4
        // TX FIFO reset
        // --------------------------------------------------------

        write_fcr(8'h05);

        if (tx_fifo_reset == 1'b1)
            $display("TEST 4 PASS: TX FIFO reset");
        else
            $display("TEST 4 FAIL");


        // --------------------------------------------------------
        // TEST 5
        // RX trigger = 1 byte
        // --------------------------------------------------------

        write_fcr(8'h01);

        if (rx_trigger_level == 2'b00)
            $display("TEST 5 PASS: RX trigger = 1");
        else
            $display("TEST 5 FAIL");


        // --------------------------------------------------------
        // TEST 6
        // RX trigger = 4 bytes
        // --------------------------------------------------------

        write_fcr(8'h41);

        if (rx_trigger_level == 2'b01)
            $display("TEST 6 PASS: RX trigger = 4");
        else
            $display("TEST 6 FAIL");


        // --------------------------------------------------------
        // TEST 7
        // RX trigger = 8 bytes
        // --------------------------------------------------------

        write_fcr(8'h81);

        if (rx_trigger_level == 2'b10)
            $display("TEST 7 PASS: RX trigger = 8");
        else
            $display("TEST 7 FAIL");


        // --------------------------------------------------------
        // TEST 8
        // RX trigger = 14 bytes
        // --------------------------------------------------------

        write_fcr(8'hC1);

        if (rx_trigger_level == 2'b11)
            $display("TEST 8 PASS: RX trigger = 14");
        else
            $display("TEST 8 FAIL");


        // --------------------------------------------------------
        // DONE
        // --------------------------------------------------------

        $display("");
        $display("========================================");
        $display("       FCR TEST COMPLETE");
        $display("========================================");

        #100;

        $finish;

    end

endmodule