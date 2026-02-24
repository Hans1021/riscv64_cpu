`default_nettype none

module regfile (
    input logic clk, reset,
    input logic [4:0] rs1_addr, rs2_addr,
    input logic rd_we,
    input logic [4:0] rd_addr,
    input logic [63:0] rd_wdata,

    output logic [63:0] rs1_data,
    output logic [63:0] rs2_data
);

    logic [63:0] regs [0:31];

    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 1; i < 32; i++) begin
                regs[i] <= 64'b0;
            end
        end else if (rd_we && rd_addr != 0) begin
            regs[rd_addr] <= rd_wdata;
        end
    end

    always_comb begin
        rs1_data = (rs1_addr == 0) ? 64'b0 : regs[rs1_addr];
        rs2_data = (rs2_addr == 0) ? 64'b0 : regs[rs2_addr];
    end


endmodule

`default_nettype wire
