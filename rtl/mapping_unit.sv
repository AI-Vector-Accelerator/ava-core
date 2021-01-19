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

module mapping_unit
   (input logic [127:0] arith_format_o,
    output  logic [31:0] memory_format_i,
    input  logic [1:0] sew_i,
    input  logic [1:0] reg_select);

    


    
                vd_wr_data0 = '{
                    vd_data[103:96],
                    vd_data[71:64],
                    vd_data[39:32],
                    vd_data[7:0]
                };
            2'd1: // 16b
            begin
                vd_wr_data1 = {
                    vd_data[111:96],
                    vd_data[79:64]
                };
                vd_wr_data0 = {
                    vd_data[47:32],
                    vd_data[15:0]
                };
            end
            2'd2: // 32b
            begin
                vd_wr_data3 = vd_data[127:96];
                vd_wr_data2 = vd_data[95:64];
                vd_wr_data1 = vd_data[63:32];
                vd_wr_data0 = vd_data[31:0];*/
endmodule 
