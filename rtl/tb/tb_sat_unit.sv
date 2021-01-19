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

`include "sat_unit.sv"

module tb_sat_unit;

logic signed [12:0] in;
logic signed  [7:0] out; 
sat_unit #(.W_IN(13), .W_OUT(8)) satu(in, out);

logic signed [7:0] i;

initial begin
    `ifndef VERILATOR
        $dumpfile("sat_unit.vcd");
        $dumpvars;
    `endif

    for(in = -256; in < 256; in++) begin
        #1ns $display("%d, %d", in, out);
    end

    $finish;
end

endmodule
