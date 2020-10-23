`timescale 1ns/10ps

`include "relu_bound.sv"

module tb_relu_bound;

logic signed [7:0] in, out; 
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