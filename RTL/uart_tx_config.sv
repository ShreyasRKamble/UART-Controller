module uart_tx_config (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       baud_tick,
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    input  logic [7:0] lcr,

    output logic       txd,
    output logic       tx_busy,
    output logic       tx_done
);

    // =====================================================
    // LCR configuration
    // =====================================================

    logic [1:0] data_bits;
    logic       stop_bits;
    logic       parity_enable;
    logic       even_parity;
    logic       stick_parity;
    logic       break_control;

    assign data_bits      = lcr[1:0];
    assign stop_bits      = lcr[2];
    assign parity_enable  = lcr[3];
    assign even_parity    = lcr[4];
    assign stick_parity   = lcr[5];
    assign break_control  = lcr[6];


    // =====================================================
    // Data length
    // 00 -> 5 bits
    // 01 -> 6 bits
    // 10 -> 7 bits
    // 11 -> 8 bits
    // =====================================================

    logic [3:0] data_length;

    always_comb begin
        case (data_bits)

            2'b00: data_length = 4'd5;
            2'b01: data_length = 4'd6;
            2'b10: data_length = 4'd7;
            2'b11: data_length = 4'd8;

            default: data_length = 4'd8;

        endcase
    end


    // =====================================================
    // TX FSM
    // =====================================================

    typedef enum logic [2:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_PARITY,
        TX_STOP1,
        TX_STOP2
    } tx_state_t;

    tx_state_t state;


    // =====================================================
    // Internal registers
    // =====================================================

    logic [7:0] data_reg;
    logic [2:0] bit_count;
    logic       parity_bit;


    // =====================================================
    // Parity generation
    // =====================================================

    always_comb begin

    if (stick_parity) begin

        if (even_parity)
            parity_bit = 1'b0;
        else
            parity_bit = 1'b1;

    end
    else if (even_parity) begin

        case (data_length)

            4'd5: parity_bit = ^data_reg[4:0];
            4'd6: parity_bit = ^data_reg[5:0];
            4'd7: parity_bit = ^data_reg[6:0];
            4'd8: parity_bit = ^data_reg[7:0];

            default: parity_bit = ^data_reg[7:0];

        endcase

    end
    else begin

        case (data_length)

            4'd5: parity_bit = ~(^data_reg[4:0]);
            4'd6: parity_bit = ~(^data_reg[5:0]);
            4'd7: parity_bit = ~(^data_reg[6:0]);
            4'd8: parity_bit = ~(^data_reg[7:0]);

            default: parity_bit = ~(^data_reg[7:0]);

        endcase

    end

end


    // =====================================================
    // TX FSM
    // =====================================================

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

            // Default
            tx_done <= 1'b0;


            case (state)


                // =================================================
                // IDLE
                // =================================================

                TX_IDLE: begin

                    txd     <= 1'b1;
                    tx_busy <= 1'b0;

                    // Break forces TX line LOW
                    if (break_control) begin

                        txd     <= 1'b0;
                        tx_busy <= 1'b0;

                    end

                    else if (tx_start) begin

                        // Load data
                        data_reg  <= tx_data;
                        bit_count <= 3'd0;

                        tx_busy <= 1'b1;

                        // START BIT begins immediately
                        txd <= 1'b0;

                        state <= TX_START;

                    end

                end


                // =================================================
                // START BIT
                // =================================================

                TX_START: begin

                    if (baud_tick) begin

                        // Start bit has lasted exactly
                        // one baud period.

                        // Send first data bit
                        txd <= data_reg[0];

                        bit_count <= 3'd1;

                        state <= TX_DATA;

                    end

                end


                // =================================================
                // DATA BITS
                // =================================================

                TX_DATA: begin

                    if (baud_tick) begin

                        // Last data bit?
                        if (bit_count == data_length - 1) begin

                            if (parity_enable) begin

                                // Send parity bit
                                txd <= parity_bit;

                                state <= TX_PARITY;

                            end
                            else begin

                                // No parity
                                // Start stop bit
                                txd <= 1'b1;

                                state <= TX_STOP1;

                            end

                            bit_count <= 3'd0;

                        end

                        else begin

                            // Send next data bit
                            txd <= data_reg[bit_count];

                            bit_count <= bit_count + 1'b1;

                        end

                    end

                end


                // =================================================
                // PARITY
                // =================================================

                TX_PARITY: begin

                    if (baud_tick) begin

                        // Move to first stop bit
                        txd <= 1'b1;

                        state <= TX_STOP1;

                    end

                end


                // =================================================
                // STOP BIT 1
                // =================================================

                TX_STOP1: begin

                    if (baud_tick) begin

                        if (stop_bits) begin

                            // Two stop bits
                            txd <= 1'b1;

                            state <= TX_STOP2;

                        end

                        else begin

                            // One stop bit
                            txd     <= 1'b1;
                            tx_busy <= 1'b0;
                            tx_done <= 1'b1;

                            state <= TX_IDLE;

                        end

                    end

                end


                // =================================================
                // STOP BIT 2
                // =================================================

                TX_STOP2: begin

                    if (baud_tick) begin

                        txd     <= 1'b1;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;

                        state <= TX_IDLE;

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state     <= TX_IDLE;
                    txd       <= 1'b1;
                    tx_busy   <= 1'b0;
                    tx_done   <= 1'b0;
                    bit_count <= 3'd0;

                end

            endcase

        end

    end

endmodule