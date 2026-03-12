`default_nettype none

module alu (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  riscv_pkg::alu_op_t op,
    output logic [63:0] y
);
    import riscv_pkg::*;

    logic [5:0] shamt64;
    logic [4:0] shamt32;

    logic [31:0] a32, b32;
    logic [31:0] r32;

    assign shamt64 = b[5:0];
    assign shamt32 = b[4:0];

    assign a32 = a[31:0];
    assign b32 = b[31:0];

    always_comb begin
        y  = 64'd0;
        r32 = 32'd0;

        unique case (op)

            // 64-bit ops
            ALU_ADD:  y = a + b;
            ALU_SUB:  y = a - b;
            ALU_AND:  y = a & b;
            ALU_OR:   y = a | b;
            ALU_XOR:  y = a ^ b;

            ALU_SLL:  y = a << shamt64;
            ALU_SRL:  y = a >> shamt64;
            ALU_SRA:  y = $signed(a) >>> shamt64;

            ALU_SLT:  y = ($signed(a) < $signed(b)) ? 64'd1 : 64'd0;
            ALU_SLTU: y = (a < b) ? 64'd1 : 64'd0;

            // W ops: compute in 32-bit then sign-extend to 64
            ALU_ADDW: begin
                r32 = a32 + b32;
                y   = {{32{r32[31]}}, r32};
            end
            ALU_SUBW: begin
                r32 = a32 - b32;
                y   = {{32{r32[31]}}, r32};
            end

            ALU_SLLW: begin
                r32 = a32 << shamt32;
                y   = {{32{r32[31]}}, r32};
            end
            ALU_SRLW: begin
                r32 = a32 >> shamt32;
                y   = {{32{r32[31]}}, r32};
            end
            ALU_SRAW: begin
                r32 = $signed(a32) >>> shamt32;
                y   = {{32{r32[31]}}, r32};
            end

            default: y = 64'b0;
            
        endcase
    end

endmodule

`default_nettype wire
