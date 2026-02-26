`default_nettype none

module decoder (
    input logic [31:0] inst,

    output logic [6:0] opcode,
    output logic [4:0] rd, rs1, rs2,

    output logic [2:0] funct3,
    output logic [6:0] funct7,

    output logic [63:0] imm_i,
    output logic [63:0] imm_s,
    output logic [63:0] imm_b,
    output logic [63:0] imm_u,
    output logic [63:0] imm_j,
    
    output logic is_addi,
    output logic is_jal,
    output logic is_ebreak,
    output logic illegal
    );

    always_comb begin
        opcode = inst[6:0];
        rd     = inst[11:7];
        funct3 = inst[14:12];
        rs1    = inst[19:15];
        rs2    = inst[24:20];
        funct7 = inst[31:25];

        // Immediates
        imm_i   = {{53{inst[31]}}, inst[30:20]};
        imm_s   = {{53{inst[31]}}, inst[30:25], inst[11:8], inst[7]};
        imm_b   = {{52{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
        imm_u   = {{33{inst[31]}}, inst[30:20], inst[19:12], 12'b0};
        imm_j   = {{44{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

        // Instruction (Milestone 3)
        is_addi   = (opcode == 7'b0010011) && (funct3 == 3'b000);
        is_jal    = (opcode == 7'b1101111);
        is_ebreak = (opcode == 7'b1110011) &&
                    (funct3 == 3'b000) &&
                    (inst[31:20] == 12'h001) &&
                    (rd == 5'd0) &&
                    (rs1 == 5'd0);

        illegal = !(is_addi || is_jal || is_ebreak);
    end

endmodule

`default_nettype wire
