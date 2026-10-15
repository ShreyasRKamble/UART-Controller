`timescale 1ns/1ps

module uart_mcr (

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    input logic       clk,
    input logic       rst_n,

    // ============================================================
    // WRITE INTERFACE
    // ============================================================

    input logic       wr_en,
    input logic [7:0] wr_data,

    // ============================================================
    // READ OUTPUT
    // ============================================================

    output logic [7:0] mcr,

    // ============================================================
    // MODEM CONTROL OUTPUTS
    // ============================================================

    output logic dtr,
    output logic rts,
    output logic out1,
    output logic out2,

    // ============================================================
    // LOOPBACK
    // ============================================================

    output logic loopback

);


    // ============================================================
    // MCR REGISTER
    //
    // Reset value = 0x00
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            mcr <= 8'h00;

        end
        else if (wr_en) begin

            // Only defined MCR bits are stored.
            //
            // Bits [7:5] are reserved and forced to zero.

            mcr <= {3'b000, wr_data[4:0]};

        end

    end


    // ============================================================
    // MCR BIT DECODE
    // ============================================================

    assign dtr      = mcr[0];
    assign rts      = mcr[1];
    assign out1     = mcr[2];
    assign out2     = mcr[3];
    assign loopback = mcr[4];


endmodule