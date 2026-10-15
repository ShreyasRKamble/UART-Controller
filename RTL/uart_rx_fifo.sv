module uart_rx_fifo #(
    parameter int DATA_WIDTH  = 8,
    parameter int FIFO_DEPTH  = 16,
    parameter int CLOCK_FREQ  = 50_000_000,
    parameter int BAUD_RATE   = 115_200
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Host read interface
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty,

    // UART input
    input  logic                  rxd,

    // Status
    output logic                  full,
    output logic                  rx_valid,
    output logic                  framing_error
);

    // =====================================================
    // 16x baud/sample tick
    // =====================================================

    logic sample_tick;

    uart_baud_gen_16x #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) baud_gen (
        .clk        (clk),
        .rst_n      (rst_n),
        .sample_tick(sample_tick)
    );

    // =====================================================
    // UART RX signals
    // =====================================================

    logic [7:0] rx_data;
    logic       rx_busy;

    // =====================================================
    // UART RX
    // =====================================================

    uart_rx_16x rx_unit (
        .clk          (clk),
        .rst_n        (rst_n),
        .sample_tick  (sample_tick),

        .rxd          (rxd),

        .rx_data      (rx_data),
        .rx_valid     (rx_valid),
        .rx_busy      (rx_busy),
        .framing_error(framing_error)
    );

    // =====================================================
    // RX FIFO signals
    // =====================================================

    logic fifo_wr_en;

    // =====================================================
    // RX FIFO
    // =====================================================

    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (FIFO_DEPTH)
    ) rx_fifo (
        .clk     (clk),
        .rst_n   (rst_n),

        .wr_en   (fifo_wr_en),
        .wr_data (rx_data),

        .rd_en   (rd_en),
        .rd_data (rd_data),

        .full    (full),
        .empty   (empty),

        .count   ()
    );

    // =====================================================
    // Write received byte into FIFO
    // =====================================================

    always_comb begin

        if (rx_valid && !full)
            fifo_wr_en = 1'b1;
        else
            fifo_wr_en = 1'b0;

    end

endmodule