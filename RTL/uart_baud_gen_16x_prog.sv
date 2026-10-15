module uart_baud_gen_16x_prog (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [15:0] divisor,

    output logic        sample_tick
);

    logic [31:0] counter;
    logic [31:0] terminal_count;

    // =====================================================
    // 16550 16x RX sampling
    //
    // Baud     = CLOCK / (16 × divisor)
    // 16x baud = CLOCK / divisor
    //
    // Therefore sample_tick period = divisor clocks
    // =====================================================

    always_comb begin

        if (divisor == 16'd0)
            terminal_count = 32'd1;

        else
            terminal_count = {16'd0, divisor};

    end

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            counter     <= 32'd0;
            sample_tick <= 1'b0;
        end

        else begin

            if (counter == terminal_count - 1) begin
                counter     <= 32'd0;
                sample_tick <= 1'b1;
            end

            else begin
                counter     <= counter + 1'b1;
                sample_tick <= 1'b0;
            end

        end

    end

endmodule