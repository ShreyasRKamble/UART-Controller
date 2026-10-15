`timescale 1ns/1ps

module uart_rx_timeout (
    input  logic clk,
    input  logic rst_n,

    // Indicates that at least one character is
    // currently stored in the RX FIFO.
    input  logic fifo_not_empty,

    // One pulse representing one complete
    // UART character time.
    input  logic char_tick,

    // New character has entered the RX FIFO.
    input  logic rx_activity,

    // CPU has read the RHR / RX FIFO.
    input  logic rhr_read,

    // Reception timeout condition.
    output logic timeout
);

    // -------------------------------------------------
    // Timeout counter
    //
    // 0 -> no character time elapsed
    // 1 -> 1 character time
    // 2 -> 2 character times
    // 3 -> 3 character times
    // 4 -> timeout
    // -------------------------------------------------

    logic [2:0] char_count;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            char_count <= 3'd0;
            timeout    <= 1'b0;
        end

        else begin

            // -----------------------------------------
            // No data in FIFO
            // -----------------------------------------

            if (!fifo_not_empty) begin
                char_count <= 3'd0;
                timeout    <= 1'b0;
            end

            // -----------------------------------------
            // New character received
            // -----------------------------------------

            else if (rx_activity) begin
                char_count <= 3'd0;
                timeout    <= 1'b0;
            end

            // -----------------------------------------
            // CPU read from RHR
            // -----------------------------------------

            else if (rhr_read) begin
                char_count <= 3'd0;
                timeout    <= 1'b0;
            end

            // -----------------------------------------
            // Count character times
            // -----------------------------------------

            else if (char_tick && !timeout) begin

                if (char_count == 3'd3) begin
                    char_count <= 3'd4;
                    timeout    <= 1'b1;
                end

                else begin
                    char_count <= char_count + 3'd1;
                end

            end

        end

    end

endmodule