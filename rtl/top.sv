`default_nettype none

module top (
    input  logic        clk,
    input  logic        reset,

    output logic        halted,
    output logic [63:0] dbg_pc,
    output logic [31:0] dbg_ir,
    output logic [3:0]  dbg_state
);
    // Core <-> SoC bus
    logic        req_valid;
    logic        req_ready;
    logic [63:0] req_addr;
    logic        req_is_write;
    logic [63:0] req_wdata;
    logic [7:0]  req_wstrb;

    logic        resp_valid;
    logic        resp_ready;
    logic [63:0] resp_rdata;
    logic        resp_err;

    core_top u_core (
        .clk          (clk),
        .reset        (reset),

        .req_valid    (req_valid),
        .req_ready    (req_ready),
        .req_addr     (req_addr),
        .req_is_write (req_is_write),
        .req_wdata    (req_wdata),
        .req_wstrb    (req_wstrb),

        .resp_valid   (resp_valid),
        .resp_ready   (resp_ready),
        .resp_rdata   (resp_rdata),
        .resp_err     (resp_err),

        .halted       (halted),
        .dbg_pc       (dbg_pc),
        .dbg_ir       (dbg_ir),
        .dbg_state    (dbg_state)
    );

    soc u_soc (
        .clk          (clk),
        .reset        (reset),

        .req_valid    (req_valid),
        .req_ready    (req_ready),
        .req_addr     (req_addr),
        .req_is_write (req_is_write),
        .req_wdata    (req_wdata),
        .req_wstrb    (req_wstrb),

        .resp_valid   (resp_valid),
        .resp_ready   (resp_ready),
        .resp_rdata   (resp_rdata),
        .resp_err     (resp_err)
    );

endmodule

`default_nettype wire
