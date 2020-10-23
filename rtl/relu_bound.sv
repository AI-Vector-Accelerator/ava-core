module relu_bound
    #(parameter W=8, parameter N=(6<<4)) 
    (input logic signed [W-1:0] a,  
     output logic signed [W-1:0] ar);

    logic signed [W-1:0] zero_signed = 'd0;
    always_comb begin
        if(a < zero_signed)
            ar = 0;
        else if (a > N)
            ar = N;
        else
            ar = a;
    end  
    
endmodule
