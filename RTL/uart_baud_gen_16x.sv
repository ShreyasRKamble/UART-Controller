module uart_baud_gen_16x #(
    parameter int CLOCK_FREQ = 50_000_000,
    parameter int BAUD_RATE  = 115_200
)(
    input  logic clk,
    input  logic rst_n,

    output logic sample_tick
);

    // 16x oversampling frequency
    localparam int SAMPLE_RATE = BAUD_RATE * 16;

    // Number of system-clock cycles per 16x sample
    localparam int DIVISOR = CLOCK_FREQ / SAMPLE_RATE;

    // Counter width
    localparam int COUNTER_WIDTH = $clog2(DIVISOR);

    logic [COUNTER_WIDTH-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            counter    <= '0;
            sample_tick <= 1'b0;

        end

        else begin

            if (counter == DIVISOR - 1) begin

                counter     <= '0;
                sample_tick <= 1'b1;

            end

            else begin

                counter     <= counter + 1'b1;
                sample_tick <= 1'b0;

            end

        end

    end

endmodule