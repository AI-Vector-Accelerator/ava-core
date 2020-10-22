module relu_bound
    #(parameter W=8) 
    (input signed [W-1:0] a, 
     input signed [W-1:0] n, 
     output signed [W-1:0] ar);

    logic signed [W-1:0] zero_signed = 'd0;
    always_comb begin
        if(a < zero_signed)
            ar = 0;
        else if (a > n)
            ar = n;
        else
            ar = a;
    end  
    
endmodule
