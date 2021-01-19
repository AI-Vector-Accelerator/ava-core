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

// W_IN must be smaller than W_OUT
module bit_ext #(parameter W_IN = 8, parameter W_OUT = 12) 
    (input logic signed [W_IN-1:0] a_in, 
     output logic signed [W_OUT-1:0] a_out);
    
    assign a_out = {{(W_OUT-W_IN){a_in[W_IN-1]}}, a_in};

endmodule
