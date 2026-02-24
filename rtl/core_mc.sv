`default_nettype none

module core_mc #(
    parameter logic [63:0] RESET_PC = 64'h0000_0000_8000_0000
) (
    input  logic        clk,
    input  logic        reset,

    // Master bus (core -> SoC)
    output logic        req_valid,
    input  logic        req_ready,
    output logic [63:0] req_addr,
    output logic        req_is_write,
    output logic [63:0] req_wdata,
    output logic [7:0]  req_wstrb,

    input  logic        resp_valid,
    output logic        resp_ready,
    input  logic [63:0] resp_rdata,
    input  logic        resp_err,

    // Debug
    output logic        halted,
    output logic [63:0] dbg_pc,
    output logic [31:0] dbg_ir,
    output logic [3:0]  dbg_state
);

    // Always ready
    assign resp_ready = 1'b1;

    logic [63:0] pc_q;
    logic [31:0] ir_q;

    assign dbg_pc = pc_q;
    assign dbg_ir = ir_q;

    // ----------------------------
    // Decoder
    // ----------------------------
    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [63:0] imm_i, imm_j;
    logic        is_addi, is_jal, is_ebreak, illegal;

    decoder u_dec (
        .inst     (ir_q),
        .opcode   (opcode),
        .rd       (rd),
        .funct3   (funct3),
        .rs1      (rs1),
        .rs2      (rs2),
        .funct7   (funct7),
        .imm_i    (imm_i),
        .imm_j    (imm_j),
        .is_addi  (is_addi),
        .is_jal   (is_jal),
        .is_ebreak(is_ebreak),
        .illegal  (illegal)
    );

    // ----------------------------
    // Register file
    // ----------------------------
    logic        rf_we;
    logic [4:0]  rf_waddr;
    logic [63:0] rf_wdata;
    logic [63:0] rs1_data, rs2_data;

    regfile u_rf (
        .clk      (clk),
        .reset    (reset),
        .rs1_addr (rs1),
        .rs2_addr (rs2),
        .rd_we    (rf_we),
        .rd_addr  (rf_waddr),
        .rd_wdata (rf_wdata),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // ----------------------------
    // ALU
    // ----------------------------
    logic [63:0] alu_y;
    logic [2:0]  alu_op;
    logic [63:0] alu_a, alu_b;

    // match alu.sv localparams: ALU_ADD=0
    localparam logic [2:0] ALU_ADD = 3'd0;

    alu u_alu (
        .a  (alu_a),
        .b  (alu_b),
        .op (alu_op),
        .y  (alu_y)
    );

    // Currently ALU always does rs1 + imm_i when executing ADDI
    assign alu_a  = rs1_data;
    assign alu_b  = imm_i;
    assign alu_op = ALU_ADD;

    // ----------------------------
    // Multi-cycle FSM
    // ----------------------------
    typedef enum logic [3:0] {
        S_RESET      = 4'd0,
        S_FETCH_REQ  = 4'd1,
        S_FETCH_RESP = 4'd2,
        S_DECODE     = 4'd3,
        S_EXEC_ADDI  = 4'd4,
        S_EXEC_JAL   = 4'd5,
        S_HALT       = 4'd15
    } state_t;

    state_t state_q, state_d;
    assign dbg_state = state_q;

    // Bus outputs default
    always_comb begin
        // defaults
        req_valid    = 1'b0;
        req_addr     = 64'b0;
        req_is_write = 1'b0;
        req_wdata    = 64'b0;
        req_wstrb    = 8'b0;

        // regfile write defaults
        rf_we    = 1'b0;
        rf_waddr = 5'd0;
        rf_wdata = 64'b0;

        // next state default
        state_d = state_q;

        if (state_q == S_FETCH_REQ) begin
            // Instruction fetch request (64-bit read)
            req_valid    = 1'b1;
            req_addr     = pc_q;
            req_is_write = 1'b0;
            req_wstrb    = 8'b0;
            if (req_ready) begin
                state_d = S_FETCH_RESP;
            end
        end else if (state_q == S_FETCH_RESP) begin
            if (resp_valid) begin
                state_d = S_DECODE;
            end
        end else if (state_q == S_DECODE) begin
            if (is_addi)       state_d = S_EXEC_ADDI;
            else if (is_jal)   state_d = S_EXEC_JAL;
            else if (is_ebreak)state_d = S_HALT;
            else               state_d = S_HALT; // illegal: halt for now
        end else if (state_q == S_EXEC_ADDI) begin
            // Write rd = rs1 + imm_i, then pc += 4
            rf_we    = 1'b1;
            rf_waddr = rd;
            rf_wdata = alu_y;
            state_d  = S_FETCH_REQ;
        end else if (state_q == S_EXEC_JAL) begin
            // Write rd = pc+4, then pc = pc + imm_j
            rf_we    = 1'b1;
            rf_waddr = rd;
            rf_wdata = pc_q + 64'd4;
            state_d  = S_FETCH_REQ;
        end else if (state_q == S_HALT) begin
            state_d = S_HALT;
        end
    end

    // Sequential state + architectural updates
    always_ff @(posedge clk) begin
        if (reset) begin
            state_q <= S_RESET;
            pc_q    <= RESET_PC;
            ir_q    <= 32'b0;
            halted  <= 1'b0;
        end else begin
            state_q <= state_d;

            if (state_d == S_HALT) halted <= 1'b1;

            // State actions
            unique case (state_q)
                S_RESET: begin
                    pc_q   <= RESET_PC;
                    halted <= 1'b0;
                    state_q <= S_FETCH_REQ; // immediate start after reset release
                end

                S_FETCH_RESP: begin
                    if (resp_valid) begin
                        if (resp_err) begin
                            // bus error on fetch: halt
                            halted <= 1'b1;
                            state_q <= S_HALT;
                        end else begin
                            ir_q <= resp_rdata[31:0];
                        end
                    end
                end

                S_EXEC_ADDI: begin
                    // PC update for ADDI
                    pc_q <= pc_q + 64'd4;
                end

                S_EXEC_JAL: begin
                    // PC update for JAL
                    pc_q <= pc_q + imm_j;
                end

                default: begin
                    // no-op
                end
            endcase
        end
    end

endmodule

`default_nettype wire