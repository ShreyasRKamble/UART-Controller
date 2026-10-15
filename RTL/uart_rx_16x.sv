module uart_rx_16x (
    input  logic       clk,
    input  logic       rst_n,

    // 16x oversampling tick
    input  logic       sample_tick,

    // Serial input
    input  logic       rxd,

    // Received data
    output logic [7:0] rx_data,
    output logic       rx_valid,

    // Receiver status
    output logic       rx_busy,
    output logic       framing_error
);

    // =====================================================
    // RX STATES
    // =====================================================

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;

    rx_state_t state;

    // =====================================================
    // Internal registers
    // =====================================================

    logic [7:0] data_reg;

    // Counts data bits: 0 -> 7
    logic [2:0] bit_count;

    // Counts 16x samples: 0 -> 15
    logic [3:0] sample_count;

    // =====================================================
    // RX FSM
    // =====================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state         <= RX_IDLE;

            data_reg      <= 8'h00;
            bit_count     <= 3'd0;
            sample_count  <= 4'd0;

            rx_data       <= 8'h00;
            rx_valid      <= 1'b0;
            rx_busy       <= 1'b0;

            framing_error <= 1'b0;

        end

        else begin

            // rx_valid is a one-clock pulse
            rx_valid <= 1'b0;

            case (state)

                // =================================================
                // IDLE
                // =================================================

                RX_IDLE: begin

                    rx_busy       <= 1'b0;
                    framing_error <= 1'b0;
                    sample_count  <= 4'd0;
                    bit_count     <= 3'd0;

                    // Detect falling edge / start bit
                    if (rxd == 1'b0) begin

                        rx_busy      <= 1'b1;
                        sample_count <= 4'd0;

                        state <= RX_START;

                    end

                end


                // =================================================
                // START BIT
                // =================================================

                RX_START: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (sample_count == 4'd7) begin

                            // Center of start bit
                            if (rxd == 1'b0) begin

                                sample_count <= 4'd0;
                                bit_count    <= 3'd0;

                                state <= RX_DATA;

                            end

                            else begin

                                // False start
                                state <= RX_IDLE;
                                rx_busy <= 1'b0;

                            end

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // DATA BITS
                // =================================================

                RX_DATA: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (sample_count == 4'd15) begin

                            // Sample data at center
                            data_reg[bit_count] <= rxd;

                            sample_count <= 4'd0;

                            if (bit_count == 3'd7) begin

                                bit_count <= 3'd0;
                                state <= RX_STOP;

                            end

                            else begin

                                bit_count <= bit_count + 1'b1;

                            end

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // STOP BIT
                // =================================================

                RX_STOP: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (sample_count == 4'd15) begin

                            // Check stop bit
                            if (rxd == 1'b1) begin

                                framing_error <= 1'b0;

                            end

                            else begin

                                framing_error <= 1'b1;

                            end

                            // Present received byte
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;

                            rx_busy <= 1'b0;

                            sample_count <= 4'd0;

                            state <= RX_IDLE;

                        end

                        else begin

                            sample_count <= sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state        <= RX_IDLE;
                    rx_busy      <= 1'b0;
                    sample_count <= 4'd0;
                    bit_count    <= 3'd0;

                end

            endcase

        end

    end

endmodule