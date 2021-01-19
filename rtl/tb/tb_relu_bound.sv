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

`timescale 1ns/10ps

`include "relu_bound.sv"

module tb_relu_bound;

logic signed [7:0] in;
logic [6:0] out; 
relu_bound #(.W(8)) rb(in, out);

logic signed [7:0] i;

initial begin
    `ifndef VERILATOR
        $dumpfile("relu_bound.vcd");
        $dumpvars;
    `endif

    for(in = -128; in < 127; in++) begin
        #10ns $display("%d, %d", in, out);
    end

    $finish;
end

endmodule
