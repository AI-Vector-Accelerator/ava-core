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

// Converts 32-bit words into PE arithmetic format (TODO: Reverse for stores)
mapping_unit mu (
    .arith_format_o(vs_wdata_o),
    .memory_format_i(data_rdata_i),
    .sew_i(vsew_i),
    .reg_select(vr_addr_i[1:0])
);

logic au_start, au_next
logic [3:0] au_be;
logic [31:0] au_addr;
logic au_valid, au_ready;

// Calculates the address and byte enable sequences for multi-cycle loads
address_unit au (
    .clk_i          (clk),
    .n_rst_i        (n_reset),

    .base_addr_i    (op0_data_i),
    .stride_i       (vlsu_strided ? op1_data_i : (31'd1 << vsew) ), // If not strided, use unit stride
    
    .vl_i           (vl_i),
    .vsew_i         (vsew_i),
    
    .au_start_i     (au_start),
    .au_next_i      (au_next),
    .au_be_o        (au_be), //[ 3:0]
    .au_addr_o      (au_addr), //[31:0]
    .au_valid_o     (au_valid),
    .au_ready_o     (au_ready)
); 

always_comb begin
    vlsu_ready_o = 1'b0;
    au_start = 1'b0;
    au_next  = 1'b0;
    if(vlsu_en_i) begin
        vlsu_ready_o = 1'b1;
        if(vlsu_load_i && au_ready) begin
            vlsu_ready_o = 1'b0;
            au_start = 1'b1;
        end else if(~au_ready) begin
            vlsu_ready_o = 1b0;
            if(au_valid) =

        end
    end
end

endmodule
