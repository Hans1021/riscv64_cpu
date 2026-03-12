`default_nettype none

module frontend #(
    parameter logic [63:0] RESET_PC = 64'h0000_0000_8000_0000
) (
    input  logic        clk,
    input  logic        reset,

    // Control from FSM
    input  logic        if_start,           // pulse to start a fetch at current PC
    output logic        if_busy,
    output logic        if_done,            // 1-cycle pulse when IR updated
    output logic        if_err,             // 1-cycle pulse aligned with if_done when resp_err

    // PC update from FSM (applied after execute)
    input  logic        pc_we,
    input  logic [63:0] pc_next,

    // States
    output logic [63:0] pc_q,
    output logic [31:0] ir_q,

    // Unified bus
    output logic        req_valid,
    input  logic        req_ready,
    output logic [63:0] req_addr,
    output logic        req_is_write,
    output logic [63:0] req_wdata,
    output logic [7:0]  req_wstrb,

    input  logic        resp_valid,
    input  logic [63:0] resp_rdata,
    input  logic        resp_err
);

    // Read-only for frontend
    assign req_is_write = 1'b0;
    assign req_wdata    = 64'd0;
    assign req_wstrb    = 8'd0;

    typedef enum logic [1:0] { F_IDLE, F_REQ, F_WAIT } fstate_t;
    fstate_t fs_q, fs_d;

    logic fetch_hi_q;

    always_comb begin
        req_valid = 1'b0;
        req_addr  = {pc_q[63:3], 3'b000};

        if_busy = (fs_q != F_IDLE);
        if_done = 1'b0;
        if_err  = 1'b0;

        fs_d = fs_q;

        unique case (fs_q)
            F_IDLE: begin
                if (if_start) begin
                    fs_d = F_REQ;
                end
            end

            F_REQ: begin
                req_valid = 1'b1;
                req_addr  = {pc_q[63:3], 3'b000};
                if (req_ready) begin
                    fs_d = F_WAIT;
                end
            end

            F_WAIT: begin
                if (resp_valid) begin
                    if_done = 1'b1;
                    if_err  = resp_err;
                    fs_d    = F_IDLE;
                end
            end

            default: fs_d = F_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            fs_q       <= F_IDLE;
            pc_q       <= RESET_PC;
            ir_q       <= 32'd0;
            fetch_hi_q <= 1'b0;
        end else begin
            fs_q <= fs_d;

            // PC update
            if (pc_we) begin
                pc_q <= pc_next;
            end

            // latch which half when fetch request accepted
            if (fs_q == F_REQ && req_valid && req_ready) begin
                fetch_hi_q <= pc_q[2];
            end

            // latch IR on response
            if (fs_q == F_WAIT && resp_valid && !resp_err) begin
                ir_q <= fetch_hi_q ? resp_rdata[63:32] : resp_rdata[31:0];
            end
        end
    end

endmodule

`default_nettype wire
