`timescale 1ns/1ps

module uart_rx_tb;

    logic       clk;
    logic       rst_n;

    logic       baud_tick;
    logic       rxd;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;
    logic       framing_error;

    // =====================================================
    // DUT
    // =====================================================

    uart_rx dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .baud_tick     (baud_tick),
        .rxd           (rxd),
        .rx_data       (rx_data),
        .rx_valid      (rx_valid),
        .rx_busy       (rx_busy),
        .framing_error (framing_error)
    );

    // =====================================================
    // 50 MHz clock
    // =====================================================

    initial begin
        clk = 1'b0;

        forever begin
            #10 clk = ~clk;
        end
    end

    // =====================================================
    // Baud tick
    // One tick every 434 clocks
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
    // UART bit task
    // =====================================================

    task send_bit(input logic bit_value);

        begin

            rxd = bit_value;

            // Wait exactly one baud period
            repeat (434) @(posedge clk);

        end

    endtask

    // =====================================================
    // Send UART byte
    // 8-N-1
    // =====================================================

    task send_byte(input logic [7:0] data);

        integer i;

        begin

            // Start bit
            send_bit(1'b0);

            // Data bits - LSB first
            for (i = 0; i < 8; i = i + 1) begin
                send_bit(data[i]);
            end

            // Stop bit
            send_bit(1'b1);

        end

    endtask

    // =====================================================
    // Test
    // =====================================================

    initial begin

        rst_n = 1'b0;
        rxd   = 1'b1;

        // Reset
        #100;

        rst_n = 1'b1;

        #100;

        $display("----------------------------------------");
        $display("UART RX TEST");
        $display("----------------------------------------");

        // Send ASCII 'A'
        send_byte(8'h41);

        // Give RX time to generate rx_valid
        #100;

        if (rx_valid || rx_data == 8'h41) begin

            $display("RX Data = 0x%02h", rx_data);
            $display("RX TEST PASSED");

        end

        else begin

            $display("RX Data = 0x%02h", rx_data);
            $display("RX TEST FAILED");

        end

        $display("----------------------------------------");

        #1000;

        $stop;

    end

endmodule