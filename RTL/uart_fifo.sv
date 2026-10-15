module uart_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst_n,

    // Write interface
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    // Read interface
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    // Status
    output logic                  full,
    output logic                  empty,
    output logic [$clog2(DEPTH+1)-1:0] count
);

    // =====================================================
    // FIFO MEMORY
    // =====================================================

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // =====================================================
    // POINTERS
    // =====================================================

    logic [$clog2(DEPTH)-1:0] wr_ptr;
    logic [$clog2(DEPTH)-1:0] rd_ptr;

    // =====================================================
    // FIFO STATUS
    // =====================================================

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    // =====================================================
    // FIFO OPERATION
    // =====================================================

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;

        end

        else begin

            // -------------------------------------------------
            // WRITE
            // -------------------------------------------------

            if (wr_en && !full) begin

                mem[wr_ptr] <= wr_data;

                wr_ptr <= wr_ptr + 1'b1;

            end


            // -------------------------------------------------
            // READ
            // -------------------------------------------------

            if (rd_en && !empty) begin

                rd_data <= mem[rd_ptr];

                rd_ptr <= rd_ptr + 1'b1;

            end


            // -------------------------------------------------
            // COUNT
            // -------------------------------------------------

            case ({wr_en && !full, rd_en && !empty})

                2'b10: begin
                    count <= count + 1'b1;
                end

                2'b01: begin
                    count <= count - 1'b1;
                end

                default: begin
                    count <= count;
                end

            endcase

        end

    end

endmodule