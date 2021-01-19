//
// SPDX-License-Identifier: CERN-OHL-S-2.0+
//
// Copyright (C) 2020-21 Embecosm Limited <www.embecosm.com>
// Contributed by:
// Byron Theobald <bt4g16@soton.ac.uk>
//
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
// A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable
// conditions.
// Source location: https://github.com/AI-Vector-Accelerator
//

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
