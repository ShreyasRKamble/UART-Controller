module uart_baud_gen_prog #(
    parameter int CLOCK_FREQ = 50_000_000
)(
    input  logic        clk,
    input  logic        rst_n,

    // 16-bit 16550 divisor
    input  logic [15:0] divisor,

    // Baud/sample tick
    output logic        baud_tick
);

    logic [31:0] counter;

    // =====================================================
    // 16550 baud rate:
    //
    // Baud = CLOCK / (16 * divisor)
    //
    // Therefore:
    //
    // Tick period = 16 * divisor clock cycles
    // =====================================================

    logic [31:0] terminal_count;

    always_comb begin

        if (divisor == 16'd0)
            terminal_count = 32'd1;

        else
            terminal_count = 32'(16 * divisor);

    end

    // =====================================================
    // Counter
    // =====================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            counter   <= 32'd0;
            baud_tick <= 1'b0;

        end

        else begin

            if (counter == terminal_count - 1) begin

                counter   <= 32'd0;
                baud_tick <= 1'b1;

            end

            else begin

                counter   <= counter + 1'b1;
                baud_tick <= 1'b0;

            end

        end

    end

endmodule