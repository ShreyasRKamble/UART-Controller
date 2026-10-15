`timescale 1ns/1ps

module uart_msr (

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    input logic clk,
    input logic rst_n,

    // ============================================================
    // MODEM STATUS INPUTS
    // ============================================================

    input logic cts,
    input logic dsr,
    input logic ri,
    input logic dcd,

    // ============================================================
    // MSR READ ENABLE
    // ============================================================

    input logic rd_en,

    // ============================================================
    // MSR OUTPUT
    // ============================================================

    output logic [7:0] msr

);


    // ============================================================
    // PREVIOUS MODEM INPUT STATES
    // ============================================================

    logic cts_prev;
    logic dsr_prev;
    logic ri_prev;
    logic dcd_prev;


    // ============================================================
    // DELTA FLAGS
    // ============================================================

    logic dcts_flag;
    logic ddsr_flag;
    logic teri_flag;
    logic ddcd_flag;


    // ============================================================
    // MODEM STATUS / DELTA FLAG LOGIC
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            cts_prev <= 1'b0;
            dsr_prev <= 1'b0;
            ri_prev  <= 1'b0;
            dcd_prev <= 1'b0;

            dcts_flag <= 1'b0;
            ddsr_flag <= 1'b0;
            teri_flag <= 1'b0;
            ddcd_flag <= 1'b0;

        end
        else begin

            // ----------------------------------------------------
            // CTS transition
            // ----------------------------------------------------

            if (cts != cts_prev)
                dcts_flag <= 1'b1;


            // ----------------------------------------------------
            // DSR transition
            // ----------------------------------------------------

            if (dsr != dsr_prev)
                ddsr_flag <= 1'b1;


            // ----------------------------------------------------
            // RI falling edge
            // ----------------------------------------------------

            if (ri_prev && !ri)
                teri_flag <= 1'b1;


            // ----------------------------------------------------
            // DCD transition
            // ----------------------------------------------------

            if (dcd != dcd_prev)
                ddcd_flag <= 1'b1;


            // ----------------------------------------------------
            // Store current inputs for next comparison
            // ----------------------------------------------------

            cts_prev <= cts;
            dsr_prev <= dsr;
            ri_prev  <= ri;
            dcd_prev <= dcd;


            // ----------------------------------------------------
            // Reading MSR clears delta flags
            // ----------------------------------------------------

            if (rd_en) begin

                dcts_flag <= 1'b0;
                ddsr_flag <= 1'b0;
                teri_flag <= 1'b0;
                ddcd_flag <= 1'b0;

            end

        end

    end


    // ============================================================
    // MSR OUTPUT
    //
    // [7] DCD
    // [6] RI
    // [5] DSR
    // [4] CTS
    //
    // [3] DDCD
    // [2] TERI
    // [1] DDSR
    // [0] DCTS
    // ============================================================

    always_comb begin

        msr = 8'h00;

        // Current modem status
        msr[7] = dcd;
        msr[6] = ri;
        msr[5] = dsr;
        msr[4] = cts;

        // Delta flags
        msr[3] = ddcd_flag;
        msr[2] = teri_flag;
        msr[1] = ddsr_flag;
        msr[0] = dcts_flag;

    end

endmodule