import accelerator_pkg::*;

module vector_lsu (
    input  wire         clk,
    input  wire         n_reset,

    // Vector CSR
    input  wire [4:0]   vl_i,
    input  wire [1:0]   vsew_i,
    input  wire [1:0]   vlmul_i,

    // VLSU Decoded Control
    input  wire         vlsu_en_i,
    input  wire         vlsu_load_i,
    input  wire         vlsu_store_i,
    input  wire         vlsu_strided_i,
    output logic        vlsu_ready_o,

    // OBI Memory Master
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    input  logic [31:0] data_rdata_i,
    output logic [31:0] data_wdata_o,

    input  logic [1:0]  cycle_count_i,
 
    // Target Data
    input  wire [31:0]  op0_data_i, // Source (Load) / Destination (Store)
    input  wire [31:0]  op1_data_i, // Stride

    // Wide vector register port
    output logic [127:0] vs_wdata_o,
    input  logic [127:0] vs_rdata_i,
    input  logic [4:0] vr_addr_i,
    output logic vr_we_o
);

logic [31:0] vs_rdata_sel;
logic [5:0] vsew_size;

mapping_unit mu (
    .arith_format_o(vs_wdata_o),
    .memory_format_i(data_rdata_i),
    .sew_i(vsew_i),
    .reg_select(vr_addr_i[1:0])
);

logic [31:0] byte_stride;

always_comb begin
    byte_stride = 'd4;
    if(vlsu_strided_i)
        byte_stride = op1_data_i;
end

// Memory Master Controller
typedef enum {IDLE, LOAD_REQ, STORE_REQ, LOAD_RVAL, STORE_RVAL} vlsu_obi_state;
vlsu_obi_state current_state, next_state;

always_ff @(posedge clk, negedge n_reset) begin
    if(~n_reset)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    data_req_o = 1'b0;
    data_addr_o = 32'd0;
    data_we_o = 1'b0;
    data_be_o = 4'd0;
    data_wdata_o = 32'd0;
    vlsu_ready_o = 1'b0;
    vr_we_o = 1'b0;

    vsew_size = 6'd8 << (vsew_i);
    
    case(vr_addr_i[1:0])
        2'd0 : vs_rdata_sel = vs_rdata_i[31:0];
        2'd1 : vs_rdata_sel = vs_rdata_i[63:32];
        2'd2 : vs_rdata_sel = vs_rdata_i[95:64];
        2'd3 : vs_rdata_sel = vs_rdata_i[127:96];
    endcase

    case(current_state)
        IDLE: begin
            if(vlsu_en_i & vlsu_load_i) begin
                data_addr_o = op0_data_i + (byte_stride * cycle_count_i);
                data_req_o = 1'b1;
                next_state = LOAD_REQ;
            end else if(vlsu_en_i & vlsu_store_i) begin
                data_addr_o = op0_data_i;
                data_wdata_o = vs_rdata_sel;
                data_we_o = 1'b1;
                data_req_o = 1'b1;
                data_be_o = 4'hf;
                next_state = STORE_REQ;
            end else 
                next_state = IDLE;
        end
        LOAD_REQ: begin
            if(data_rvalid_i) begin
                vr_we_o = 1'b1;
                vlsu_ready_o = 1'b1;
                next_state = IDLE;
            end else
                next_state = LOAD_REQ;
        end
        STORE_REQ: begin
            if(data_rvalid_i) begin
                vlsu_ready_o = 1'b1;
                next_state = IDLE;    
            end else
                next_state = STORE_REQ;
            
        end
    endcase    
end

endmodule
