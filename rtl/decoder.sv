`default_nettype none

module decoder (
    input  logic [31:0] inst,

    output logic [6:0]  opcode,
    output logic [4:0]  rd, rs1, rs2,
    output logic [11:0] csr_addr,
    output logic [2:0]  funct3,
    output logic [6:0]  funct7,

    output logic [63:0] imm_i,
    output logic [63:0] imm_s,
    output logic [63:0] imm_b,
    output logic [63:0] imm_u,
    output logic [63:0] imm_j,

    output riscv_pkg::dec_uop_t uop
);
    import riscv_pkg::*;

    function automatic dec_uop_t decode_controls(
        input logic [31:0] inst_i,
        input logic [6:0]  opcode_i,
        input logic [2:0]  funct3_i,
        input logic [6:0]  funct7_i,
        input logic [4:0]  rd_i,
        input logic [4:0]  rs1_i
    );
        dec_uop_t c;

        // defaults

        c = '0;

        c.kind = IK_ILLEGAL;

        c.alu_op        = ALU_NONE;
        c.md_op         = MD_NONE;
        c.sys_op        = SYS_NONE;
        c.br_op         = BR_NONE;

        c.srca_sel      = SRCA_RS1;
        c.srcb_sel      = SRCB_RS2;

        c.wb_sel        = WB_EXU;
        c.pc_sel        = PC_PC4;
        c.reg_write     = 1'b0;

        c.mem_size      = MSZ_W;
        c.mem_unsigned  = 1'b0;

        c.csr_op  = CSR_NONE;
        c.csr_imm = 1'b0;

        // Decode!

        // SYSTEM
        if (opcode_i == 7'b1110011) begin
            unique case (funct3_i)
                3'b000: begin
                    if (rd_i == 5'b0 && rs1_i == 5'b0) begin
                        if (inst_i[31:20] == 12'b0) begin
                            c.kind      = IK_SYSTEM;
                            c.sys_op    = SYS_ECALL;
                        end else if (inst_i[31:20] == 12'b1) begin
                            c.kind      = IK_SYSTEM;
                            c.sys_op    = SYS_EBREAK;
                        end
                    end
                end

                3'b001: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RW;
                    c.csr_imm = 1'b0;
                    c.reg_write = (rd_i != 5'd0);
                end

                3'b010: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RS;
                    c.csr_imm = 1'b0;
                    c.reg_write = (rd_i != 5'd0);
                end

                3'b011: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RC;
                    c.csr_imm = 1'b0;
                    c.reg_write = (rd_i != 5'd0);
                end

                3'b101: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RW;
                    c.csr_imm = 1'b1;
                    c.reg_write = (rd_i != 5'd0);
                end

                3'b110: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RS;
                    c.csr_imm = 1'b1;
                    c.reg_write = (rd_i != 5'd0);
                end

                3'b111: begin
                    c.kind    = IK_SYSTEM;
                    c.csr_op  = CSR_RC;
                    c.csr_imm = 1'b1;
                    c.reg_write = (rd_i != 5'd0);
                end

            endcase
        end

        // FENCE / FENCE.I
        else if (opcode_i == 7'b0001111) begin
            if (funct3_i == 3'b000) begin
                c.kind   = IK_SYSTEM;
                c.sys_op = SYS_FENCE;
            end else if (funct3_i == 3'b001) begin
                c.kind   = IK_SYSTEM;
                c.sys_op = SYS_FENCE_I;
            end


        end

        // LUI
        else if (opcode_i == 7'b0110111) begin
            c.kind      = IK_LUI;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;
        end

        // AUIPC
        else if (opcode_i == 7'b0010111) begin
            c.kind      = IK_AUIPC;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;
        end

        // JAL
        else if (opcode_i == 7'b1101111) begin
            c.kind      = IK_JAL;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_PC4;
            c.pc_sel    = PC_PC_IMM;
        end

        // JALR
        else if (opcode_i == 7'b1100111) begin
            if (funct3_i == 3'b000) begin
                c.kind      = IK_JALR;
                c.reg_write = (rd_i != 5'd0);
                c.wb_sel    = WB_PC4;

                c.srca_sel  = SRCA_RS1;
                c.srcb_sel  = SRCB_IMM_I;
                c.alu_op    = ALU_ADD;

                c.pc_sel    = PC_ALU;
            end
        end

        // BRANCH
        else if (opcode_i == 7'b1100011) begin
            c.kind      = IK_BRANCH;
            c.pc_sel    = PC_PC_IMM;
            c.reg_write = 1'b0;

            unique case (funct3_i)
                3'b000: c.br_op = BR_EQ;
                3'b001: c.br_op = BR_NE;
                3'b100: c.br_op = BR_LT;
                3'b101: c.br_op = BR_GE;
                3'b110: c.br_op = BR_LTU;
                3'b111: c.br_op = BR_GEU;
                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // LOAD
        else if (opcode_i == 7'b0000011) begin
            c.kind      = IK_LOAD;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_MEM;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_IMM_I;
            c.alu_op    = ALU_ADD;

            unique case (funct3_i)
                3'b000: begin c.mem_size = MSZ_B; c.mem_unsigned = 1'b0; end // LB
                3'b001: begin c.mem_size = MSZ_H; c.mem_unsigned = 1'b0; end // LH
                3'b010: begin c.mem_size = MSZ_W; c.mem_unsigned = 1'b0; end // LW
                3'b011: begin c.mem_size = MSZ_D; c.mem_unsigned = 1'b0; end // LD
                3'b100: begin c.mem_size = MSZ_B; c.mem_unsigned = 1'b1; end // LBU
                3'b101: begin c.mem_size = MSZ_H; c.mem_unsigned = 1'b1; end // LHU
                3'b110: begin c.mem_size = MSZ_W; c.mem_unsigned = 1'b1; end // LWU
                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // STORE
        else if (opcode_i == 7'b0100011) begin
            c.kind      = IK_STORE;
            c.reg_write = 1'b0;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_IMM_S;
            c.alu_op    = ALU_ADD;

            unique case (funct3_i)
                3'b000: c.mem_size = MSZ_B; // SB
                3'b001: c.mem_size = MSZ_H; // SH
                3'b010: c.mem_size = MSZ_W; // SW
                3'b011: c.mem_size = MSZ_D; // SD
                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP-IMM (0010011)
        else if (opcode_i == 7'b0010011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_IMM_I;

            unique case (funct3_i)
                3'b000: c.alu_op = ALU_ADD;
                3'b010: c.alu_op = ALU_SLT;
                3'b011: c.alu_op = ALU_SLTU;
                3'b100: c.alu_op = ALU_XOR;
                3'b110: c.alu_op = ALU_OR;
                3'b111: c.alu_op = ALU_AND;

                3'b001: begin
                    if (inst_i[31:26] == 6'b000000) c.alu_op = ALU_SLL;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin
                    if (inst_i[31:26] == 6'b000000) c.alu_op = ALU_SRL;
                    else if (inst_i[31:26] == 6'b010000) c.alu_op = ALU_SRA;
                    else c.kind = IK_ILLEGAL;
                end
            endcase
        end

        // OP (0110011)
        else if (opcode_i == 7'b0110011) begin
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_RS2;

            if (funct7_i == 7'b0000001) begin
                c.kind = IK_MD;

                unique case (funct3_i)
                    3'b000: c.md_op = MD_MUL;
                    3'b001: c.md_op = MD_MULH;
                    3'b010: c.md_op = MD_MULHSU;
                    3'b011: c.md_op = MD_MULHU;
                    3'b100: c.md_op = MD_DIV;
                    3'b101: c.md_op = MD_DIVU;
                    3'b110: c.md_op = MD_REM;
                    3'b111: c.md_op = MD_REMU;
                    default: c.kind = IK_ILLEGAL;
                endcase
            end
            else begin
                c.kind = IK_ALU;

                unique case (funct3_i)
                    3'b000: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_ADD;
                        else if (funct7_i == 7'b0100000) c.alu_op = ALU_SUB;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b001: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SLL;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b010: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SLT;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b011: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SLTU;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b100: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_XOR;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b101: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SRL;
                        else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRA;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b110: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_OR;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b111: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_AND;
                        else c.kind = IK_ILLEGAL;
                    end

                    default: c.kind = IK_ILLEGAL;
                endcase
            end
        end

        // OP-IMM-32 (0011011)
        else if (opcode_i == 7'b0011011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_IMM_I;

            unique case (funct3_i)
                3'b000: c.alu_op = ALU_ADDW;

                3'b001: begin
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLLW;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SRLW;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRAW;
                    else c.kind = IK_ILLEGAL;
                end

                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP-32 (0111011)
        else if (opcode_i == 7'b0111011) begin
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_EXU;
            c.pc_sel    = PC_PC4;

            c.srca_sel  = SRCA_RS1;
            c.srcb_sel  = SRCB_RS2;

            if (funct7_i == 7'b0000001) begin
                c.kind = IK_MD;

                unique case (funct3_i)
                    3'b000: c.md_op = MD_MULW;
                    3'b100: c.md_op = MD_DIVW;
                    3'b101: c.md_op = MD_DIVUW;
                    3'b110: c.md_op = MD_REMW;
                    3'b111: c.md_op = MD_REMUW;
                    default: c.kind = IK_ILLEGAL;
                endcase
            end
            else begin
                c.kind = IK_ALU;

                unique case (funct3_i)
                    3'b000: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_ADDW;
                        else if (funct7_i == 7'b0100000) c.alu_op = ALU_SUBW;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b001: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SLLW;
                        else c.kind = IK_ILLEGAL;
                    end

                    3'b101: begin
                        if (funct7_i == 7'b0000000) c.alu_op = ALU_SRLW;
                        else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRAW;
                        else c.kind = IK_ILLEGAL;
                    end

                    default: c.kind = IK_ILLEGAL;
                endcase
            end
        end

        return c;
    endfunction

    always_comb begin
        opcode      = inst[6:0];
        rd          = inst[11:7];
        funct3      = inst[14:12];
        rs1         = inst[19:15];
        rs2         = inst[24:20];
        funct7      = inst[31:25];
        csr_addr    = inst[31:20];

        // Immediates
        imm_i = {{52{inst[31]}}, inst[31:20]};
        imm_s = {{52{inst[31]}}, inst[31:25], inst[11:7]};
        imm_b = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        imm_u = {{32{inst[31]}}, inst[31:12], 12'b0};
        imm_j = {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

        uop = decode_controls(inst, opcode, funct3, funct7, rd, rs1);
    end

endmodule

`default_nettype wire
