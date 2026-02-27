`default_nettype none

module exu (
    input  logic [63:0] pc,

    input  logic [63:0] rs1_data,
    input  logic [63:0] rs2_data,

    input  logic [63:0] imm_i,
    input  logic [63:0] imm_s,
    input  logic [63:0] imm_u,

    input  riscv_pkg::dec_uop_t uop,

    output logic [63:0] alu_y,
    output logic        br_take,
    output logic [63:0] jalr_target
);
    import riscv_pkg::*;

    logic [63:0] alu_a, alu_b;
    alu_op_t     alu_op;

    // ALU operand selection
    always_comb begin
        alu_op = uop.alu_op;

        alu_a  = (uop.alua_sel == ALUA_PC) ? pc : rs1_data;

        unique case (uop.alub_sel)
            ALUB_RS2:   alu_b = rs2_data;
            ALUB_IMM_I: alu_b = imm_i;
            ALUB_IMM_S: alu_b = imm_s;
            ALUB_IMM_U: alu_b = imm_u;
            default:    alu_b = 64'd0;
        endcase
    end

    // Instantiate ALU
    alu u_alu (
        .a  (alu_a),
        .b  (alu_b),
        .op (alu_op),
        .y  (alu_y)
    );

    // Branch decision (valid when kind==IK_BRANCH)
    always_comb begin
        unique case (uop.br_funct3)
            3'b000: br_take = (rs1_data == rs2_data);                   // BEQ
            3'b001: br_take = (rs1_data != rs2_data);                   // BNE
            3'b100: br_take = ($signed(rs1_data) <  $signed(rs2_data)); // BLT
            3'b101: br_take = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
            3'b110: br_take = (rs1_data <  rs2_data);                   // BLTU
            3'b111: br_take = (rs1_data >= rs2_data);                   // BGEU
            default: br_take = 1'b0;
        endcase
    end

    // JALR target (requires bit0 cleared)
    always_comb begin
        jalr_target = (alu_y & ~64'd1);
    end

endmodule

`default_nettype wire
