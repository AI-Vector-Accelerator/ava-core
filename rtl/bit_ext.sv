// W_IN must be smaller than W_OUT
module bit_ext #(parameter W_IN = 8, parameter W_OUT = 12) 
    (input logic signed [W_IN-1:0] a_in, 
     output logic signed [W_OUT-1:0] a_out);
    
    assign a_out = {{(W_OUT-W_IN){a_in[W_IN-1]}}, a_in};

endmodule