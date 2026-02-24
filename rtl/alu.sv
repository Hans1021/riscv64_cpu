`default_nettype none

module alu (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [2:0]  op,
    output logic [63:0] y
);

    // ALU opcodes
    localparam logic [2:0] ALU_ADD  = 3'd0;
    localparam logic [2:0] ALU_PASS = 3'd1;

    always_comb begin
        unique case (op)
            ALU_ADD:  y = a + b;
            ALU_PASS: y = a;
            default:  y = 64'b0;
        endcase
    end

endmodule

`default_nettype wire