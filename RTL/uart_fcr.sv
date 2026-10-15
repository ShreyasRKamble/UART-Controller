module uart_fcr (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       wr_en,
    input  logic [7:0] wr_data,

    output logic [7:0] fcr,

    output logic       fifo_enable,
    output logic       rx_fifo_reset,
    output logic       tx_fifo_reset,

    output logic [1:0] rx_trigger_level
);

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            fcr <= 8'h00;

        end
        else if (wr_en) begin

            fcr <= wr_data;

        end

    end


    // ============================================================
    // FCR fields
    // ============================================================

    assign fifo_enable     = fcr[0];

    assign rx_fifo_reset   = fcr[1];

    assign tx_fifo_reset   = fcr[2];

    assign rx_trigger_level = fcr[7:6];

endmodule