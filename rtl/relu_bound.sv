module relu_bound
    #(parameter W=8, parameter N=(6<<4)) 
    (input logic signed [W-1:0] a,  
     output logic [W-2:0] ar);

    logic signed [W-1:0] zero = 'd0;
    always_comb begin
        if(a < zero)
            ar = 0;
        else if (a > N)
            ar = N[6:0];
        else
            ar = a[6:0];
    end  
    
endmodule
