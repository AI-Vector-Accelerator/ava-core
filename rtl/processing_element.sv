module processing_element 
    (input logic [7:0] a,
     input logic [7:0] b,
     input logic [7:0] c,
     
     input logic [11:0] tree_l,
     input logic [11:0] tree_r,
     
     input logic [1:0] mux_add_a,
     input logic [1:0] mux_add_b,
     input logic mux_c_acc,
     input logic [1:0] mux_sat8,
     input logic mux_relu,
     input logic [1:0] mux_res,
     input logic mux_comb,
     input logic enable_acc,
     input logic clk,
     input logic n_reset,

     output logic [7:0] r,
     output logic [11:0] tree_o);

    logic [15:0] mul_out;
    logic [11:0] mul_out_trunc;
    assign mul_out = a * b;
    assign mul_out_trunc = mul_out[15:4];

    logic [11:0] a_ex, b_ex, c_ex;
    bit_ext #(.W_IN(8), .W_OUT(12)) a_bex(a, a_ex);
    bit_ext #(.W_IN(8), .W_OUT(12)) b_bex(b, b_ex);
    bit_ext #(.W_IN(8), .W_OUT(12)) c_bex(c, c_ex);
    
    logic [11:0] acc_reg, c_acc;
    assign c_acc = mux_c_acc ? c_ex : acc_reg;

    logic [11:0] add_a, add_b;
    always_comb begin
        case(mux_add_a)
            2'd0: add_a = a_ex;
            2'd1: add_a = mul_out_trunc;
            2'd2: add_a = tree_l;
            2'd3: add_a = 12'd0; // Not Implemented;
            default: add_a = 12'd0;
        endcase
        case(mux_add_b)
            2'd0: add_b = b_ex;
            2'd1: add_b = c_acc;
            2'd2: add_b = tree_r;
            2'd3: add_b = 12'd0; // Not Implemented;
            default: add_b = 12'd0;
        endcase
    end

    logic [12:0] add_out;
    assign add_out = add_a + add_b;

    logic [12:0] sat8_in;
    logic [7:0] sat8_out;

    always_comb begin
        case(mux_sat8)
            // Sign extend 12-bit native data to match adder output
            2'd0: sat8_in = {c_acc[11],c_acc};
            2'd1: sat8_in = add_out;
            2'd2: sat8_in = {mul_out_trunc[11],mul_out_trunc};
            2'd3: sat8_in = 13'd0; // Not Implemented;
            default: sat8_in = 13'd0;
        endcase
    end
    sat_unit #(.W_IN(13), .W_OUT(8)) sat_unit_8 (sat8_in, sat8_out);


    logic [11:0] add_sat12_out;
    sat_unit #(.W_IN(13), .W_OUT(12)) sat_unit_12 (add_out, add_sat12_out);
    assign tree_o = add_sat12_out;

    logic [7:0] relu_in;
    logic [6:0] relu_out; // Unsigned
    assign relu_in = mux_relu ? sat8_out : a;
    relu_bound #(.W(8)) relu6 (relu_in, relu_out);
 
    logic [11:0] sat8_out_ex, relu_out_ex;
    bit_ext #(.W_IN(8), .W_OUT(12)) sat8_bex(sat8_out, sat8_out_ex);
    assign relu_out_ex = {5'b0, relu_out};

    logic [11:0] res_out;

    always_comb begin
        case(mux_res)
            // Sign extend 12-bit native data to match adder output
            2'd0: res_out = mul_out_trunc;
            2'd1: res_out = add_sat12_out;
            2'd2: res_out = sat8_out_ex;
            2'd3: res_out = relu_out_ex;
            default: res_out = mul_out_trunc;
        endcase
    end

    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset) begin
            acc_reg <= 'd0;        
        end if(enable_acc) begin
            acc_reg <= res_out;
        end
    end

    logic [11:0] wb_sat8_in;
    assign wb_sat8_in = mux_comb ? res_out : acc_reg;

    //sat_unit #(.W_IN(12), .W_OUT(8)) wb_sat8 (wb_sat8_in, r);
    assign r = wb_sat8_in[7:0]; // Don't handle overflow at end unless selected

endmodule
