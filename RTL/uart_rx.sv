module uart_rx (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       baud_tick,
    input  logic       rxd,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_busy,

    output logic       framing_error
);

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    rx_state_t state;

    logic [7:0] data_reg;
    logic [2:0] bit_count;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state         <= RX_IDLE;
            data_reg      <= 8'h00;
            bit_count     <= 3'd0;

            rx_data       <= 8'h00;
            rx_valid      <= 1'b0;
            rx_busy       <= 1'b0;
            framing_error <= 1'b0;

        end

        else begin

            // rx_valid is a one-clock pulse
            rx_valid <= 1'b0;

            case (state)

                // =========================================
                // IDLE
                // =========================================

                RX_IDLE: begin

                    rx_busy       <= 1'b0;
                    framing_error <= 1'b0;

                    // UART line goes LOW for start bit
                    if (rxd == 1'b0) begin

                        rx_busy <= 1'b1;
                        state   <= RX_START;

                    end

                end


                // =========================================
                // START BIT
                // =========================================

                RX_START: begin

                    rx_busy <= 1'b1;

                    if (baud_tick) begin

                        // Verify start bit is still LOW
                        if (rxd == 1'b0) begin

                            bit_count <= 3'd0;
                            state     <= RX_DATA;

                        end

                        else begin

                            // False start
                            state <= RX_IDLE;

                        end

                    end

                end


                // =========================================
                // DATA BITS
                // =========================================

                RX_DATA: begin

                    rx_busy <= 1'b1;

                    if (baud_tick) begin

                        // UART sends LSB first
                        data_reg[bit_count] <= rxd;

                        if (bit_count == 3'd7) begin

                            bit_count <= 3'd0;
                            state     <= RX_STOP;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end

                end


                // =========================================
                // STOP BIT
                // =========================================

                RX_STOP: begin

                    rx_busy <= 1'b1;

                    if (baud_tick) begin

                        if (rxd == 1'b1) begin

                            framing_error <= 1'b0;

                        end

                        else begin

                            framing_error <= 1'b1;

                        end

                        rx_data  <= data_reg;
                        rx_valid <= 1'b1;
                        rx_busy  <= 1'b0;

                        state <= RX_IDLE;

                    end

                end


                // =========================================
                // DEFAULT
                // =========================================

                default: begin

                    state   <= RX_IDLE;
                    rx_busy <= 1'b0;

                end

            endcase

        end

    end

endmodule