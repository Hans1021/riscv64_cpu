`default_nettype none

module decoder (
    input  logic [31:0] inst,

    output logic [6:0]  opcode,
    output logic [4:0]  rd, rs1, rs2,
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

        // ----------------------------
        // Defaults: illegal, NOP
        // ----------------------------
        c = '0;

        c.kind      = IK_ILLEGAL;

        // execute defaults
        c.alu_op    = ALU_ADD;
        c.alua_sel  = ALUA_RS1;
        c.alub_sel  = ALUB_RS2;

        // wb/pc defaults
        c.wb_sel    = WB_ALU;
        c.pc_sel    = PC_PC4;
        c.reg_write = 1'b0;

        // branch defaults
        c.br_funct3 = funct3_i;

        // mem defaults
        c.mem_size     = MSZ_W;
        c.mem_unsigned = 1'b0;

        // system defaults
        c.is_ebreak = 1'b0;
        c.is_ecall  = 1'b0;
        c.is_fence  = 1'b0;

        // ----------------------------
        // Decode by opcode
        // ----------------------------

        // SYSTEM (ECALL/EBREAK only)
        if (opcode_i == 7'b1110011) begin
        if (funct3_i == 3'b000 && rd_i == 5'd0 && rs1_i == 5'd0) begin
            if (inst_i[31:20] == 12'h000) begin
            c.kind     = IK_SYSTEM;
            c.is_ecall = 1'b1;
            end else if (inst_i[31:20] == 12'h001) begin
            c.kind      = IK_SYSTEM;
            c.is_ebreak = 1'b1;
            end
        end
        end

        // FENCE (legal NOP for now)
        else if (opcode_i == 7'b0001111) begin
        if (funct3_i == 3'b000 || funct3_i == 3'b001) begin
            // legal, no register write, just advance PC
            c.kind      = IK_SYSTEM;
            c.is_fence  = 1'b1;
            c.reg_write = 1'b0;
            c.pc_sel    = PC_PC4;
        end
        end

        // LUI: rd = imm_u
        else if (opcode_i == 7'b0110111) begin
            c.kind      = IK_LUI;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_IMM_U;
            c.pc_sel    = PC_PC4;
        end

        // AUIPC: rd = pc + imm_u
        else if (opcode_i == 7'b0010111) begin
            c.kind      = IK_AUIPC;
            c.reg_write = (rd_i != 5'd0);

            c.alua_sel  = ALUA_PC;
            c.alub_sel  = ALUB_IMM_U;
            c.alu_op    = ALU_ADD;

            c.wb_sel    = WB_ALU;
            c.pc_sel    = PC_PC4;
        end

        // JAL: rd = pc+4; pc = pc + imm_j
        else if (opcode_i == 7'b1101111) begin
            c.kind      = IK_JAL;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_PC4;
            c.pc_sel    = PC_PC_IMM;
        end

        // JALR: rd = pc+4; pc = (rs1 + imm_i) & ~1
        else if (opcode_i == 7'b1100111) begin
            if (funct3_i == 3'b000) begin
                c.kind      = IK_JALR;
                c.reg_write = (rd_i != 5'd0);
                c.wb_sel    = WB_PC4;

                c.alua_sel  = ALUA_RS1;
                c.alub_sel  = ALUB_IMM_I;
                c.alu_op    = ALU_ADD;

                c.pc_sel    = PC_ALU;
            end
        end

        // BRANCH: taken decided by exu using br_funct3; pc uses imm_b if taken else pc+4
        else if (opcode_i == 7'b1100011) begin
            c.kind      = IK_BRANCH;
            c.br_funct3 = funct3_i;
            c.pc_sel    = PC_PC_IMM;
            c.reg_write = 1'b0;

            // Optional: enforce only the 6 defined branch funct3 values
            unique case (funct3_i)
                3'b000,3'b001,3'b100,3'b101,3'b110,3'b111: /* ok */ ;
                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // LOAD: address = rs1 + imm_i ; wb = mem
        else if (opcode_i == 7'b0000011) begin
            c.kind      = IK_LOAD;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_MEM;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_IMM_I;
            c.alu_op    = ALU_ADD;

            // funct3: LB/LH/LW/LD/LBU/LHU/LWU
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

        // STORE: address = rs1 + imm_s
        else if (opcode_i == 7'b0100011) begin
            c.kind      = IK_STORE;
            c.reg_write = 1'b0;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_IMM_S;
            c.alu_op    = ALU_ADD;

            // funct3: SB/SH/SW/SD
            unique case (funct3_i)
                3'b000: c.mem_size = MSZ_B; // SB
                3'b001: c.mem_size = MSZ_H; // SH
                3'b010: c.mem_size = MSZ_W; // SW
                3'b011: c.mem_size = MSZ_D; // SD
                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP-IMM (0010011): ADDI/SLTI/SLTIU/XORI/ORI/ANDI/SLLI/SRLI/SRAI
        else if (opcode_i == 7'b0010011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_ALU;
            c.pc_sel    = PC_PC4;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_IMM_I;

            unique case (funct3_i)
                3'b000: c.alu_op = ALU_ADD;   // ADDI
                3'b010: c.alu_op = ALU_SLT;   // SLTI
                3'b011: c.alu_op = ALU_SLTU;  // SLTIU
                3'b100: c.alu_op = ALU_XOR;   // XORI
                3'b110: c.alu_op = ALU_OR;    // ORI
                3'b111: c.alu_op = ALU_AND;   // ANDI

                3'b001: begin                 // SLLI
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLL;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin                 // SRLI/SRAI
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SRL;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRA;
                    else c.kind = IK_ILLEGAL;
                end

                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP (0110011): ADD/SUB/SLL/SLT/SLTU/XOR/SRL/SRA/OR/AND
        else if (opcode_i == 7'b0110011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_ALU;
            c.pc_sel    = PC_PC4;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_RS2;

            unique case (funct3_i)
                3'b000: begin // ADD/SUB
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_ADD;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SUB;
                    else c.kind = IK_ILLEGAL;
                end

                3'b001: begin // SLL
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLL;
                    else c.kind = IK_ILLEGAL;
                end

                3'b010: begin // SLT
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLT;
                    else c.kind = IK_ILLEGAL;
                end

                3'b011: begin // SLTU
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLTU;
                    else c.kind = IK_ILLEGAL;
                end

                3'b100: begin // XOR
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_XOR;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin // SRL/SRA
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SRL;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRA;
                    else c.kind = IK_ILLEGAL;
                end

                3'b110: begin // OR
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_OR;
                    else c.kind = IK_ILLEGAL;
                end

                3'b111: begin // AND
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_AND;
                    else c.kind = IK_ILLEGAL;
                end

                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP-IMM-32 (0011011): ADDIW/SLLIW/SRLIW/SRAIW
        else if (opcode_i == 7'b0011011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_ALU;
            c.pc_sel    = PC_PC4;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_IMM_I;

            unique case (funct3_i)
                3'b000: c.alu_op = ALU_ADDW; // ADDIW

                3'b001: begin // SLLIW
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLLW;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin // SRLIW/SRAIW
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SRLW;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRAW;
                    else c.kind = IK_ILLEGAL;
                end

                default: c.kind = IK_ILLEGAL;
            endcase
        end

        // OP-32 (0111011): ADDW/SUBW/SLLW/SRLW/SRAW
        else if (opcode_i == 7'b0111011) begin
            c.kind      = IK_ALU;
            c.reg_write = (rd_i != 5'd0);
            c.wb_sel    = WB_ALU;
            c.pc_sel    = PC_PC4;

            c.alua_sel  = ALUA_RS1;
            c.alub_sel  = ALUB_RS2;

            unique case (funct3_i)
                3'b000: begin // ADDW/SUBW
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_ADDW;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SUBW;
                    else c.kind = IK_ILLEGAL;
                end

                3'b001: begin // SLLW
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SLLW;
                    else c.kind = IK_ILLEGAL;
                end

                3'b101: begin // SRLW/SRAW
                    if (funct7_i == 7'b0000000) c.alu_op = ALU_SRLW;
                    else if (funct7_i == 7'b0100000) c.alu_op = ALU_SRAW;
                    else c.kind = IK_ILLEGAL;
                end

              default: c.kind = IK_ILLEGAL;
            endcase
        end

        return c;
    endfunction

    always_comb begin
        opcode = inst[6:0];
        rd     = inst[11:7];
        funct3 = inst[14:12];
        rs1    = inst[19:15];
        rs2    = inst[24:20];
        funct7 = inst[31:25];

        // Immediates (RV64)
        imm_i = {{52{inst[31]}}, inst[31:20]};
        imm_s = {{52{inst[31]}}, inst[31:25], inst[11:7]};
        imm_b = {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        imm_u = {{32{inst[31]}}, inst[31:12], 12'b0};
        imm_j = {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

        uop = decode_controls(inst, opcode, funct3, funct7, rd, rs1);
    end

endmodule

`default_nettype wire
