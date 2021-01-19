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

`include "bit_ext.sv"

module tb_bit_ext;

logic signed [7:0] in;
logic signed [11:0] out; 
bit_ext #(.W_IN(8), .W_OUT(12)) bit_ext(in, out);

initial begin
    `ifndef VERILATOR
        $dumpfile("bit_ext.vcd");
        $dumpvars;
    `endif

    for(in = -128; in < 127; in++) begin
        #1ns $display("%d, %d", in, out);
    end

    $finish;
end

endmodule
