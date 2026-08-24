`default_nettype none

module csr_file (
    input logic clk, reset,

    input logic [11:0]  csr_raddr,
    input logic         csr_we,
    input logic [11:0]  csr_waddr,
    input logic [63:0]  csr_wdata,

    output logic [63:0] csr_rdata,

    input logic         trap_we,
    input logic [63:0]  trap_pc,
    input logic [63:0]  trap_cause,
    input logic [63:0]  trap_value,

    output logic [63:0] mtvec,
    output logic [63:0] mepc
);

    logic [63:0] mstatus_q;
    logic [63:0] mtvec_q;
    logic [63:0] mscratch_q;
    logic [63:0] mepc_q;
    logic [63:0] mcause_q;
    logic [63:0] mtval_q;

    always_ff @(posedge clk) begin
        if (reset) begin
            mstatus_q   <= 64'b0;
            mtvec_q     <= 64'b0;
            mscratch_q  <= 64'b0;
            mepc_q      <= 64'b0;
            mcause_q    <= 64'b0;
            mtval_q     <= 64'b0;
        end else if (trap_we) begin
            mepc_q      <= trap_pc;
            mcause_q    <= trap_cause;
            mtval_q     <= trap_value;
        end else if (csr_we) begin
            case (csr_waddr)
                12'h300: mstatus_q  <= csr_wdata;
                12'h305: mtvec_q    <= csr_wdata;
                12'h340: mscratch_q <= csr_wdata;
                12'h341: mepc_q     <= csr_wdata;
                12'h342: mcause_q   <= csr_wdata;
                12'h343: mtval_q    <= csr_wdata;
                default: ;
            endcase
        end
    end

    always_comb begin
        case (csr_raddr)
            12'h300: csr_rdata = mstatus_q;
            12'h305: csr_rdata = mtvec_q;
            12'h340: csr_rdata = mscratch_q;
            12'h341: csr_rdata = mepc_q;
            12'h342: csr_rdata = mcause_q;
            12'h343: csr_rdata = mtval_q;
            default: csr_rdata = 64'd0;
        endcase

        mtvec   = mtvec_q
        mepc    = mepc_q
    end

endmodule

`default_nettype wire