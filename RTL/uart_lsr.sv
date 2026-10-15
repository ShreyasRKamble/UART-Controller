`timescale 1ns/1ps

module uart_lsr (

    input  logic       clk,
    input  logic       rst_n,

    // RX status
    input  logic       rx_data_ready,
    input  logic       rx_overrun,
    input  logic       rx_parity_error,
    input  logic       rx_framing_error,
    input  logic       rx_break,

    // TX status
    input  logic       tx_fifo_empty,
    input  logic       tx_busy,

    // LSR read
    input  logic       rd_en,

    // LSR output
    output logic [7:0] lsr

);

    // ============================================================
    // STORED ERROR FLAGS
    // ============================================================

    logic overrun_flag;
    logic parity_flag;
    logic framing_flag;
    logic break_flag;


    // ============================================================
    // ERROR FLAG STORAGE
    //
    // Errors are latched until LSR is read.
    // ============================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            overrun_flag  <= 1'b0;
            parity_flag   <= 1'b0;
            framing_flag  <= 1'b0;
            break_flag    <= 1'b0;

        end
        else begin

            if (rx_overrun)
                overrun_flag <= 1'b1;

            if (rx_parity_error)
                parity_flag <= 1'b1;

            if (rx_framing_error)
                framing_flag <= 1'b1;

            if (rx_break)
                break_flag <= 1'b1;

            // Reading LSR clears stored error flags
            if (rd_en) begin

                overrun_flag  <= 1'b0;
                parity_flag   <= 1'b0;
                framing_flag <= 1'b0;
                break_flag    <= 1'b0;

            end

        end

    end


    // ============================================================
    // LSR BIT GENERATION
    // ============================================================

    always_comb begin

        lsr = 8'h00;

        // Bit 0: Data Ready
        lsr[0] = rx_data_ready;

        // Bit 1: Overrun Error
        lsr[1] = overrun_flag;

        // Bit 2: Parity Error
        lsr[2] = parity_flag;

        // Bit 3: Framing Error
        lsr[3] = framing_flag;

        // Bit 4: Break Interrupt
        lsr[4] = break_flag;

        // Bit 5: THR Empty
        lsr[5] = tx_fifo_empty;

        // Bit 6: THR + Transmitter Empty
        lsr[6] = tx_fifo_empty && !tx_busy;

        // Bit 7: Error in RX FIFO
        lsr[7] = overrun_flag |
                 parity_flag  |
                 framing_flag;

    end

endmodule