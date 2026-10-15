`timescale 1ns/1ps

module uart_tx_tb;

    logic       clk;
    logic       rst_n;

    logic       baud_tick;

    logic       tx_start;
    logic [7:0] tx_data;

    logic       txd;
    logic       tx_busy;
    logic       tx_done;

    // =====================================================
    // DUT
    // =====================================================

    uart_tx dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .txd       (txd),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    // =====================================================
    // 50 MHz clock
    // Period = 20 ns
    // =====================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end

    // =====================================================
    // Generate baud tick
    //
    // One tick every 434 clock cycles
    // =====================================================

    initial begin
        baud_tick = 1'b0;

        forever begin
            repeat (433) @(posedge clk);
            @(posedge clk);
            baud_tick = 1'b1;

            @(posedge clk);
            baud_tick = 1'b0;
        end
    end

    // =====================================================
    // Test sequence
    // =====================================================

    initial begin

        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        // Reset
        #100;

        rst_n = 1'b1;

        // Wait a little
        #100;

        // Send ASCII 'A'
        // 8'h41 = 0100_0001
        tx_data  = 8'h41;
	tx_start = 1'b1;

	#100;
	tx_start = 1'b0;

        @(posedge clk);
        tx_start = 1'b0;

        // Wait for transmission to finish
        wait(tx_done);

        $display("----------------------------------------");
        $display("UART TX TEST");
        $display("----------------------------------------");
        $display("Transmitted Data = 0x%02h", tx_data);
        $display("TX transmission completed");
        $display("----------------------------------------");

        #1000;

        $stop;

    end

endmodule