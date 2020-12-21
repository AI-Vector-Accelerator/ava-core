`timescale 1ns/10ps

`include "address_unit.sv"

module tb_address_unit;
    logic clk_i;
    logic n_rst_i;
    
    logic [1:0] vsew_i;
    logic [4:0] vl_i;
    logic [1:0] vlmul_i;

    logic vlsu_strided;
    logic [31:0] stride;

    logic [31:0] base_addr_i;
    logic [31:0] addr_calc_o;
    logic data_req;
    logic data_rvalid;

    logic au_en;
    logic au_done;

    address_unit au (.*);

    initial begin
        $dumpvars;

        vsew_i = 2'd0;
        vl_i = 5'd0;
        vlmul_i = 2'd0;
        vlsu_strided = 1'b0;
        stride = 32'd0;

        #10ns vsew_i = 2'd0;
        vl_i = 5'd16;
        vlmul_i = 2'd2;

        #10ns vsew_i = 2'd0;
        vl_i = 5'd16;
        vlmul_i = 2'd2;
        vlsu_strided = 1'b1;
        stride = 32'd2;

        #100ns $finish;
    end
endmodule