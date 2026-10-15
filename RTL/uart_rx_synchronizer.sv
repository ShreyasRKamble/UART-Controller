`timescale 1ns/1ps

module uart_rx_synchronizer (
    input  logic clk,
    input  logic rst_n,

    // Asynchronous UART RX input
    input  logic rxd,

    // Synchronized RX output
    output logic rxd_sync
);

    // First and second synchronizer stages
    logic rxd_ff1;
    logic rxd_ff2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rxd_ff1 <= 1'b1;
            rxd_ff2 <= 1'b1;
        end
        else begin
            rxd_ff1 <= rxd;
            rxd_ff2 <= rxd_ff1;
        end
    end

    assign rxd_sync = rxd_ff2;

endmodule