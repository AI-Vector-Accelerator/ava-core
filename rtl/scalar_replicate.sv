//
// SPDX-License-Identifier: CERN-OHL-S-2.0+
//
// Copyright (C) 2020-21 Embecosm Limited <www.embecosm.com>
// Contributed by:
// Matthew Johns <mrj1g17@soton.ac.uk>
//
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
// A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable
// conditions.
// Source location: https://github.com/AI-Vector-Accelerator
//

// import accelerator_pkg::*;

module scalar_replicate (
    output logic [127:0] replicated_out,
    input wire [31:0] scalar_in,
    input wire [1:0] vsew,
    input wire us
);

// When a scalar operand comes into the accelerator there is only one copy of
// it. However, each PE needs a copy for it's calculation, so it must be
// replicated into the right position for each PE. This module does that.

always_comb
    case (vsew)
        2'd0: // 8b
            if (us)
                replicated_out = {
                    24'd0,
                    scalar_in[7:0],
                    24'd0,
                    scalar_in[7:0],
                    24'd0,
                    scalar_in[7:0],
                    24'd0,
                    scalar_in[7:0]
                };
            else
                replicated_out = {
                    {24{scalar_in[7]}},
                    scalar_in[7:0],
                    {24{scalar_in[7]}},
                    scalar_in[7:0],
                    {24{scalar_in[7]}},
                    scalar_in[7:0],
                    {24{scalar_in[7]}},
                    scalar_in[7:0]
                };
        2'd1: // 16b
            if (us)
                replicated_out = {
                    16'd0,
                    scalar_in[15:0],
                    16'd0,
                    scalar_in[15:0],
                    16'd0,
                    scalar_in[15:0],
                    16'd0,
                    scalar_in[15:0]
                };
            else
                replicated_out = {
                    {16{scalar_in[15]}},
                    scalar_in[15:0],
                    {16{scalar_in[15]}},
                    scalar_in[15:0],
                    {16{scalar_in[15]}},
                    scalar_in[15:0],
                    {16{scalar_in[15]}},
                    scalar_in[15:0]
                };
        2'd2: // 32b
            replicated_out = {
                {4{scalar_in}}
            };
        default:
            replicated_out = {'0, scalar_in};
    endcase


endmodule
