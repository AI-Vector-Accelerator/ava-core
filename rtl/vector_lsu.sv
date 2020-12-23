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
    output logic        vlsu_done_o,

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
    output logic [4:0] vd_addr_o, // Redirected vector register address
    output logic vr_we_o
);

logic [31:0] vs_rdata_sel;
logic [5:0] vsew_size;

// Converts 32-bit words into PE arithmetic format (TODO: Reverse for stores)
mapping_unit mu (
    .arith_format_o     (),
    .memory_format_i    (data_rdata_i),
    .sew_i              (vsew_i),
    .reg_select         (vd_addr_o[1:0])
);

logic au_start, au_next;
logic [3:0] au_be;
logic [6:0] au_bc;
logic [31:0] au_addr;
logic au_valid, au_ready;
logic au_final;
logic [6:0] vd_offset;

// Calculates the address and byte enable sequences for multi-cycle loads
address_unit au (
    .clk_i          (clk),
    .n_rst_i        (n_reset),

    .base_addr_i    (op0_data_i),
    .stride_i       (vlsu_strided_i ? op1_data_i : (31'd1 << vsew_i) ), // If not strided, use unit stride
    .vd_offset_o    (vd_offset),

    .vl_i           (vl_i),
    .vsew_i         (vsew_i),
    
    .au_start_i     (au_start),
    .au_next_i      (au_next),
    .au_be_o        (au_be), //[ 3:0]
    .au_addr_o      (au_addr), //[31:0]
    .au_valid_o     (au_valid),
    .au_ready_o     (au_ready),
    .au_final_o     (au_final),
    .au_bc_o        (au_bc)
); 

temporary_reg tr (
    .clk_i              (clk), 
    .n_rst_i            (n_reset),
    .byte_enable_valid  (au_valid),
    .read_data_valid    (data_rvalid_i),
    .clear_register     (au_start),
    .memory_read_i      (data_rdata_i),
    .byte_enable_i      (au_be),
    .byte_select_i      (vd_offset + {vr_addr_i[1:0], 2'b00}),
    .wide_vd_o          (vs_wdata_o)
);

always_ff @(posedge clk, negedge n_reset) begin
    if(~n_reset)
        vr_we_o = 1'b0;
    else 
        vr_we_o = au_final;
end

always_comb begin
    vlsu_ready_o = 1'b0;
    au_start = 1'b0;
    au_next  = 1'b0;

    data_req_o  = 1'b0;
    data_addr_o = au_addr;
    data_we_o = 32'd0;
    data_be_o = au_be;
    data_wdata_o = 32'd0;
    vlsu_done_o = au_final;

    // Calculate offset of vd 
    vd_addr_o = vr_addr_i;

    if(vlsu_en_i) begin
        vlsu_ready_o = 1'b1;
        if(vlsu_load_i && au_ready) begin
            vlsu_ready_o = 1'b0; // Start transfer
            au_start = 1'b1;
        end else if(vlsu_load_i && ~au_ready) begin
            vlsu_ready_o = 1'b0;
            if(au_valid) begin
                data_req_o = 1'b1; // Send data request
            end
            if(data_rvalid_i) begin
                au_next = 1'b1;
            end
        end else if(vr_we_o) begin
            vlsu_ready_o = 1'b0;
        end
    end
end

endmodule
