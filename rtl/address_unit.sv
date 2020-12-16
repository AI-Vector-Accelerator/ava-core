module address_unit
   (input logic clk_i,
    input logic n_rst_i,

    input logic [1:0] vsew_i,
    input logic [4:0] vl_i,
    input logic [1:0] vlmul_i,

    input logic vlsu_strided,
    input logic [31:0] stride,

    input logic [31:0] base_addr_i,
    output logic [31:0] addr_calc_o,
    output logic data_req,  
    input logic data_rvalid,
    
    input logic au_en,
    output logic au_done);

    // Calculate required read cycles
    logic [3:0] cycles_needed;
    logic [1:0] vsew_div;
    logic [1:0] stride_div;
    logic vl_trunc_c;

    always_comb begin

        if(~vlsu_strided) begin
            stride_div = 2'd0;          // No Stride
        end else begin
            if(stride == 32'd0)     
                stride_div = 2'd0;      // No Stride
            else if(stride <= 32'd2)
                stride_div = 2'd1;      // 1-2 Byte Stride
            else if(stride <= 32'd4)
                stride_div = 2'd2;      // 4-x Byte Stride
        end

        // How many shifts to divide reg?
        vsew_div = 2'b10 >> (vsew_i + stride_div); // TODO: Strided loads reduce count per cycle

        // Depending on VSEW, check dropped bits of vl and see if an extra read needed
        vl_trunc_c = (vsew_div == 2'd2) ? (vl_i[1] || vl_i[0]) : ((vsew_div == 2'd1) ? (vl_i[0]) : (1'b0));
        cycles_needed = (vl_i >> vsew_div) + vl_trunc_c;
    end

endmodule