// W_IN must be larger than W_OUT
module sat_unit #(parameter W_IN = 13, parameter W_OUT = 8) 
    (input logic signed [W_IN-1:0] a_in, 
     output logic signed [W_OUT-1:0] a_out);
    
    logic signed [W_IN-1:0] max_in = {{(W_IN-W_OUT+1){1'b0}},{(W_OUT-1){1'b1}}}; 
    logic signed [W_IN-1:0] min_in = {{(W_IN-W_OUT+1){1'b1}},{(W_OUT-1){1'b0}}};
    logic signed [W_OUT-1:0] max_out = {1'b0,{(W_OUT-1){1'b1}}}; 
    logic signed [W_OUT-1:0] min_out = {1'b1,{(W_OUT-1){1'b0}}};

    assign a_out = a_in < min_in ? min_out : (a_in > max_in) ? max_out : a_in[W_OUT-1:0];

    //initial $display("%d, %d, %d, %d", max_in, min_in, max_out, min_out);

endmodule