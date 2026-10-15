module uart_tx (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       baud_tick,

    input  logic       tx_start,
    input  logic [7:0] tx_data,

    output logic       txd,
    output logic       tx_busy,
    output logic       tx_done
);

    typedef enum logic [1:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_STOP
    } tx_state_t;

    tx_state_t state;

    logic [7:0] data_reg;
    logic [2:0] bit_count;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state     <= TX_IDLE;
            data_reg  <= 8'h00;
            bit_count <= 3'd0;

            txd       <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
        end

        else begin

            // Default: done is only a one-clock pulse
            tx_done <= 1'b0;

            case (state)

                // -----------------------------------------
                // IDLE
                // -----------------------------------------
                TX_IDLE: begin

                    txd     <= 1'b1;
                    tx_busy <= 1'b0;

                    if (tx_start) begin

                        data_reg  <= tx_data;
                        bit_count <= 3'd0;

                        tx_busy <= 1'b1;
                        state   <= TX_START;

                    end

                end

                // -----------------------------------------
                // START BIT
                // -----------------------------------------
                TX_START: begin

                    tx_busy <= 1'b1;
                    txd     <= 1'b0;

                    if (baud_tick) begin
                        state <= TX_DATA;
                    end

                end

                // -----------------------------------------
                // DATA BITS
                // -----------------------------------------
                TX_DATA: begin

                    tx_busy <= 1'b1;
                    txd     <= data_reg[bit_count];

                    if (baud_tick) begin

                        if (bit_count == 3'd7) begin
                            bit_count <= 3'd0;
                            state     <= TX_STOP;
                        end

                        else begin
                            bit_count <= bit_count + 1'b1;
                        end

                    end

                end

                // -----------------------------------------
                // STOP BIT
                // -----------------------------------------
                TX_STOP: begin

                    tx_busy <= 1'b1;
                    txd     <= 1'b1;

                    if (baud_tick) begin

                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;

                        state <= TX_IDLE;

                    end

                end

                default: begin
                    state <= TX_IDLE;
                    txd   <= 1'b1;
                end

            endcase

        end

    end

endmodule