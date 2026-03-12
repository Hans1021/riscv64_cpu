`default_nettype none
package riscv_pkg;

	// Major instruction kinds
	typedef enum logic [3:0] {
		IK_ALU,
		IK_MD,
		IK_LUI,
		IK_AUIPC,
		IK_JAL,
		IK_JALR,
		IK_BRANCH,
		IK_LOAD,
		IK_STORE,
		IK_SYSTEM,
		IK_ILLEGAL
	} instr_kind_t;

	// System ops
	typedef enum logic [3:0] {
		SYS_NONE,
		SYS_ECALL,
		SYS_EBREAK,
		SYS_FENCE,
		SYS_FENCE_I
	} sys_op_t;

	// ALU ops
	typedef enum logic [4:0] {
		ALU_NONE,
		ALU_ADD,
		ALU_SUB,
		ALU_AND,
		ALU_OR,
		ALU_XOR,
		ALU_SLL,
		ALU_SRL,
		ALU_SRA,
		ALU_SLT,
		ALU_SLTU,
		ALU_ADDW,
		ALU_SUBW,
		ALU_SLLW,
		ALU_SRLW,
		ALU_SRAW
	} alu_op_t;

	// MULDIV ops
	typedef enum logic [3:0] {
		MD_NONE,
		MD_MUL,
		MD_MULH,
		MD_MULHU,
		MD_MULHSU,
		MD_DIV,
		MD_DIVU,
		MD_REM,
		MD_REMU,
		MD_MULW,
		MD_DIVW,
		MD_DIVUW,
		MD_REMW,
		MD_REMUW
	} md_op_t;

	// Branch ops
	typedef enum logic [2:0] {
		BR_NONE,
		BR_EQ,
		BR_NE,
		BR_LT,
		BR_GE,
		BR_LTU,
		BR_GEU
	} br_op_t;

	// Operands select
	typedef enum logic [1:0] { 
		SRCA_RS1, 
		SRCA_PC 
	}  srca_sel_t;

	typedef enum logic [2:0] { 
		SRCB_RS2, 
		SRCB_IMM_I, 
		SRCB_IMM_S, 
		SRCB_IMM_U 
	} srcb_sel_t;

	// Writeback select
	typedef enum logic [1:0] { 
		WB_EXU, 
		WB_PC4, 
		WB_MEM
	} wb_sel_t;

	// PC select
	typedef enum logic [1:0] { 
		PC_PC4, 
		PC_PC_IMM,
		PC_ALU 
	} pc_sel_t;

	// Mem size select
	typedef enum logic [1:0] { 
		MSZ_B, 
		MSZ_H, 
		MSZ_W, 
		MSZ_D 
	} mem_size_t;

	// Decoded bundle
	typedef struct packed {
		instr_kind_t kind;

		alu_op_t     alu_op;
		md_op_t      md_op;
		sys_op_t     sys_op;
		br_op_t      br_op;

		srca_sel_t   srca_sel;
		srcb_sel_t   srcb_sel;

		wb_sel_t     wb_sel;
		pc_sel_t     pc_sel;
		logic        reg_write;

		mem_size_t   mem_size;
		logic        mem_unsigned;
	} dec_uop_t;

endpackage
`default_nettype wire
