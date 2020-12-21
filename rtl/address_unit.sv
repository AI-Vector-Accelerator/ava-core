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

        if(~vlsu_strided || stride == 32'd0) begin
            stride_div = 2'd0;  // Unit Stride
        end else begin
            stride_div = (stride <= 2'd2) ? 2'd1 : 2'd2;
        end

        // How many shifts to divide reg?
        vsew_div = 2'b10 >> (vsew_i + stride_div); // TODO: Strided loads reduce count per cycle
        cycles_needed = (vl_i >> vsew_div) + vl_trunc_c;
    end

    assign vl_trunc_c = (vsew_div == 2'd2) ? (vl_i[1] || vl_i[0]) : ((vsew_div == 2'd1) ? (vl_i[0]) : (1'b0));

endmodule