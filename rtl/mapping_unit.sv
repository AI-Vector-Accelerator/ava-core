module mapping_unit
   (output logic [127:0] arith_format_o,
    input  logic [31:0] memory_format_i,
    input  logic [1:0] sew_i,
    input  logic [1:0] reg_select);

    // Correctly format incoming data
    always_comb begin
        case(sew_i)
            //  8b
            2'd0 : arith_format_o = {24'd0, memory_format_i[31:24], 
                                     24'd0, memory_format_i[23:16], 
                                     24'd0, memory_format_i[15:8 ], 
                                     24'd0, memory_format_i[ 7:0 ] };
            // 16b                         
            2'd1 : arith_format_o = {16'd0, ( reg_select[0]) ? memory_format_i[31:16] : 16'd0,
                                     16'd0, ( reg_select[0]) ? memory_format_i[15:0 ] : 16'd0, 
                                     16'd0, (~reg_select[0]) ? memory_format_i[31:16] : 16'd0, 
                                     16'd0, (~reg_select[0]) ? memory_format_i[15:0 ] : 16'd0 };
            // 32b
            2'd2 : arith_format_o = {(reg_select == 2'd3 ) ? memory_format_i : 32'd0,
                                     (reg_select == 2'd2 ) ? memory_format_i : 32'd0, 
                                     (reg_select == 2'd1 ) ? memory_format_i : 32'd0, 
                                     (reg_select == 2'd0 ) ? memory_format_i : 32'd0 };
        endcase
    end
endmodule 