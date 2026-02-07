`default_nettype none

module top (
    input  logic clk,
    input  logic reset,
    output logic [63:0] cycle_count
);

always_ff @(posedge clk) begin
    if (reset) begin
        cycle_count <= 64'd0;
    end else begin
        cycle_count <= cycle_count + 64'd1;
    end
end

endmodule

`default_nettype wire
