`default_nettype none

module lsu (
    input  logic        clk,
    input  logic        reset,

    // Issue from control/FSM (one request at a time)
    input  logic        issue,
    input  logic        is_store,        // 0=load, 1=store
    input  logic [63:0] addr,
    input  logic [63:0] store_data,      // rs2_data (unshifted)
    input  riscv_pkg::mem_size_t mem_size,
    input  logic        mem_unsigned,    // loads only

    output logic        busy,
    output logic        done,            // 1-cycle pulse when operation completes
    output logic [63:0] load_data,       // valid when done && !is_store
    output logic        err,             // pulse aligned with done

    // Unified bus (LSU drives when busy)
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
    import riscv_pkg::*;

    // ----------------------------
    // Helpers
    // ----------------------------
    function automatic logic [7:0] size_mask(input mem_size_t sz);
        unique case (sz)
            MSZ_B: size_mask = 8'b0000_0001;
            MSZ_H: size_mask = 8'b0000_0011;
            MSZ_W: size_mask = 8'b0000_1111;
            MSZ_D: size_mask = 8'b1111_1111;
            default: size_mask = 8'b0;
        endcase
    endfunction

    function automatic logic is_misaligned(input logic [63:0] a, input mem_size_t sz);
        unique case (sz)
            MSZ_B: is_misaligned = 1'b0;
            MSZ_H: is_misaligned = a[0];
            MSZ_W: is_misaligned = |a[1:0];
            MSZ_D: is_misaligned = |a[2:0];
            default: is_misaligned = 1'b1;
        endcase
    endfunction

    function automatic logic [63:0] load_extend(
        input logic [63:0] rdata,
        input logic [2:0]  addr_lo,
        input mem_size_t   sz,
        input logic        u
    );
        logic [63:0] shifted;
        shifted = rdata >> (addr_lo * 8);

        unique case (sz)
            MSZ_B: load_extend = u ? {{56{1'b0}}, shifted[7:0]}
                                   : {{56{shifted[7]}}, shifted[7:0]};
            MSZ_H: load_extend = u ? {{48{1'b0}}, shifted[15:0]}
                                   : {{48{shifted[15]}}, shifted[15:0]};
            MSZ_W: load_extend = u ? {{32{1'b0}}, shifted[31:0]}
                                   : {{32{shifted[31]}}, shifted[31:0]};
            MSZ_D: load_extend = shifted;
            default: load_extend = 64'd0;
        endcase
    endfunction

    // ----------------------------
    // Internal state
    // ----------------------------
    typedef enum logic [1:0] { L_IDLE, L_REQ, L_WAIT } lstate_t;
    lstate_t ls_q, ls_d;

    logic        is_store_q;
    mem_size_t   mem_size_q;
    logic        mem_unsigned_q;
    logic [63:0] addr_q;
    logic [2:0]  addr_lo_q;
    logic [63:0] store_q;

    // outputs
    always_comb begin
        busy      = (ls_q != L_IDLE);
        done      = 1'b0;
        err       = 1'b0;
        load_data = 64'd0;

        // bus defaults
        req_valid    = 1'b0;
        req_addr     = addr_q;
        req_is_write = is_store_q;
        req_wdata    = 64'd0;
        req_wstrb    = 8'd0;

        ls_d = ls_q;

        unique case (ls_q)
            L_IDLE: begin
                if (issue) begin
                    if (is_misaligned(addr, mem_size)) begin
                        // Immediate error completion (no bus transaction)
                        done = 1'b1;
                        err  = 1'b1;
                        ls_d = L_IDLE;
                    end else begin
                        ls_d = L_REQ;
                    end
                end
            end

            L_REQ: begin
                req_valid    = 1'b1;
                req_addr     = addr_q;
                req_is_write = is_store_q;

                if (is_store_q) begin
                    req_wdata = store_q << (addr_lo_q * 8);
                    req_wstrb = size_mask(mem_size_q) << addr_lo_q;
                end else begin
                    req_wdata = 64'd0;
                    req_wstrb = 8'd0;
                end

                if (req_ready) begin
                    if (is_store_q) begin
                        done = 1'b1;     // store completes on accept
                        ls_d = L_IDLE;
                    end else begin
                        ls_d = L_WAIT;   // load waits for response
                    end
                end
            end

            L_WAIT: begin
                if (resp_valid) begin
                    done      = 1'b1;
                    err       = resp_err;
                    load_data = load_extend(resp_rdata, addr_lo_q, mem_size_q, mem_unsigned_q);
                    ls_d      = L_IDLE;
                end
            end

            default: ls_d = L_IDLE;
        endcase
    end

    // latching request info on issue
    always_ff @(posedge clk) begin
        if (reset) begin
            ls_q           <= L_IDLE;
            is_store_q     <= 1'b0;
            mem_size_q     <= MSZ_W;
            mem_unsigned_q <= 1'b0;
            addr_q         <= 64'd0;
            addr_lo_q      <= 3'd0;
            store_q        <= 64'd0;
        end else begin
            ls_q <= ls_d;

            if (ls_q == L_IDLE && issue && !is_misaligned(addr, mem_size)) begin
                is_store_q     <= is_store;
                mem_size_q     <= mem_size;
                mem_unsigned_q <= mem_unsigned;
                addr_q         <= addr;
                addr_lo_q      <= addr[2:0];
                store_q        <= store_data;
            end
        end
    end

endmodule

`default_nettype wire
