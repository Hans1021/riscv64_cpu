`default_nettype none
package riscv_pkg;

  typedef enum logic [3:0] {
    IK_ALU     = 4'd0,
    IK_LUI     = 4'd1,
    IK_AUIPC   = 4'd2,
    IK_JAL     = 4'd3,
    IK_JALR    = 4'd4,
    IK_BRANCH  = 4'd5,
    IK_LOAD    = 4'd6,
    IK_STORE   = 4'd7,
    IK_SYSTEM  = 4'd8,
    IK_ILLEGAL = 4'd15
  } instr_kind_t;

  typedef enum logic [5:0] {
    ALU_ADD    = 6'd0,
    ALU_SUB    = 6'd1,
    ALU_AND    = 6'd2,
    ALU_OR     = 6'd3,
    ALU_XOR    = 6'd4,
    ALU_SLL    = 6'd5,
    ALU_SRL    = 6'd6,
    ALU_SRA    = 6'd7,
    ALU_SLT    = 6'd8,
    ALU_SLTU   = 6'd9,
    ALU_ADDW   = 6'd10,
    ALU_SUBW   = 6'd11,
    ALU_SLLW   = 6'd12,
    ALU_SRLW   = 6'd13,
    ALU_SRAW   = 6'd14,
    ALU_PASS_A = 6'd63
  } alu_op_t;

  typedef enum logic [1:0] { ALUA_RS1, ALUA_PC }  alua_sel_t;
  typedef enum logic [2:0] { ALUB_RS2, ALUB_IMM_I, ALUB_IMM_S, ALUB_IMM_U } alub_sel_t;

  typedef enum logic [1:0] { WB_ALU, WB_PC4, WB_MEM, WB_IMM_U } wb_sel_t;
  typedef enum logic [1:0] { PC_PC4, PC_PC_IMM, PC_ALU } pc_sel_t;

  typedef enum logic [1:0] { MSZ_B, MSZ_H, MSZ_W, MSZ_D } mem_size_t;

  typedef struct packed {
    instr_kind_t kind;

    // execute
    alu_op_t     alu_op;
    alua_sel_t   alua_sel;
    alub_sel_t   alub_sel;

    // writeback + pc
    wb_sel_t     wb_sel;
    pc_sel_t     pc_sel;
    logic        reg_write;

    // branch (valid when kind==IK_BRANCH)
    logic [2:0]  br_funct3;

    // memory (valid when kind==IK_LOAD/IK_STORE)
    mem_size_t   mem_size;
    logic        mem_unsigned; // loads only

	// system / misc
	logic        is_ebreak;    // opcode=SYSTEM, imm=0x001
	logic        is_ecall;     // opcode=SYSTEM, imm=0x000
	logic        is_fence;     // opcode=FENCE (0001111)
  } dec_uop_t;

endpackage
`default_nettype wire
