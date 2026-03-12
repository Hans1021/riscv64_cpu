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
    
    // Load program

    string memfile;

    initial begin
        if ($value$plusargs("mem=%s", memfile)) begin
            $display("RAM: loading hex from %s", memfile);
            $readmemh(memfile, mem);
            $display("%h", mem[0]);
        end else begin
            $display("RAM: no +mem=<file> provided; memory uninitialized");
        end
    end

    logic [IDX_W-1:0] idx;
    assign idx = req_addr[ADDR_LSB + IDX_W - 1 : ADDR_LSB];

    // For 1-cycle response
    logic        pend_q;
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
            rd_q       <= 1'b0;
            rd_idx_q   <= '0;
        end else begin
            // Default: drop if response is accepted
            if (resp_valid && resp_ready) begin
                resp_valid <= 1'b0;
                resp_err   <= 1'b0;
            end

            // Launch request
            if (req_fire) begin
                rd_q     <= !req_is_write;
                rd_idx_q <= idx;

                pend_q   <= !req_is_write;

                // Write immediately
                if (req_is_write) begin
                    for (int b = 0; b < 8; b++) begin
                        if (req_wstrb[b]) begin
                            mem[idx][8*b +: 8] <= req_wdata[8*b +: 8];
                        end
                    end
                end
            end else begin
                pend_q <= 1'b0;
            end

            // Respond one cycle after req_fire
            if (pend_q) begin
                resp_valid <= 1'b1;
                resp_err   <= 1'b0;
                resp_rdata <= mem[rd_idx_q];
            end
        end
    end

    
endmodule

`default_nettype wire
