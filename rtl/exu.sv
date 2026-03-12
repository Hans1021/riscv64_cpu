`default_nettype none

module exu (
    input  logic [63:0] pc,

    input  logic [63:0] rs1_data,
    input  logic [63:0] rs2_data,

    input  logic [63:0] imm_i,
    input  logic [63:0] imm_s,
    input  logic [63:0] imm_u,

    input  riscv_pkg::dec_uop_t uop,

    output logic [63:0] exu_y,
    output logic        br_take,
    output logic [63:0] jalr_target
);
    import riscv_pkg::*;

    logic [63:0] src_a, src_b;
    logic [63:0] alu_y;
    logic [63:0] md_y;

    // Operand select
    always_comb begin
        src_a = 64'd0;
        src_b = 64'd0;

        unique case (uop.srca_sel)
            SRCA_RS1: src_a = rs1_data;
            SRCA_PC:  src_a = pc;
        endcase

        unique case (uop.srcb_sel)
            SRCB_RS2:   src_b = rs2_data;
            SRCB_IMM_I: src_b = imm_i;
            SRCB_IMM_S: src_b = imm_s;
            SRCB_IMM_U: src_b = imm_u;
        endcase
    end

    alu u_alu (
        .a  (src_a),
        .b  (src_b),
        .op (uop.alu_op),
        .y  (alu_y)
    );

    muldiv u_muldiv (
        .a  (src_a),
        .b  (src_b),
        .op (uop.md_op),
        .y  (md_y)
    );

    // Result select
    always_comb begin
        exu_y = 64'd0;

        unique case (uop.kind)
            IK_ALU:    exu_y = alu_y;
            IK_MD:     exu_y = md_y;
            IK_LUI:    exu_y = imm_u;
            IK_AUIPC:  exu_y = pc + imm_u;
            IK_LOAD:   exu_y = alu_y;
            IK_STORE:  exu_y = alu_y;
            IK_JALR:   exu_y = alu_y;
            default:   exu_y = 64'd0;
        endcase
    end

    // Branch decision
    always_comb begin
        unique case (uop.br_op)
            BR_EQ: br_take = (rs1_data == rs2_data);
            BR_NE: br_take = (rs1_data != rs2_data);
            BR_LT: br_take = ($signed(rs1_data) <  $signed(rs2_data));
            BR_GE: br_take = ($signed(rs1_data) >= $signed(rs2_data));
            BR_LTU: br_take = (rs1_data <  rs2_data);
            BR_GEU: br_take = (rs1_data >= rs2_data);
            default: br_take = 1'b0;
        endcase
    end

    // JALR target (bit 0 cleared)
    assign jalr_target = ((rs1_data + imm_i) & ~64'b1);

endmodule

`default_nettype wire
