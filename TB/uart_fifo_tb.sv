`timescale 1ns/1ps

module uart_fifo_tb;

    // =====================================================
    // PARAMETERS
    // =====================================================

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;


    // =====================================================
    // SIGNALS
    // =====================================================

    logic                  clk;
    logic                  rst_n;

    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;

    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;

    logic                  full;
    logic                  empty;

    logic [$clog2(DEPTH+1)-1:0] count;


    // =====================================================
    // DUT
    // =====================================================

    uart_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) dut (
        .clk     (clk),
        .rst_n   (rst_n),

        .wr_en   (wr_en),
        .wr_data (wr_data),

        .rd_en   (rd_en),
        .rd_data (rd_data),

        .full    (full),
        .empty   (empty),
        .count   (count)
    );


    // =====================================================
    // CLOCK
    // =====================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // =====================================================
    // WRITE TASK
    // =====================================================

    task write_fifo(input logic [7:0] data);

        begin

            @(posedge clk);

            wr_en   = 1'b1;
            wr_data = data;

            @(posedge clk);

            wr_en   = 1'b0;
            wr_data = 8'h00;

        end

    endtask


    // =====================================================
    // READ TASK
    // =====================================================

    task read_fifo;

        begin

            @(posedge clk);

            rd_en = 1'b1;

            @(posedge clk);

            rd_en = 1'b0;

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        // -------------------------------------------------
        // INITIAL VALUES
        // -------------------------------------------------

        rst_n   = 1'b0;

        wr_en   = 1'b0;
        wr_data = 8'h00;

        rd_en   = 1'b0;


        // -------------------------------------------------
        // RESET
        // -------------------------------------------------

        #20;

        rst_n = 1'b1;

        #20;


        $display("");
        $display("========================================");
        $display("          UART FIFO TEST");
        $display("========================================");


        // =================================================
        // TEST 1: RESET
        // =================================================

        $display("");
        $display("TEST 1: RESET");

        if (empty && !full && count == 0) begin

            $display("RESET TEST PASSED");

        end

        else begin

            $display("RESET TEST FAILED");

        end


        // =================================================
        // TEST 2: WRITE THREE BYTES
        // =================================================

        $display("");
        $display("TEST 2: WRITE DATA");

        write_fifo(8'h41);
        write_fifo(8'h55);
        write_fifo(8'hAA);

        #10;

        $display("COUNT = %0d", count);

        if (count == 3) begin

            $display("WRITE TEST PASSED");

        end

        else begin

            $display("WRITE TEST FAILED");

        end


        // =================================================
        // TEST 3: READ THREE BYTES
        // =================================================

        $display("");
        $display("TEST 3: READ DATA");

        read_fifo;

        #1;

        $display("READ DATA = 0x%02h", rd_data);

        if (rd_data == 8'h41) begin
            $display("READ 1 PASSED");
        end
        else begin
            $display("READ 1 FAILED");
        end


        read_fifo;

        #1;

        $display("READ DATA = 0x%02h", rd_data);

        if (rd_data == 8'h55) begin
            $display("READ 2 PASSED");
        end
        else begin
            $display("READ 2 FAILED");
        end


        read_fifo;

        #1;

        $display("READ DATA = 0x%02h", rd_data);

        if (rd_data == 8'hAA) begin
            $display("READ 3 PASSED");
        end
        else begin
            $display("READ 3 FAILED");
        end


        // =================================================
        // TEST 4: EMPTY
        // =================================================

        #10;

        $display("");
        $display("TEST 4: EMPTY");

        if (empty && count == 0) begin

            $display("EMPTY TEST PASSED");

        end

        else begin

            $display("EMPTY TEST FAILED");

        end


        // =================================================
        // TEST 5: FILL FIFO
        // =================================================

        $display("");
        $display("TEST 5: FILL FIFO");

        for (int i = 0; i < DEPTH; i = i + 1) begin

            write_fifo(i);

        end

        #10;

        $display("COUNT = %0d", count);
        $display("FULL  = %b", full);

        if (full && count == DEPTH) begin

            $display("FULL TEST PASSED");

        end

        else begin

            $display("FULL TEST FAILED");

        end


        // =================================================
        // TEST 6: ATTEMPT OVERFLOW
        // =================================================

        $display("");
        $display("TEST 6: OVERFLOW PROTECTION");

        write_fifo(8'hFF);

        #10;

        if (count == DEPTH) begin

            $display("OVERFLOW PROTECTION PASSED");

        end

        else begin

            $display("OVERFLOW PROTECTION FAILED");

        end


        // =================================================
        // TEST 7: EMPTY FIFO AGAIN
        // =================================================

        $display("");
        $display("TEST 7: EMPTY FIFO");

        for (int i = 0; i < DEPTH; i = i + 1) begin

            read_fifo;

        end

        #10;

        $display("COUNT = %0d", count);
        $display("EMPTY = %b", empty);

        if (empty && count == 0) begin

            $display("EMPTY FIFO TEST PASSED");

        end

        else begin

            $display("EMPTY FIFO TEST FAILED");

        end


        // =================================================
        // TEST 8: UNDERFLOW PROTECTION
        // =================================================

        $display("");
        $display("TEST 8: UNDERFLOW PROTECTION");

        read_fifo;

        #10;

        if (count == 0) begin

            $display("UNDERFLOW PROTECTION PASSED");

        end

        else begin

            $display("UNDERFLOW PROTECTION FAILED");

        end


        // =================================================
        // COMPLETE
        // =================================================

        $display("");
        $display("========================================");
        $display("          FIFO TEST COMPLETE");
        $display("========================================");


        #20;

        $stop;

    end

endmodule