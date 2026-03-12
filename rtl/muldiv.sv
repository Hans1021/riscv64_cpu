`default_nettype none

module muldiv (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  riscv_pkg::md_op_t op,
    output logic [63:0] y
);
    import riscv_pkg::*;

    logic [31:0] a32, b32;
    logic [31:0] r32;

    logic [127:0] prod;

    assign a32 = a[31:0];
    assign b32 = b[31:0];

    always_comb begin
        y    = 64'd0;
        r32  = 32'd0;
        prod = 128'd0;
        unique case (op)

            // 64-bit ops
            MD_MUL: begin
                prod = a * b;
                y = prod[63:0];
            end
            MD_MULH: begin
                prod = $signed(a) * $signed(b);
                y = prod[127:64];
            end
            MD_MULHU: begin
                prod = a * b;
                y = prod[127:64];
            end
            MD_MULHSU: begin
                prod = $signed(a) * $signed({1'b0, b});
                y = prod[127:64];
            end

            MD_DIV: begin
                if (b == 0) y = -1;
                // Overflow case
                else if (a == {{1'b1}, {63{1'b0}}} && b == {64{1'b1}}) y = a;
                else y = $signed(a) / $signed(b);
            end
            MD_DIVU: begin
                if (b == 0) y = {64{1'b1}};
                else y = a / b;
            end
            MD_REM: begin
                if (b == 0) y = a;
                // Overflow case
                else if (a == {{1'b1}, {63{1'b0}}} && b == {64{1'b1}}) y = 0;
                else y = $signed(a) % $signed(b);
            end
            MD_REMU: begin
                if (b == 0) y = a;
                else y = a % b;
            end

            // W ops: compute in 32-bit then sign-extend to 64
            MD_MULW: begin
                r32 = a32 * b32;
                y   = {{32{r32[31]}}, r32};
            end
            MD_DIVW: begin
                if (b32 == 0) r32 = -1;
                // Overflow case
                else if (a32 == {{1'b1}, {31{1'b0}}} && b32 == {32{1'b1}}) r32 = a32;
                else begin
                    r32 = $signed(a32) / $signed(b32);
                end
                y = {{32{r32[31]}}, r32};
            end

            MD_DIVUW: begin
                if (b32 == 0) r32 = {32{1'b1}};
                else begin
                    r32 = a32 / b32;
                end
                y = {{32{r32[31]}}, r32};
            end
            MD_REMW: begin
                if (b32 == 0) r32 = a32;
                // Overflow case
                else if (a32 == {{1'b1}, {31{1'b0}}} && b32 == {32{1'b1}}) r32 = 0;
                else begin
                    r32 = $signed(a32) % $signed(b32);
                end
                y = {{32{r32[31]}}, r32};
            end
            MD_REMUW: begin
                if (b32 == 0) r32 = a32;
                else begin
                    r32 = a32 % b32;
                end
                y = {{32{r32[31]}}, r32};
            end

            default: y = 64'b0;
        endcase
    end

endmodule

`default_nettype wire
