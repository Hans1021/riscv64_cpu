`default_nettype none

module decoder (
    input logic [31:0] inst;

    output logic [6:0] opcode;
    output logic [4:0] rd, rs1, rs2;

    output logic [2:0] funct3;
    output logic [6:0] funct7;

    output logic [63:0] imm_i; // sign-extended
    output logic [63:0] imm_j; // sign-extended
    
    output logic is_addi;
    output logic is_jal;
    output logic is_ebreak;
    output logic illegal;
);

    always_comb begin
        opcode = inst[6:0];
        rd     = inst[11:7];
        funct3 = inst[14:12];
        rs1    = inst[19:15];
        rs2    = inst[24:20];
        funct7 = inst[31:25];

        // I-type immediate: inst[31:20], sign-extended to 64
        imm_i  = {{52{inst[31]}}, inst[31:20]};

        // J-type immediate assembly (21 bits including bit 0=0), sign-extended
        logic [20:0] immj_21;
        immj_21 = { inst[31],
                    inst[30:21],
                    inst[20],
                    inst[19:12],
                    1'b0 };
        imm_j = {{43{immj_21[20]}}, immj_21};

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