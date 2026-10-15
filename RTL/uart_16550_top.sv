`timescale 1ns/1ps

module uart_16550_top #(
    parameter integer CLOCK_FREQ = 50_000_000,
    parameter integer BAUD_RATE  = 115_200,
    parameter integer FIFO_DEPTH = 16
)(
    // =========================================================
    // CLOCK / RESET
    // =========================================================

    input  logic       clk,
    input  logic       rst_n,

    // =========================================================
    // HOST REGISTER INTERFACE
    // =========================================================

    input  logic [2:0] addr,
    input  logic       wr_en,
    input  logic       rd_en,

    input  logic [7:0] wr_data,
    output logic [7:0] rd_data,

    // =========================================================
    // UART SERIAL
    // =========================================================

    input  logic       rxd,
    output logic       txd,

    // =========================================================
    // MODEM INPUTS
    // =========================================================

    input  logic       cts,
    input  logic       dsr,
    input  logic       ri,
    input  logic       dcd,

    // =========================================================
    // MODEM OUTPUTS
    // =========================================================

    output logic       dtr,
    output logic       rts,
    output logic       out1,
    output logic       out2
);

    // =========================================================
    // REGISTER ADDRESSES
    // =========================================================

    localparam logic [2:0] ADDR_RBR_THR_DLL = 3'h0;
    localparam logic [2:0] ADDR_IER_DLM     = 3'h1;
    localparam logic [2:0] ADDR_IIR_FCR     = 3'h2;
    localparam logic [2:0] ADDR_LCR         = 3'h3;
    localparam logic [2:0] ADDR_MCR         = 3'h4;
    localparam logic [2:0] ADDR_LSR         = 3'h5;
    localparam logic [2:0] ADDR_MSR         = 3'h6;
    localparam logic [2:0] ADDR_SCR         = 3'h7;

    // =========================================================
    // INTERNAL REGISTERS
    // =========================================================

    logic [7:0] lcr;
    logic [7:0] mcr;
    logic [7:0] fcr;
    logic [7:0] ier;
    logic [7:0] dll;
    logic [7:0] dlm;
    logic [7:0] scr;
    logic [3:0] psd;

    // =========================================================
    // LCR DECODE
    // =========================================================

    logic       dlab;
    logic       break_enable;
    logic       parity_enable;
    logic       even_parity;
    logic       stick_parity;
    logic       two_stop_bits;

    logic [1:0] word_length;

    always_comb begin

        dlab          = lcr[7];
        break_enable  = lcr[6];
        parity_enable = lcr[3];
        even_parity   = lcr[4];
        stick_parity  = lcr[5];
        two_stop_bits = lcr[2];

        word_length = lcr[1:0];

    end

    // =========================================================
    // FCR
    // =========================================================

    logic fifo_enable;
    logic tx_fifo_reset_cmd;
    logic rx_fifo_reset_cmd;

    always_comb begin

        fifo_enable      = fcr[0];
        rx_fifo_reset_cmd = fcr[1];
        tx_fifo_reset_cmd = fcr[2];

    end

    // =========================================================
    // REGISTER WRITE LOGIC
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            lcr <= 8'h00;
            mcr <= 8'h00;
            fcr <= 8'h00;
            ier <= 8'h00;
            dll <= 8'h01;
            dlm <= 8'h00;
            scr <= 8'h00;
            psd <= 4'h0;

        end
        else begin

            if (wr_en) begin

                case (addr)

                    // -------------------------------------------------
                    // Address 0
                    // DLL when DLAB = 1
                    // THR handled separately when DLAB = 0
                    // -------------------------------------------------

                    ADDR_RBR_THR_DLL: begin

                        if (dlab)
                            dll <= wr_data;

                    end

                    // -------------------------------------------------
                    // Address 1
                    // DLM when DLAB = 1
                    // IER when DLAB = 0
                    // -------------------------------------------------

                    ADDR_IER_DLM: begin

                        if (dlab)
                            dlm <= wr_data;
                        else
                            ier <= wr_data;

                    end

                    // -------------------------------------------------
                    // Address 2
                    // FCR
                    // -------------------------------------------------

                    ADDR_IIR_FCR: begin

                        fcr <= wr_data;

                    end

                    // -------------------------------------------------
                    // Address 3
                    // LCR
                    // -------------------------------------------------

                    ADDR_LCR: begin

                        lcr <= wr_data;

                    end

                    // -------------------------------------------------
                    // Address 4
                    // MCR
                    // -------------------------------------------------

                    ADDR_MCR: begin

                        mcr <= wr_data;

                    end

                    // -------------------------------------------------
                    // Address 5
                    // PSD when DLAB = 1
                    // -------------------------------------------------

                    ADDR_LSR: begin

                        if (dlab)
                            psd <= wr_data[3:0];

                    end

                    // -------------------------------------------------
                    // Address 7
                    // SCR
                    // -------------------------------------------------

                    ADDR_SCR: begin

                        scr <= wr_data;

                    end

                    default: begin

                    end

                endcase

            end

        end

    end

    // =========================================================
    // BAUD GENERATOR
    //
    // baud rate:
    //
    // CLOCK_FREQ
    // ------------------------------
    // 16 * divisor * (PSD + 1)
    //
    // divisor = 0 => 65536
    // =========================================================

    logic [31:0] divisor_value;
    logic [31:0] psd_value;
    logic [31:0] baud_terminal_count;

    logic [31:0] baud_counter;
    logic [3:0]  baud16_count;

    logic baud_tick;
    logic sample_tick;

    always_comb begin

        if ({dlm, dll} == 16'h0000)
            divisor_value = 32'd65536;
        else
            divisor_value = {16'h0000, dlm, dll};

        psd_value = {28'd0, psd} + 32'd1;

        baud_terminal_count =
            divisor_value * psd_value;

    end

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            baud_counter <= 32'd0;
            baud16_count <= 4'd0;

            baud_tick   <= 1'b0;
            sample_tick <= 1'b0;

        end
        else begin

            baud_tick   <= 1'b0;
            sample_tick <= 1'b0;

            if (baud_terminal_count != 0) begin

                if (baud_counter >= baud_terminal_count - 1) begin

                    baud_counter <= 32'd0;

                    sample_tick <= 1'b1;

                    if (baud16_count == 4'd15) begin

                        baud16_count <= 4'd0;
                        baud_tick    <= 1'b1;

                    end
                    else begin

                        baud16_count <=
                            baud16_count + 1'b1;

                    end

                end
                else begin

                    baud_counter <=
                        baud_counter + 1'b1;

                end

            end

        end

    end

    // =========================================================
    // RX SYNCHRONIZER
    // =========================================================

    logic rxd_sync_ff1;
    logic rxd_sync_ff2;

    logic rxd_sync;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rxd_sync_ff1 <= 1'b1;
            rxd_sync_ff2 <= 1'b1;

        end
        else begin

            rxd_sync_ff1 <= rxd;
            rxd_sync_ff2 <= rxd_sync_ff1;

        end

    end

    assign rxd_sync = rxd_sync_ff2;

    // =========================================================
    // LOOPBACK
    //
    // MCR[4] = 1
    //
    // TX -> RX internally
    // =========================================================

    logic loopback;

    logic txd_internal;
    logic rx_serial;

    assign loopback = mcr[4];

    assign rx_serial =
        loopback ? txd_internal : rxd_sync;

    assign txd =
        loopback ? 1'b1 : txd_internal;

    // =========================================================
    // TX FIFO
    // =========================================================

    logic [7:0] tx_fifo_mem [0:FIFO_DEPTH-1];

    logic [3:0] tx_wr_ptr;
    logic [3:0] tx_rd_ptr;

    logic [4:0] tx_fifo_count;

    logic tx_fifo_empty;
    logic tx_fifo_full;

    logic tx_fifo_wr;
    logic tx_fifo_rd;

    logic [7:0] tx_fifo_data;

    assign tx_fifo_empty =
        (tx_fifo_count == 0);

    assign tx_fifo_full =
        (tx_fifo_count == FIFO_DEPTH);

    assign tx_fifo_data =
        tx_fifo_mem[tx_rd_ptr];

    // =========================================================
    // TX CONTROL
    // =========================================================

    typedef enum logic [2:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_PARITY,
        TX_STOP
    } tx_state_t;

    tx_state_t tx_state;

    logic [3:0] tx_sample_count;
    logic [2:0] tx_bit_count;

    logic [7:0] tx_data_reg;

    logic tx_parity;

    logic tx_busy;
    logic tx_done;

    logic [3:0] tx_data_bits;

    always_comb begin

        case (word_length)

            2'b00:
                tx_data_bits = 4'd5;

            2'b01:
                tx_data_bits = 4'd6;

            2'b10:
                tx_data_bits = 4'd7;

            default:
                tx_data_bits = 4'd8;

        endcase

    end

    // =========================================================
    // TX FIFO WRITE
    // =========================================================

    assign tx_fifo_wr =
        wr_en &&
        !dlab &&
        (addr == ADDR_RBR_THR_DLL) &&
        !tx_fifo_full;

    // =========================================================
    // TX FIFO READ
    //
    // Read the FIFO at the end of the start-bit period.
    // =========================================================

    assign tx_fifo_rd =
        (tx_state == TX_START) &&
        (tx_sample_count == 4'd15) &&
        sample_tick;

    // =========================================================
    // TX FIFO STORAGE
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_fifo_count <= 5'd0;
            tx_wr_ptr     <= 4'd0;
            tx_rd_ptr     <= 4'd0;

        end
        else if (tx_fifo_reset_cmd) begin

            tx_fifo_count <= 5'd0;
            tx_wr_ptr     <= 4'd0;
            tx_rd_ptr     <= 4'd0;

        end
        else begin

            case ({tx_fifo_wr, tx_fifo_rd})

                2'b10: begin

                    tx_fifo_mem[tx_wr_ptr] <= wr_data;

                    tx_wr_ptr <=
                        tx_wr_ptr + 1'b1;

                    tx_fifo_count <=
                        tx_fifo_count + 1'b1;

                end

                2'b01: begin

                    tx_rd_ptr <=
                        tx_rd_ptr + 1'b1;

                    tx_fifo_count <=
                        tx_fifo_count - 1'b1;

                end

                2'b11: begin

                    tx_fifo_mem[tx_wr_ptr] <= wr_data;

                    tx_wr_ptr <=
                        tx_wr_ptr + 1'b1;

                    tx_rd_ptr <=
                        tx_rd_ptr + 1'b1;

                end

                default: begin

                end

            endcase

        end

    end

    // =========================================================
    // TX SAMPLE COUNTER
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_sample_count <= 4'd0;

        end
        else if (!tx_busy) begin

            tx_sample_count <= 4'd0;

        end
        else if (sample_tick) begin

            if (tx_sample_count == 4'd15)
                tx_sample_count <= 4'd0;
            else
                tx_sample_count <=
                    tx_sample_count + 1'b1;

        end

    end

    // =========================================================
    // TX FSM
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_state      <= TX_IDLE;

            txd_internal  <= 1'b1;

            tx_data_reg   <= 8'h00;
            tx_bit_count  <= 3'd0;

            tx_busy       <= 1'b0;
            tx_done       <= 1'b0;

            tx_parity     <= 1'b0;

        end
        else begin

            tx_done <= 1'b0;

            case (tx_state)

                // -------------------------------------------------
                // IDLE
                // -------------------------------------------------

                TX_IDLE: begin

                    txd_internal <= 1'b1;
                    tx_busy      <= 1'b0;

                    tx_bit_count <= 3'd0;

                    if (!tx_fifo_empty) begin

                        tx_data_reg <= tx_fifo_data;

                        tx_busy <= 1'b1;

                        txd_internal <= 1'b0;

                        tx_sample_count <= 4'd0;

                        tx_state <= TX_START;

                    end

                end

                // -------------------------------------------------
                // START
                // -------------------------------------------------

                TX_START: begin

                    tx_busy      <= 1'b1;
                    txd_internal <= 1'b0;

                    if (sample_tick &&
                        (tx_sample_count == 4'd15)) begin

                        tx_bit_count <= 3'd0;

                        txd_internal <=
                            tx_data_reg[0];

                        tx_state <= TX_DATA;

                    end

                end

                // -------------------------------------------------
                // DATA
                // -------------------------------------------------

                TX_DATA: begin

                    tx_busy <= 1'b1;

                    if (sample_tick &&
                        (tx_sample_count == 4'd15)) begin

                        if (tx_bit_count ==
                            tx_data_bits - 1) begin

                            // Calculate parity if required

                            if (parity_enable) begin

                                tx_parity <=
                                    ^tx_data_reg;

                                if (even_parity)
                                    txd_internal <=
                                        ^tx_data_reg;
                                else
                                    txd_internal <=
                                        ~(^tx_data_reg);

                                tx_state <=
                                    TX_PARITY;

                            end
                            else begin

                                txd_internal <= 1'b1;

                                tx_state <=
                                    TX_STOP;

                            end

                        end
                        else begin

                            tx_bit_count <=
                                tx_bit_count + 1'b1;

                            txd_internal <=
                                tx_data_reg[
                                    tx_bit_count + 1'b1
                                ];

                        end

                    end

                end

                // -------------------------------------------------
                // PARITY
                // -------------------------------------------------

                TX_PARITY: begin

                    tx_busy <= 1'b1;

                    if (sample_tick &&
                        (tx_sample_count == 4'd15)) begin

                        txd_internal <= 1'b1;

                        tx_state <= TX_STOP;

                    end

                end

                // -------------------------------------------------
                // STOP
                // -------------------------------------------------

                TX_STOP: begin

                    tx_busy      <= 1'b1;
                    txd_internal <= 1'b1;

                    if (sample_tick &&
                        (tx_sample_count == 4'd15)) begin

                        if (two_stop_bits) begin

                            tx_state <= TX_STOP;

                        end
                        else begin

                            tx_state <= TX_IDLE;

                            tx_busy <= 1'b0;
                            tx_done <= 1'b1;

                        end

                    end

                end

                default: begin

                    tx_state     <= TX_IDLE;
                    txd_internal <= 1'b1;
                    tx_busy      <= 1'b0;

                end

            endcase

        end

    end

    // =========================================================
    // RX SIGNALS
    // =========================================================

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_busy;

    logic       parity_error;
    logic       framing_error;

    // =========================================================
    // RX CONFIGURABLE RECEIVER
    // =========================================================

    typedef enum logic [2:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP
    } rx_state_t;

    rx_state_t rx_state;

    logic [3:0] rx_sample_count;
    logic [2:0] rx_bit_count;

    logic [7:0] rx_shift_reg;

    logic rx_parity;

    logic [3:0] rx_data_bits;

    always_comb begin

        case (word_length)

            2'b00:
                rx_data_bits = 4'd5;

            2'b01:
                rx_data_bits = 4'd6;

            2'b10:
                rx_data_bits = 4'd7;

            default:
                rx_data_bits = 4'd8;

        endcase

    end

    // =========================================================
    // RX FSM
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_state        <= RX_IDLE;

            rx_sample_count <= 4'd0;
            rx_bit_count    <= 3'd0;

            rx_shift_reg    <= 8'h00;
            rx_data         <= 8'h00;

            rx_valid        <= 1'b0;
            rx_busy         <= 1'b0;

            parity_error    <= 1'b0;
            framing_error   <= 1'b0;

            rx_parity       <= 1'b0;

        end
        else begin

            rx_valid <= 1'b0;

            case (rx_state)

                // -------------------------------------------------
                // IDLE
                // -------------------------------------------------

                RX_IDLE: begin

                    rx_busy <= 1'b0;

                    rx_sample_count <= 4'd0;
                    rx_bit_count    <= 3'd0;

                    if (!rx_serial) begin

                        rx_busy <= 1'b1;

                        rx_sample_count <= 4'd0;

                        rx_state <= RX_START;

                    end

                end

                // -------------------------------------------------
                // START
                // -------------------------------------------------

                RX_START: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (rx_sample_count == 4'd7) begin

                            if (!rx_serial) begin

                                rx_sample_count <= 4'd0;
                                rx_bit_count    <= 3'd0;

                                rx_shift_reg <= 8'h00;

                                rx_state <=
                                    RX_DATA;

                            end
                            else begin

                                rx_state <= RX_IDLE;
                                rx_busy  <= 1'b0;

                            end

                        end
                        else begin

                            rx_sample_count <=
                                rx_sample_count + 1'b1;

                        end

                    end

                end

                // -------------------------------------------------
                // DATA
                // -------------------------------------------------

                RX_DATA: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (rx_sample_count == 4'd15) begin

                            rx_shift_reg[rx_bit_count]
                                <= rx_serial;

                            rx_sample_count <= 4'd0;

                            if (rx_bit_count ==
                                rx_data_bits - 1) begin

                                if (parity_enable) begin

                                    rx_state <=
                                        RX_PARITY;

                                end
                                else begin

                                    rx_state <=
                                        RX_STOP;

                                end

                            end
                            else begin

                                rx_bit_count <=
                                    rx_bit_count + 1'b1;

                            end

                        end
                        else begin

                            rx_sample_count <=
                                rx_sample_count + 1'b1;

                        end

                    end

                end

                // -------------------------------------------------
                // PARITY
                // -------------------------------------------------

                RX_PARITY: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (rx_sample_count == 4'd15) begin

                            if (even_parity)
                                parity_error <=
                                    (rx_serial !=
                                     (^rx_shift_reg));
                            else
                                parity_error <=
                                    (rx_serial !=
                                     ~(^rx_shift_reg));

                            rx_sample_count <= 4'd0;

                            rx_state <=
                                RX_STOP;

                        end
                        else begin

                            rx_sample_count <=
                                rx_sample_count + 1'b1;

                        end

                    end

                end

                // -------------------------------------------------
                // STOP
                // -------------------------------------------------

                RX_STOP: begin

                    rx_busy <= 1'b1;

                    if (sample_tick) begin

                        if (rx_sample_count == 4'd15) begin

                            if (!rx_serial)
                                framing_error <= 1'b1;
                            else
                                framing_error <= 1'b0;

                            rx_data <= rx_shift_reg;

                            rx_valid <= 1'b1;

                            rx_busy <= 1'b0;

                            rx_state <=
                                RX_IDLE;

                            rx_sample_count <=
                                4'd0;

                        end
                        else begin

                            rx_sample_count <=
                                rx_sample_count + 1'b1;

                        end

                    end

                end

                default: begin

                    rx_state <= RX_IDLE;
                    rx_busy  <= 1'b0;

                end

            endcase

        end

    end

    // =========================================================
    // RX FIFO
    // =========================================================

    logic [7:0] rx_fifo_mem [0:FIFO_DEPTH-1];

    logic [3:0] rx_wr_ptr;
    logic [3:0] rx_rd_ptr;

    logic [4:0] rx_fifo_count;

    logic rx_fifo_empty;
    logic rx_fifo_full;

    logic rx_fifo_wr;
    logic rx_fifo_rd;

    logic [7:0] rx_fifo_data;

    assign rx_fifo_empty =
        (rx_fifo_count == 0);

    assign rx_fifo_full =
        (rx_fifo_count == FIFO_DEPTH);

    assign rx_fifo_data =
        rx_fifo_mem[rx_rd_ptr];

    // =========================================================
    // RX FIFO WRITE
    // =========================================================

    assign rx_fifo_wr =
        rx_valid &&
        !rx_fifo_full;

    // =========================================================
    // RBR READ
    // =========================================================

    assign rx_fifo_rd =
        rd_en &&
        !dlab &&
        (addr == ADDR_RBR_THR_DLL) &&
        !rx_fifo_empty;

    // =========================================================
    // RX FIFO STORAGE
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_fifo_count <= 5'd0;
            rx_wr_ptr     <= 4'd0;
            rx_rd_ptr     <= 4'd0;

        end
        else if (rx_fifo_reset_cmd) begin

            rx_fifo_count <= 5'd0;
            rx_wr_ptr     <= 4'd0;
            rx_rd_ptr     <= 4'd0;

        end
        else begin

            case ({rx_fifo_wr, rx_fifo_rd})

                // -------------------------------------------------
                // WRITE ONLY
                // -------------------------------------------------

                2'b10: begin

                    rx_fifo_mem[rx_wr_ptr] <=
                        rx_data;

                    rx_wr_ptr <=
                        rx_wr_ptr + 1'b1;

                    rx_fifo_count <=
                        rx_fifo_count + 1'b1;

                end

                // -------------------------------------------------
                // READ ONLY
                // -------------------------------------------------

                2'b01: begin

                    rx_rd_ptr <=
                        rx_rd_ptr + 1'b1;

                    rx_fifo_count <=
                        rx_fifo_count - 1'b1;

                end

                // -------------------------------------------------
                // READ + WRITE SAME CYCLE
                // -------------------------------------------------

                2'b11: begin

                    rx_fifo_mem[rx_wr_ptr] <=
                        rx_data;

                    rx_wr_ptr <=
                        rx_wr_ptr + 1'b1;

                    rx_rd_ptr <=
                        rx_rd_ptr + 1'b1;

                end

                default: begin

                end

            endcase

        end

    end

    // =========================================================
    // RBR READ DATA REGISTER
    //
    // IMPORTANT FIX:
    //
    // Capture the FIFO head BEFORE the FIFO pop becomes visible
    // to the combinational read-data logic.
    // =========================================================

    logic [7:0] rbr_read_data;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rbr_read_data <= 8'h00;

        end
        else if (rx_fifo_rd) begin

            rbr_read_data <= rx_fifo_data;

        end

    end

    // =========================================================
    // RX TIMEOUT
    // =========================================================

    logic rx_timeout;

    logic [31:0] rx_timeout_counter;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_timeout_counter <= 32'd0;
            rx_timeout          <= 1'b0;

        end
        else begin

            rx_timeout <= 1'b0;

            if (rx_fifo_empty) begin

                rx_timeout_counter <= 32'd0;

            end
            else if (rx_valid) begin

                rx_timeout_counter <= 32'd0;

            end
            else if (rx_timeout_counter >=
                     (baud_terminal_count * 16 * 4) - 1) begin

                rx_timeout_counter <= 32'd0;

                rx_timeout <= 1'b1;

            end
            else begin

                rx_timeout_counter <=
                    rx_timeout_counter + 1'b1;

            end

        end

    end

    // =========================================================
    // MODEM CONTROL
    // =========================================================

    assign dtr  = mcr[0];
    assign rts  = mcr[1];
    assign out1 = mcr[2];
    assign out2 = mcr[3];

    // =========================================================
    // MSR
    // =========================================================

    logic [7:0] msr;

    logic cts_prev;
    logic dsr_prev;
    logic ri_prev;
    logic dcd_prev;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            msr      <= 8'h00;

            cts_prev <= 1'b1;
            dsr_prev <= 1'b1;
            ri_prev  <= 1'b1;
            dcd_prev <= 1'b1;

        end
        else begin

            // Current modem states

            msr[4] <= cts;
            msr[5] <= dsr;
            msr[6] <= ri;
            msr[7] <= dcd;

            // Delta bits

            msr[0] <=
                cts ^ cts_prev;

            msr[1] <=
                dsr ^ dsr_prev;

            msr[2] <=
                ri ^ ri_prev;

            msr[3] <=
                dcd ^ dcd_prev;

            cts_prev <= cts;
            dsr_prev <= dsr;
            ri_prev  <= ri;
            dcd_prev <= dcd;

        end

    end

    // =========================================================
    // LSR
    // =========================================================

    logic [7:0] lsr;

    always_comb begin

        lsr = 8'h00;

        // -----------------------------------------------------
        // Bit 0: Data Ready
        // -----------------------------------------------------

        lsr[0] = !rx_fifo_empty;

        // -----------------------------------------------------
        // Bit 1: Overrun
        // -----------------------------------------------------

        lsr[1] = 1'b0;

        // -----------------------------------------------------
        // Bit 2: Parity Error
        // -----------------------------------------------------

        lsr[2] = parity_error;

        // -----------------------------------------------------
        // Bit 3: Framing Error
        // -----------------------------------------------------

        lsr[3] = framing_error;

        // -----------------------------------------------------
        // Bit 4: Break Interrupt
        // -----------------------------------------------------

        lsr[4] = 1'b0;

        // -----------------------------------------------------
        // Bit 5: THR Empty
        // -----------------------------------------------------

        lsr[5] = tx_fifo_empty;

        // -----------------------------------------------------
        // Bit 6: THR + TSR Empty
        // -----------------------------------------------------

        lsr[6] =
            tx_fifo_empty &&
            !tx_busy;

        // -----------------------------------------------------
        // Bit 7: FIFO Error
        // -----------------------------------------------------

        lsr[7] = 1'b0;

    end

    // =========================================================
    // HOST READ DATA
    // =========================================================

    always_comb begin

        rd_data = 8'h00;

        if (rd_en) begin

            case (addr)

                // -------------------------------------------------
                // RBR / DLL
                // -------------------------------------------------

                ADDR_RBR_THR_DLL: begin

                    if (dlab)
                        rd_data = dll;
                    else
                        rd_data = rbr_read_data;

                end

                // -------------------------------------------------
                // IER / DLM
                // -------------------------------------------------

                ADDR_IER_DLM: begin

                    if (dlab)
                        rd_data = dlm;
                    else
                        rd_data = ier;

                end

                // -------------------------------------------------
                // IIR
                // -------------------------------------------------

                ADDR_IIR_FCR: begin

                    // Interrupts skipped in this implementation.

                    rd_data = 8'h01;

                end

                // -------------------------------------------------
                // LCR
                // -------------------------------------------------

                ADDR_LCR: begin

                    rd_data = lcr;

                end

                // -------------------------------------------------
                // MCR
                // -------------------------------------------------

                ADDR_MCR: begin

                    rd_data = mcr;

                end

                // -------------------------------------------------
                // LSR / PSD
                // -------------------------------------------------

                ADDR_LSR: begin

                    if (dlab)
                        rd_data = {
                            4'h0,
                            psd
                        };
                    else
                        rd_data = lsr;

                end

                // -------------------------------------------------
                // MSR
                // -------------------------------------------------

                ADDR_MSR: begin

                    rd_data = msr;

                end

                // -------------------------------------------------
                // SCR
                // -------------------------------------------------

                ADDR_SCR: begin

                    rd_data = scr;

                end

                default: begin

                    rd_data = 8'h00;

                end

            endcase

        end

    end

    // =========================================================
    // DEBUG
    // =========================================================

    always @(posedge clk) begin

        if (rst_n) begin

            if (tx_busy || rx_busy || rx_valid) begin

                $display(
                    "TIME=%0t | TX=%b | RX_SERIAL=%b | RX_BUSY=%b | RX_VALID=%b | RX_DATA=%02h",
                    $time,
                    txd_internal,
                    rx_serial,
                    rx_busy,
                    rx_valid,
                    rx_data
                );

            end

        end

    end

endmodule