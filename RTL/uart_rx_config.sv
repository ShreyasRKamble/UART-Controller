module uart_rx_config (
    input  logic       clk,
    input  logic       rst_n,

    input  logic       sample_tick,
    input  logic       rxd,

    input  logic [7:0] lcr,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_busy,

    output logic       parity_error,
    output logic       framing_error
);

    // =========================================================
    // LCR CONFIGURATION
    // =========================================================

    logic [1:0] data_bits;
    logic       stop_bits;
    logic       parity_enable;
    logic       even_parity;
    logic       stick_parity;

    assign data_bits     = lcr[1:0];
    assign stop_bits     = lcr[2];
    assign parity_enable = lcr[3];
    assign even_parity   = lcr[4];
    assign stick_parity  = lcr[5];


    // =========================================================
    // DATA LENGTH
    // =========================================================

    logic [3:0] data_length;

    always_comb begin

        case (data_bits)

            2'b00: data_length = 4'd5;
            2'b01: data_length = 4'd6;
            2'b10: data_length = 4'd7;
            2'b11: data_length = 4'd8;

            default:
                data_length = 4'd8;

        endcase

    end


    // =========================================================
    // RX FSM
    // =========================================================

    typedef enum logic [2:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP1,
        RX_STOP2
    } rx_state_t;

    rx_state_t state;


    // =========================================================
    // INTERNAL REGISTERS
    // =========================================================

    logic [7:0] data_reg;

    logic [3:0] bit_count;

    logic [3:0] sample_count;

    logic received_parity;

    logic calculated_parity;


    // =========================================================
    // PARITY CALCULATION
    // =========================================================

    always_comb begin

        if (stick_parity) begin

            if (even_parity)
                calculated_parity = 1'b0;
            else
                calculated_parity = 1'b1;

        end

        else if (even_parity) begin

            case (data_length)

                4'd5:
                    calculated_parity = ^data_reg[4:0];

                4'd6:
                    calculated_parity = ^data_reg[5:0];

                4'd7:
                    calculated_parity = ^data_reg[6:0];

                4'd8:
                    calculated_parity = ^data_reg[7:0];

                default:
                    calculated_parity = ^data_reg[7:0];

            endcase

        end

        else begin

            case (data_length)

                4'd5:
                    calculated_parity = ~(^data_reg[4:0]);

                4'd6:
                    calculated_parity = ~(^data_reg[5:0]);

                4'd7:
                    calculated_parity = ~(^data_reg[6:0]);

                4'd8:
                    calculated_parity = ~(^data_reg[7:0]);

                default:
                    calculated_parity = ~(^data_reg[7:0]);

            endcase

        end

    end


    // =========================================================
    // RX FSM
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            state           <= RX_IDLE;

            data_reg        <= 8'h00;

            bit_count       <= 4'd0;

            sample_count    <= 4'd0;

            received_parity <= 1'b0;

            rx_data         <= 8'h00;

            rx_valid        <= 1'b0;

            rx_busy         <= 1'b0;

            parity_error    <= 1'b0;

            framing_error   <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // RX_VALID IS A ONE-CLOCK PULSE
            // -------------------------------------------------

            rx_valid <= 1'b0;


            case (state)


                // =================================================
                // IDLE
                // =================================================

                RX_IDLE: begin

                    rx_busy      <= 1'b0;

                    sample_count <= 4'd0;

                    bit_count    <= 4'd0;

                    parity_error  <= 1'b0;

                    framing_error <= 1'b0;


                    // Detect falling edge / start bit

                    if (rxd == 1'b0) begin

                        rx_busy      <= 1'b1;

                        sample_count <= 4'd0;

                        state        <= RX_START;

                    end

                end


                // =================================================
                // START BIT
                //
                // Wait 8 sample ticks.
                //
                // This puts us at the CENTER of the start bit.
                // =================================================

                RX_START: begin

    rx_busy <= 1'b1;

    if (sample_tick) begin

        $display(
            "START | TIME=%0t | RXD=%b | SAMPLE_CNT=%0d",
            $time,
            rxd,
            sample_count
        );

        if (sample_count == 4'd7) begin

            if (rxd == 1'b0) begin

                sample_count <= 4'd0;
                bit_count    <= 4'd0;
                state        <= RX_DATA;

            end
            else begin

                state   <= RX_IDLE;
                rx_busy <= 1'b0;

            end

        end
        else begin

            sample_count <= sample_count + 1'b1;
        end

    end

end  //DATA
               
               RX_DATA: begin

    rx_busy <= 1'b1;

    if (sample_tick) begin

        $display(
            "DATA  | TIME=%0t | RXD=%b | SAMPLE_CNT=%0d | BIT_CNT=%0d",
            $time,
            rxd,
            sample_count,
            bit_count
        );

        if (sample_count == 4'd15) begin

            data_reg[bit_count] <= rxd;

            sample_count <= 4'd0;

            if (bit_count == data_length - 1) begin

                bit_count <= 4'd0;

                if (parity_enable)
                    state <= RX_PARITY;
                else
                    state <= RX_STOP1;

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
                // PARITY
                // =================================================

                RX_PARITY: begin

                    rx_busy <= 1'b1;


                    if (sample_tick) begin

                        if (sample_count == 4'd15) begin

                            received_parity <= rxd;


                            if (rxd != calculated_parity)
                                parity_error <= 1'b1;
                            else
                                parity_error <= 1'b0;


                            sample_count <= 4'd0;

                            state <= RX_STOP1;

                        end

                        else begin

                            sample_count <=
                                sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // STOP BIT 1
                // =================================================

                RX_STOP1: begin

                    rx_busy <= 1'b1;


                    if (sample_tick) begin

                        if (sample_count == 4'd15) begin

                            if (rxd != 1'b1)
                                framing_error <= 1'b1;
                            else
                                framing_error <= 1'b0;


                            sample_count <= 4'd0;


                            if (stop_bits) begin

                                state <= RX_STOP2;

                            end

                            else begin

                                // Frame complete

                                rx_data  <= data_reg;

                                rx_valid <= 1'b1;

                                rx_busy  <= 1'b0;

                                state <= RX_IDLE;

                            end

                        end

                        else begin

                            sample_count <=
                                sample_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // STOP BIT 2
                // =================================================

                RX_STOP2: begin

                    rx_busy <= 1'b1;


                    if (sample_tick) begin

                        if (sample_count == 4'd15) begin

                            if (rxd != 1'b1)
                                framing_error <= 1'b1;


                            rx_data  <= data_reg;

                            rx_valid <= 1'b1;

                            rx_busy  <= 1'b0;

                            sample_count <= 4'd0;

                            state <= RX_IDLE;

                        end

                        else begin

                            sample_count <=
                                sample_count + 1'b1;

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

                    bit_count    <= 4'd0;

                end

            endcase

        end

    end

endmodule