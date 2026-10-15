`timescale 1ns/1ps

module uart_scr (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       wr_en,
    input  logic [7:0] wr_data,

    output logic [7:0] scr
);

    // -------------------------------------------------
    // Scratch Pad Register
    // -------------------------------------------------
    // 8-bit read/write storage register.
    // It is completely independent of UART operation.
    // -------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            scr <= 8'h00;
        end

        else if (wr_en) begin
            scr <= wr_data;
        end

    end

endmodule