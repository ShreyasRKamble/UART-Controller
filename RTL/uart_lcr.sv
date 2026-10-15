module uart_lcr (
    input  logic       clk,
    input  logic       rst_n,

    // Register interface
    input  logic       wr_en,
    input  logic [7:0] wr_data,

    output logic [7:0] lcr
);

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            lcr <= 8'h00;
        end

        else if (wr_en) begin
            lcr <= wr_data;
        end

    end

endmodule