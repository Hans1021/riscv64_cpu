`default_nettype wire

module top (
    input  logic        clk,
    input  logic        reset,

    // Expose SoC bus to C++ test
    input  logic        req_valid,
    output logic        req_ready,
    input  logic [63:0] req_addr,
    input  logic        req_is_write,
    input  logic [63:0] req_wdata,
    input  logic [7:0]  req_wstrb,

    output logic        resp_valid,
    input  logic        resp_ready,
    output logic [63:0] resp_rdata,
    output logic        resp_err,

    output logic [63:0] cycle_count
);

    always_ff @(posedge clk) begin
        if (reset) cycle_count <= 64'd0;
        else       cycle_count <= cycle_count + 64'd1;
    end

    soc u_soc (
        .clk        (clk),
        .reset      (reset),

        .req_valid  (req_valid),
        .req_ready  (req_ready),
        .req_addr   (req_addr),
        .req_is_write(req_is_write),
        .req_wdata  (req_wdata),
        .req_wstrb  (req_wstrb),

        .resp_valid (resp_valid),
        .resp_ready (resp_ready),
        .resp_rdata (resp_rdata),
        .resp_err   (resp_err)
    );

endmodule

`default_nettype wire