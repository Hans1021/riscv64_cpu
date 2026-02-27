`default_nettype none

module control_fsm (
    input  logic        clk,
    input  logic        reset,

    // Unified bus (core -> SoC)
    output logic        req_valid,
    input  logic        req_ready,
    output logic [63:0] req_addr,
    output logic        req_is_write,
    output logic [63:0] req_wdata,
    output logic [7:0]  req_wstrb,

    input  logic        resp_valid,
    output logic        resp_ready,
    input  logic [63:0] resp_rdata,
    input  logic        resp_err,

    // Frontend control/status
    output logic        if_start,
    input  logic        if_busy,
    input  logic        if_done,
    input  logic        if_err,

    output logic        pc_we,
    output logic [63:0] pc_next,
    input  logic [63:0] pc_q,
    input  logic [31:0] ir_q,

    // Frontend bus outputs (for arbitration)
    input  logic        fe_req_valid,
    input  logic [63:0] fe_req_addr,

    // From decoder (driven by current IR)
    input  riscv_pkg::dec_uop_t uop_d,
    input  logic [4:0]          rd_d,
    input  logic [4:0]          rs1_d,
    input  logic [4:0]          rs2_d,
    input  logic [63:0]         imm_i_d,
    input  logic [63:0]         imm_s_d,
    input  logic [63:0]         imm_b_d,
    input  logic [63:0]         imm_u_d,
    input  logic [63:0]         imm_j_d,

    // Regfile
    output logic [4:0]  rf_rs1_addr,
    output logic [4:0]  rf_rs2_addr,
    input  logic [63:0] rf_rs1_data,
    input  logic [63:0] rf_rs2_data,

    output logic        rf_we,
    output logic [4:0]  rf_waddr,
    output logic [63:0] rf_wdata,

    // Debug
    output logic        halted,
    output logic [3:0]  dbg_state
);
    import riscv_pkg::*;
    assign resp_ready = 1'b1;

    typedef enum logic [3:0] {
        S_RESET   = 4'd0,
        S_IFETCH  = 4'd1,
        S_DECODE  = 4'd2,
        S_MEM     = 4'd3,
        S_EXEC    = 4'd4,
        S_HALT    = 4'd15
    } state_t;

    state_t st_q, st_d;
    assign dbg_state = st_q;

    // latch decoded bundle
    dec_uop_t uop_q;
    logic [4:0]  rd_q_l, rs1_q_l, rs2_q_l;
    logic [63:0] imm_i_q, imm_s_q, imm_b_q, imm_u_q, imm_j_q;

    // regfile read addrs from current IR
    assign rf_rs1_addr = rs1_d;
    assign rf_rs2_addr = rs2_d;

    // EXU
    logic [63:0] exu_alu_y;
    logic        exu_br_take;
    logic [63:0] exu_jalr_target;

    exu u_exu (
        .pc          (pc_q),
        .rs1_data    (rf_rs1_data),
        .rs2_data    (rf_rs2_data),
        .imm_i       (imm_i_q),
        .imm_s       (imm_s_q),
        .imm_u       (imm_u_q),
        .uop         (uop_q),
        .alu_y       (exu_alu_y),
        .br_take     (exu_br_take),
        .jalr_target (exu_jalr_target)
    );

    // LSU
    logic        lsu_issue, lsu_is_store;
    logic [63:0] lsu_addr, lsu_store_data;
    mem_size_t   lsu_size;
    logic        lsu_unsigned;
    logic        lsu_busy, lsu_done, lsu_err;
    logic [63:0] lsu_load_data;

    logic        lsu_req_valid;
    logic [63:0] lsu_req_addr;
    logic        lsu_req_is_write;
    logic [63:0] lsu_req_wdata;
    logic [7:0]  lsu_req_wstrb;

    lsu u_lsu (
        .clk          (clk),
        .reset        (reset),

        .issue        (lsu_issue),
        .is_store     (lsu_is_store),
        .addr         (lsu_addr),
        .store_data   (lsu_store_data),
        .mem_size     (lsu_size),
        .mem_unsigned (lsu_unsigned),

        .busy         (lsu_busy),
        .done         (lsu_done),
        .load_data    (lsu_load_data),
        .err          (lsu_err),

        .req_valid    (lsu_req_valid),
        .req_ready    (req_ready),
        .req_addr     (lsu_req_addr),
        .req_is_write (lsu_req_is_write),
        .req_wdata    (lsu_req_wdata),
        .req_wstrb    (lsu_req_wstrb),

        .resp_valid   (resp_valid),
        .resp_rdata   (resp_rdata),
        .resp_err     (resp_err)
    );

    // ----------------------------
    // Bus arbitration: FE in IFETCH, LSU in MEM, else idle
    // ----------------------------
    always_comb begin
        req_valid    = 1'b0;
        req_addr     = 64'd0;
        req_is_write = 1'b0;
        req_wdata    = 64'd0;
        req_wstrb    = 8'd0;

        if (st_q == S_IFETCH) begin
            req_valid    = fe_req_valid;
            req_addr     = fe_req_addr;
            req_is_write = 1'b0;
            req_wdata    = 64'd0;
            req_wstrb    = 8'd0;
        end else if (st_q == S_MEM) begin
            req_valid    = lsu_req_valid;
            req_addr     = lsu_req_addr;
            req_is_write = lsu_req_is_write;
            req_wdata    = lsu_req_wdata;
            req_wstrb    = lsu_req_wstrb;
        end
    end

    // ----------------------------
    // Control outputs + next state
    // ----------------------------
    always_comb begin
        st_d   = st_q;
        halted = 1'b0;

        // frontend controls
        if_start = 1'b0;
        pc_we    = 1'b0;
        pc_next  = pc_q;

        // regfile write defaults
        rf_we    = 1'b0;
        rf_waddr = rd_q_l;
        rf_wdata = 64'd0;

        // lsu defaults
        lsu_issue      = 1'b0;
        lsu_is_store   = 1'b0;
        lsu_addr       = 64'd0;
        lsu_store_data = rf_rs2_data;
        lsu_size       = uop_q.mem_size;
        lsu_unsigned   = uop_q.mem_unsigned;

        unique case (st_q)
            S_RESET: begin
                st_d = S_IFETCH;
            end

            // Start + wait for frontend fetch to complete
            S_IFETCH: begin
                if (!if_busy) if_start = 1'b1;
                if (if_done) begin
                    if (if_err) st_d = S_HALT;
                    else        st_d = S_DECODE;
                end
            end

            S_DECODE: begin
                if (uop_d.kind == IK_ILLEGAL) begin
                    st_d = S_HALT;
                end else if (uop_d.kind == IK_SYSTEM) begin
                    if (uop_d.is_fence) st_d = S_EXEC; // NOP-like
                    else                st_d = S_HALT; // ECALL/EBREAK now
                end else if (uop_d.kind == IK_LOAD || uop_d.kind == IK_STORE) begin
                    st_d = S_MEM;
                end else begin
                    st_d = S_EXEC;
                end
            end

            S_MEM: begin
                if (!lsu_busy) begin
                    lsu_issue      = 1'b1;
                    lsu_is_store   = (uop_q.kind == IK_STORE);
                    lsu_addr       = exu_alu_y; // rs1 + imm_i/imm_s
                    lsu_store_data = rf_rs2_data;
                    lsu_size       = uop_q.mem_size;
                    lsu_unsigned   = uop_q.mem_unsigned;
                end

                if (lsu_done) begin
                    if (lsu_err) begin
                        st_d = S_HALT;
                    end else begin
                        if (uop_q.kind == IK_LOAD && uop_q.reg_write) begin
                            rf_we    = 1'b1;
                            rf_waddr = rd_q_l;
                            rf_wdata = lsu_load_data;
                        end
                        st_d = S_EXEC;
                    end
                end
            end

            S_EXEC: begin
                // writeback for non-loads
                if (uop_q.reg_write && uop_q.kind != IK_LOAD) begin
                    rf_we    = 1'b1;
                    rf_waddr = rd_q_l;
                    unique case (uop_q.wb_sel)
                        WB_ALU:   rf_wdata = exu_alu_y;
                        WB_PC4:   rf_wdata = pc_q + 64'd4;
                        WB_IMM_U: rf_wdata = imm_u_q;
                        default:  rf_wdata = 64'd0;
                    endcase
                end

                // compute next PC and commit to frontend
                pc_we = 1'b1;
                unique case (uop_q.pc_sel)
                    PC_PC4: pc_next = pc_q + 64'd4;

                    PC_PC_IMM: begin
                        if (uop_q.kind == IK_JAL) begin
                            pc_next = pc_q + imm_j_q;
                        end else if (uop_q.kind == IK_BRANCH) begin
                            pc_next = exu_br_take ? (pc_q + imm_b_q) : (pc_q + 64'd4);
                        end else begin
                            pc_next = pc_q + 64'd4;
                        end
                    end

                    PC_ALU: begin
                        if (uop_q.kind == IK_JALR) pc_next = exu_jalr_target;
                        else                       pc_next = exu_alu_y;
                    end

                    default: pc_next = pc_q + 64'd4;
                endcase

                st_d = S_IFETCH;
            end

            S_HALT: begin
                halted = 1'b1;
                st_d   = S_HALT;
            end

            default: st_d = S_HALT;
        endcase
    end

    // ----------------------------
    // Sequential: latch decode bundle
    // ----------------------------
    always_ff @(posedge clk) begin
        if (reset) begin
            st_q    <= S_RESET;

            uop_q   <= '0;
            rd_q_l  <= 5'd0;
            rs1_q_l <= 5'd0;
            rs2_q_l <= 5'd0;

            imm_i_q <= 64'd0;
            imm_s_q <= 64'd0;
            imm_b_q <= 64'd0;
            imm_u_q <= 64'd0;
            imm_j_q <= 64'd0;
        end else begin
            st_q <= st_d;

            if (st_q == S_DECODE) begin
                uop_q   <= uop_d;
                rd_q_l  <= rd_d;
                rs1_q_l <= rs1_d;
                rs2_q_l <= rs2_d;

                imm_i_q <= imm_i_d;
                imm_s_q <= imm_s_d;
                imm_b_q <= imm_b_d;
                imm_u_q <= imm_u_d;
                imm_j_q <= imm_j_d;
            end
        end
    end

endmodule

`default_nettype wire
