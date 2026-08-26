`default_nettype none

module core_top #(
    parameter logic [63:0] RESET_PC = 64'h0000_0000_8000_0000
) (
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

    // Debug
    output logic        halted,
    output logic [63:0] dbg_pc,
    output logic [31:0] dbg_ir,
    output logic [3:0]  dbg_state
);
    import riscv_pkg::*;

    // Frontend and FSM signals
    logic        if_start, if_busy, if_done, if_err;
    logic        pc_we;
    logic [63:0] pc_next;

    logic [63:0] pc_q;
    logic [31:0] ir_q;

    // Frontend bus outputs
    logic        fe_req_valid;
    logic [63:0] fe_req_addr;

    frontend #(.RESET_PC(RESET_PC)) u_fe (
        .clk         (clk),
        .reset       (reset),

        .if_start    (if_start),
        .if_busy     (if_busy),
        .if_done     (if_done),
        .if_err      (if_err),

        .pc_we       (pc_we),
        .pc_next     (pc_next),

        .pc_q        (pc_q),
        .ir_q        (ir_q),

        .req_valid   (fe_req_valid),
        .req_ready   (req_ready),
        .req_addr    (fe_req_addr),
        .req_is_write(),        // unused (frontend is read-only)
        .req_wdata   (),        // unused
        .req_wstrb   (),        // unused

        .resp_valid  (resp_valid),
        .resp_rdata  (resp_rdata),
        .resp_err    (resp_err)
    );

    // Decoder
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [63:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    logic [11:0] csr_addr;

    dec_uop_t uop;

    decoder u_dec (
        .inst   (ir_q),

        .opcode (opcode),
        .rd     (rd),
        .rs1    (rs1),
        .rs2    (rs2),
        .funct3 (funct3),
        .funct7 (funct7),

        .imm_i  (imm_i),
        .imm_s  (imm_s),
        .imm_b  (imm_b),
        .imm_u  (imm_u),
        .imm_j  (imm_j),

        .csr_addr (csr_addr),

        .uop    (uop)
    );

    // Regfile
    logic [4:0]  rf_rs1_addr, rf_rs2_addr;
    logic [63:0] rf_rs1_data, rf_rs2_data;

    logic        rf_we;
    logic [4:0]  rf_waddr;
    logic [63:0] rf_wdata;

    regfile u_rf (
        .clk      (clk),
        .reset    (reset),
        .rs1_addr (rf_rs1_addr),
        .rs2_addr (rf_rs2_addr),
        .rd_we    (rf_we),
        .rd_addr  (rf_waddr),
        .rd_wdata (rf_wdata),
        .rs1_data (rf_rs1_data),
        .rs2_data (rf_rs2_data)
    );

    // CSR file
    logic [11:0] csr_raddr;
    logic [63:0] csr_rdata;

    logic        csr_we;
    logic [11:0] csr_waddr;
    logic [63:0] csr_wdata;

    logic [63:0] mtvec;
    logic [63:0] mepc;

    logic        trap_we;
    logic [63:0] trap_pc;
    logic [63:0] trap_cause;
    logic [63:0] trap_value;

    logic mret_we;

    logic csr_valid;

    csr_file u_csr (
    .clk        (clk),
    .reset      (reset),

    .csr_raddr  (csr_raddr),
    .csr_we     (csr_we),
    .csr_waddr  (csr_waddr),
    .csr_wdata  (csr_wdata),
    .csr_rdata  (csr_rdata),

    .trap_we    (trap_we),
    .trap_pc    (trap_pc),
    .trap_cause (trap_cause),
    .trap_value (trap_value),

    .mtvec      (mtvec),
    .mepc       (mepc),

    .mret_we    (mret_we),

    .csr_valid  (csr_valid)
    );

    // Control FSM (arbitrates bus and controls FE/EXU/LSU)
    control_fsm u_fsm (
        .clk         (clk),
        .reset       (reset),

        // External unified bus (driven by FSM arbitration)
        .req_valid   (req_valid),
        .req_ready   (req_ready),
        .req_addr    (req_addr),
        .req_is_write(req_is_write),
        .req_wdata   (req_wdata),
        .req_wstrb   (req_wstrb),

        .resp_valid  (resp_valid),
        .resp_ready  (resp_ready),
        .resp_rdata  (resp_rdata),
        .resp_err    (resp_err),

        // Frontend
        .if_start    (if_start),
        .if_busy     (if_busy),
        .if_done     (if_done),
        .if_err      (if_err),

        .pc_we       (pc_we),
        .pc_next     (pc_next),
        .pc_q        (pc_q),
        .ir_q        (ir_q),

        // Frontend bus outputs
        .fe_req_valid(fe_req_valid),
        .fe_req_addr (fe_req_addr),

        // Decoder outputs
        .uop_d       (uop),
        .rd_d        (rd),
        .rs1_d       (rs1),
        .rs2_d       (rs2),
        .imm_i_d     (imm_i),
        .imm_s_d     (imm_s),
        .imm_b_d     (imm_b),
        .imm_u_d     (imm_u),
        .imm_j_d     (imm_j),

        // Regfile
        .rf_rs1_addr (rf_rs1_addr),
        .rf_rs2_addr (rf_rs2_addr),
        .rf_rs1_data (rf_rs1_data),
        .rf_rs2_data (rf_rs2_data),

        .rf_we       (rf_we),
        .rf_waddr    (rf_waddr),
        .rf_wdata    (rf_wdata),

        // CSR
        .csr_addr_d (csr_addr),

        .csr_raddr  (csr_raddr),
        .csr_rdata  (csr_rdata),

        .csr_we     (csr_we),
        .csr_waddr  (csr_waddr),
        .csr_wdata  (csr_wdata),

        // Traps
        .trap_we    (trap_we),
        .trap_pc    (trap_pc),
        .trap_cause (trap_cause),
        .trap_value (trap_value),

        .mtvec      (mtvec),
        .mepc       (mepc),
        
        .mret_we    (mret_we),

        .csr_valid  (csr_valid),

        // Debug
        .halted      (halted),
        .dbg_state   (dbg_state)
    );

    assign dbg_pc = pc_q;
    assign dbg_ir = ir_q;

endmodule

`default_nettype wire
