module uart_baud_gen #(
    parameter int CLOCK_FREQ = 50_000_000,
    parameter int BAUD_RATE  = 115_200
)(
    input  logic clk,
    input  logic rst_n,

    output logic baud_tick
);

    // Number of system-clock cycles per UART bit
    localparam int BAUD_DIV = CLOCK_FREQ / BAUD_RATE;

    // Counter width
    localparam int COUNTER_WIDTH = $clog2(BAUD_DIV);

    logic [COUNTER_WIDTH-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            counter   <= '0;
            baud_tick <= 1'b0;
        end

        else begin

            if (counter == BAUD_DIV - 1) begin
                counter   <= '0;
                baud_tick <= 1'b1;
            end

            else begin
                counter   <= counter + 1'b1;
                baud_tick <= 1'b0;
            end

        end

    end

endmodule