module uart_tx_fifo #(
    parameter int DATA_WIDTH  = 8,
    parameter int FIFO_DEPTH  = 16,
    parameter int CLOCK_FREQ  = 50_000_000,
    parameter int BAUD_RATE   = 115_200
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Host interface
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    // UART output
    output logic                  txd,
    output logic                  tx_busy
);

    // =====================================================
    // Baud generator
    // =====================================================

    logic baud_tick;

    uart_baud_gen #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) baud_gen (
        .clk       (clk),
        .rst_n     (rst_n),
        .baud_tick (baud_tick)
    );

    // =====================================================
    // FIFO signals
    // =====================================================

    logic                  fifo_rd_en;
    logic [DATA_WIDTH-1:0] fifo_rd_data;
    logic                  fifo_empty;

    // =====================================================
    // UART TX signals
    // =====================================================

    logic                  tx_start;
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  tx_done;

    // =====================================================
    // TX FIFO
    // =====================================================

    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (FIFO_DEPTH)
    ) tx_fifo (
        .clk     (clk),
        .rst_n   (rst_n),

        .wr_en   (wr_en),
        .wr_data (wr_data),

        .rd_en   (fifo_rd_en),
        .rd_data (fifo_rd_data),

        .full    (full),
        .empty   (fifo_empty),

        .count   ()
    );

    // =====================================================
    // UART TX
    // =====================================================

    uart_tx tx_unit (
        .clk       (clk),
        .rst_n     (rst_n),

        .baud_tick (baud_tick),

        .tx_start  (tx_start),
        .tx_data   (tx_data),

        .txd       (txd),
        .tx_busy   (tx_busy),
        .tx_done   (tx_done)
    );

    // =====================================================
    // TX FIFO Controller
    // =====================================================

    typedef enum logic [1:0] {
        TX_FIFO_IDLE,
        TX_FIFO_LOAD,
        TX_FIFO_SEND
    } state_t;

    state_t state;

    // =====================================================
    // Controller
    // =====================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state      <= TX_FIFO_IDLE;
            fifo_rd_en <= 1'b0;
            tx_start   <= 1'b0;
            tx_data    <= '0;
        end

        else begin

            // Default: one-cycle pulses
            fifo_rd_en <= 1'b0;
            tx_start   <= 1'b0;

            case (state)

                // -----------------------------------------
                // Wait for FIFO data
                // -----------------------------------------

                TX_FIFO_IDLE: begin

                    if (!fifo_empty && !tx_busy) begin

                        // Read one byte from FIFO
                        fifo_rd_en <= 1'b1;

                        state <= TX_FIFO_LOAD;
                    end

                end

                // -----------------------------------------
                // Load FIFO data into TX
                // -----------------------------------------

                TX_FIFO_LOAD: begin

                    tx_data <= fifo_rd_data;

                    // Start UART transmission
                    tx_start <= 1'b1;

                    state <= TX_FIFO_SEND;

                end

                // -----------------------------------------
                // Wait for transmission completion
                // -----------------------------------------

                TX_FIFO_SEND: begin

                    if (tx_done) begin
                        state <= TX_FIFO_IDLE;
                    end

                end

                default: begin
                    state <= TX_FIFO_IDLE;
                end

            endcase

        end
    end

endmodule