`default_nettype none

module ram #(
    parameter int DEPTH_WORDS = 131072
) (
    input logic         clk,
    input logic         reset,

    input logic         req_valid,
    output logic        req_ready,

    input logic [63:0]  req_addr,
    input logic         req_is_write,
    input logic [63:0]  req_wdata,
    input logic [7:0]   req_wstrb,

    output logic        resp_valid,
    input logic         resp_ready,
    output logic [63:0] resp_rdata,
    output logic        resp_err
);

    localparam int ADDR_LSB = 3; // 8-byte alignment
    localparam int IDX_W = $clog2(DEPTH_WORDS);

    logic [63:0] mem [0:DEPTH_WORDS-1];

    logic bad_align;
    assign bad_align = |req_addr[2:0];

    logic [IDX_W-1:0] idx;
    assign idx = req_addr[ADDR_LSB + IDX_W - 1 : ADDR_LSB];

    logic unused_addr_hi;
    assign unused_addr_hi = |req_addr[63 : (ADDR_LSB + IDX_W)];

    // Pipeline regs for 1-cycle response
    logic        pend_q;
    logic        err_q;
    logic        rd_q;
    logic [IDX_W-1:0] rd_idx_q;

    assign req_ready = !resp_valid && !pend_q;

    logic req_fire;
    assign req_fire = req_valid & req_ready;

    always_ff @(posedge clk) begin
        if (reset) begin
            resp_valid <= 1'b0;
            resp_rdata <= 64'b0;
            resp_err   <= 1'b0;
            pend_q     <= 1'b0;
            err_q      <= 1'b0;
            rd_q       <= 1'b0;
            rd_idx_q   <= '0;
        end else begin
            // Default: if response is accepted, drop it
            if (resp_valid && resp_ready) begin
                resp_valid <= 1'b0;
                resp_err   <= 1'b0;
            end

            // Launch a request (only when resp_valid=0 due to req_ready)
            if (req_fire) begin
                err_q    <= bad_align;
                rd_q     <= !req_is_write && !bad_align;
                rd_idx_q <= idx;
                pend_q   <= 1'b1;

                // Perform write immediately (still respond next cycle)
                if (req_is_write && !bad_align) begin
                    for (int b = 0; b < 8; b++) begin
                        if (req_wstrb[b]) begin
                            mem[idx][8*b +: 8] <= req_wdata[8*b +: 8];
                        end
                    end
                end
            end else begin
                pend_q <= 1'b0;
            end

            // Generate response one cycle after req_fire
            if (pend_q) begin
                resp_valid <= 1'b1;
                resp_err   <= err_q;
                resp_rdata <= (rd_q) ? mem[rd_idx_q] : 64'b0;
            end
        end
    end

    
endmodule

`default_nettype wire