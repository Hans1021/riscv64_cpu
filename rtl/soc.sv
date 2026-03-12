`default_nettype none

module soc #(
    parameter logic [63:0] RAM_BASE         = 64'h0000_0000_8000_0000,
    parameter logic [63:0] RAM_SIZE_BYTES   = 64'h0000_0000_0010_0000,
    parameter int          RAM_DEPTH_WORDS  = 131072
) (
    input  logic        clk,
    input  logic        reset,

    // CPU <-> SoC bus
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [63:0] req_addr,
    input  logic        req_is_write,
    input  logic [63:0] req_wdata,
    input  logic [7:0]  req_wstrb,

    output logic        resp_valid,
    input  logic        resp_ready,
    output logic [63:0] resp_rdata,
    output logic        resp_err
);

    // Address decode
    logic ram_sel;
    assign ram_sel = (req_addr >= RAM_BASE) && (req_addr < (RAM_BASE + RAM_SIZE_BYTES));

    logic [63:0] ram_addr;
    assign ram_addr = req_addr - RAM_BASE;


    // RAM wires
    logic        ram_req_valid, ram_req_ready;
    logic [63:0] ram_req_addr;
    logic        ram_req_is_write;
    logic [63:0] ram_req_wdata;
    logic [7:0]  ram_req_wstrb;

    logic        ram_resp_valid, ram_resp_ready;
    logic [63:0] ram_resp_rdata;
    logic        ram_resp_err;

    // Only drive RAM when selected
    assign ram_req_valid    = req_valid && ram_sel;
    assign ram_req_addr     = ram_addr;
    assign ram_req_is_write = req_is_write;
    assign ram_req_wdata    = req_wdata;
    assign ram_req_wstrb    = req_wstrb;

    assign ram_resp_ready   = resp_ready; // if response is from RAM

    logic unmapped_resp_valid;

    assign req_ready = (!unmapped_resp_valid) && ram_req_ready;

    logic req_fire;
    assign req_fire = req_valid && req_ready;

    // Hold error until accepted
    always_ff @(posedge clk) begin
        if (reset) begin
            unmapped_resp_valid <= 1'b0;
        end else begin
            if (unmapped_resp_valid && resp_ready) begin
                unmapped_resp_valid <= 1'b0;
            end

            if (req_fire && !ram_sel) begin
                unmapped_resp_valid <= 1'b1;
            end
        end
    end

    // RAM vs unmapped error
    always_comb begin
        if (unmapped_resp_valid) begin
            resp_valid = 1'b1;
            resp_err   = 1'b1;
            resp_rdata = 64'b0;
        end else begin
            resp_valid = ram_resp_valid;
            resp_err   = ram_resp_err;
            resp_rdata = ram_resp_rdata;
        end
    end

    ram #(.DEPTH_WORDS(RAM_DEPTH_WORDS)) u_ram (
        .clk        (clk),
        .reset      (reset),

        .req_valid  (ram_req_valid),
        .req_ready  (ram_req_ready),
        .req_addr   (ram_req_addr),
        .req_is_write(ram_req_is_write),
        .req_wdata  (ram_req_wdata),
        .req_wstrb  (ram_req_wstrb),

        .resp_valid (ram_resp_valid),
        .resp_ready (ram_resp_ready),
        .resp_rdata (ram_resp_rdata),
        .resp_err   (ram_resp_err)
    );

endmodule

`default_nettype wire
