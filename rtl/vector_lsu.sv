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
    output logic         vlsu_ready_o,

    // OBI Memory Master
    output logic         data_req_o,
    input  logic         data_gnt_i,
    input  logic         data_rvalid_i,
    output logic [31:0]  data_addr_o,
    output logic         data_we_o,
    output logic [3:0]   data_be_o,
    input  logic [31:0]  data_rdata_i,
    output logic [31:0]  data_wdata_o,

    // Target Data
    input  wire [31:0]  op0_data_i, // Source (Load) / Destination (Store)
    input  wire [31:0]  op1_data_i, // Stride

    // Wide vector register port
    output logic [127:0] vs_wdata_o,
    input  logic [127:0] vs_rdata_i,
    input  logic [4:0] vr_addr_i
);

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
    vs_wdata_o = data_rdata_i << 8'(vr_addr_i[1:0] * 6'd32); // Shift data into correct position
    case(current_state)
        IDLE: begin
            if(vlsu_en_i & vlsu_load_i) begin
                data_addr_o = op0_data_i;
                data_req_o = 1'b1;
                next_state = LOAD_REQ;
            end else if(vlsu_en_i & vlsu_store_i)
                next_state = STORE_REQ;
            else 
                next_state = IDLE;
        end
        LOAD_REQ: begin
            if(data_rvalid_i) begin
                vlsu_ready_o = 1'b1;
                next_state = IDLE;
            end else
                next_state = LOAD_REQ;
        end
        STORE_REQ: begin
            next_state = IDLE;
        end
        LOAD_RVAL: begin
            
            next_state = IDLE;
        end
        STORE_RVAL: begin
            next_state = IDLE;
        end
    endcase    
end

endmodule
