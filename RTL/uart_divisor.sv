module uart_divisor (
    input  logic        clk,
    input  logic        rst_n,

    // DLL interface
    input  logic        dll_wr_en,
    input  logic [7:0]  dll_wr_data,

    // DLM interface
    input  logic        dlm_wr_en,
    input  logic [7:0]  dlm_wr_data,

    // Combined 16-bit divisor
    output logic [15:0] divisor,

    // Individual registers
    output logic [7:0] dll,
    output logic [7:0] dlm
);

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            dll <= 8'h01;
            dlm <= 8'h00;
        end

        else begin

            if (dll_wr_en)
                dll <= dll_wr_data;

            if (dlm_wr_en)
                dlm <= dlm_wr_data;

        end

    end

    // Combine DLM and DLL
    assign divisor = {dlm, dll};

endmodule