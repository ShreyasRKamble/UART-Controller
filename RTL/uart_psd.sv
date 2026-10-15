`timescale 1ns/1ps

module uart_psd (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       wr_en,
    input  logic [7:0] wr_data,

    output logic [3:0] psd,
    output logic [7:0] psd_reg
);

    // -------------------------------------------------
    // Programmable Prescaler Division Register
    // -------------------------------------------------
    //
    // PSD[3:0] stores the programmable prescaler value.
    //
    // Division factor = PSD + 1
    //
    // Therefore:
    // PSD = 0  -> divide by 1
    // PSD = 1  -> divide by 2
    // ...
    // PSD = 15 -> divide by 16
    //
    // Bits [7:4] are always zero.
    // -------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            psd <= 4'h0;
        end

        else if (wr_en) begin
            psd <= wr_data[3:0];
        end

    end

    // Register-style output.
    // Upper four bits are always zero.
    always_comb begin
        psd_reg = {4'h0, psd};
    end

endmodule