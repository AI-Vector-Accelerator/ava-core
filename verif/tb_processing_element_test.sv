module tb_processing_element_test;

//////////////////////////////////////////////////////////////////////
// Declare internal signals and instantiate DUT
//////////////////////////////////////////////////////////////////////
logic signed [7:0] a;
logic signed [7:0] b;
logic signed [7:0] c;
logic signed [11:0] tree_l;
logic signed [11:0] tree_r;

logic [1:0] mux_add_a;
logic [1:0] mux_add_b;
logic mux_c_acc;
logic [1:0] mux_sat8;
logic mux_relu;
logic [1:0] mux_res;
logic mux_comb;
logic enable_acc;
logic clk;
logic n_reset;

wire logic signed [7:0] r;
wire logic signed [11:0] tree_o;

processing_element pe0 (
    .a(a),
    .b(b),
    .c(c),
    .tree_l(tree_l),
    .tree_r(tree_r),
    .mux_add_a(mux_add_a),
    .mux_add_b(mux_add_b),
    .mux_c_acc(mux_c_acc),
    .mux_sat8(mux_sat8),
    .mux_relu(mux_relu),
    .mux_res(mux_res),
    .mux_comb(mux_comb),
    .enable_acc(enable_acc),
    .clk(clk),
    .n_reset(n_reset),
    // reset signal???
    .r(r),
    .tree_o(tree_o)
);

//////////////////////////////////////////////////////////////////////
// Test stimulus begins
//////////////////////////////////////////////////////////////////////
`define NUM_TESTS 100

logic [11:0] prev_acc;

initial
begin
    prev_acc = '0;

    randomize_inputs();
    // Initial reset pulse for the accumulator register
    clk = 1'b0;
    n_reset = 1'b1;
    #5ns n_reset = 1'b0;
    #10ns clk = 1'b1;
    #5ns n_reset = 1'b1;
    #10ns clk = 1'b0;
    prev_acc = pe0.acc_reg;

    // Loop for required number of test cases
    for (int i = 0; i < `NUM_TESTS; i++)
    begin
        #10ns clk = 1'b1;
        randomize_inputs();
        // check scores
        #20ns clk = 1'b0;
        prev_acc = pe0.acc_reg;
        #10ns
        // $display("%d %d %d", a, b, r);
        check_output();
        $display("\n");
        // print_test();
    end

    $finish;
end

function void print_test;
    $display("A: %d B: %d C: %d tree_l: %d tree_r: %d", a, b, c, tree_l, tree_r);
    $display("A: %b B: %b C: %b tree_l: %b tree_r: %b", a, b, c, tree_l, tree_r);
    $display("r: %d acc: %d", r, pe0.acc_reg);
    $display("r: %b acc: %b", r, pe0.acc_reg);
    $display("mux_add_a: %d", mux_add_a);
    $display("mux_add_b: %d", mux_add_b);
    $display("mux_c_acc: %d", mux_c_acc);
    $display("mux_sat8: %d", mux_sat8);
    $display("mux_relu: %d", mux_relu);
    $display("mux_res: %d", mux_res);
    $display("mux_comb: %d", mux_comb);
    $display("enable_acc: %d", enable_acc);
    // $display("\n");
endfunction

function void randomize_inputs;
    assert(randomize(a));
    assert(randomize(b));
    assert(randomize(c));
    assert(randomize(tree_l));
    assert(randomize(tree_r));
    assert(randomize(mux_add_a));
    assert(randomize(mux_add_b));
    assert(randomize(mux_c_acc));
    assert(randomize(mux_sat8));
    assert(randomize(mux_relu));
    assert(randomize(mux_res));
    assert(randomize(mux_comb));
    assert(randomize(enable_acc));
endfunction


function void check_output;

    logic signed [15:0] mult_wide;
    logic signed [11:0] mult_res;
    logic signed [12:0] addop_res;
    logic signed [7:0] satop_res;
    logic signed [7:0] relu_res;
    logic signed [7:0] final_res;

    // Calculate the "multiply" component of result
    // Need to remove the extra fractional bits after
    // A*B
    mult_wide = a * b;
    mult_res = mult_wide[15:4];

    // Calculate the "AddOp" part of the result
    if ((mux_add_a == '0) && (mux_add_b == '0))
        // A + B
        addop_res = a + b;
    else if ((mux_add_a == 2'd1) && (mux_add_b == '0))
        // (A*B) + B
        addop_res = (a * b) + b;
    else if ((mux_add_a == 2'd2) && (mux_add_b == '0))
        // Tree_L + B
        addop_res = tree_l + b;
    else if ((mux_add_a == 2'd3) && (mux_add_b == '0))
        // 0 + B
        addop_res = b;
    else if ((mux_add_a == '0) && (mux_add_b == 2'd1) && ~mux_c_acc)
        // A + C
        addop_res = a + c;
    else if ((mux_add_a == '0) && (mux_add_b == 2'd1) && mux_c_acc)
        // A + acc
        addop_res = a + prev_acc;
    else if ((mux_add_a == 2'd1) && (mux_add_b == 2'd1) && ~mux_c_acc)
        // (A*B) + C
        addop_res = (a * b) + c;
    else if ((mux_add_a == 2'd1) && (mux_add_b == 2'd1) && mux_c_acc)
        // (A*B) + acc
        addop_res = (a * b) + prev_acc;
    else if ((mux_add_a == 2'd2) && (mux_add_b == 2'd1) && ~mux_c_acc)
        // Tree_L + C
        addop_res = tree_l + c;
    else if ((mux_add_a == 2'd2) && (mux_add_b == 2'd1) && mux_c_acc)
        // Tree_L + acc
        addop_res = tree_l + prev_acc;
    else if ((mux_add_a == 2'd3) && (mux_add_b == 2'd1) && ~mux_c_acc)
        // 0 + C
        addop_res = c;
    else if ((mux_add_a == 2'd3) && (mux_add_b == 2'd1) && mux_c_acc)
        // 0 + acc
        addop_res = prev_acc;
    else if ((mux_add_a == 2'd0) && (mux_add_b == 2'd2))
        // A + Tree_R
        addop_res = a + tree_r;
    else if ((mux_add_a == 2'd1) && (mux_add_b == 2'd2))
        // (A*B) + Tree_R
        addop_res = (a * b) + tree_r;
    else if ((mux_add_a == 2'd2) && (mux_add_b == 2'd2))
        // Tree_L + Tree_R
        addop_res = tree_l + tree_r;
    else if ((mux_add_a == 2'd3) && (mux_add_b == 2'd2))
        // 0 + Tree_R
        addop_res = tree_r;
    else if ((mux_add_a == 2'd0) && (mux_add_b == 2'd3))
        // A + 0
        addop_res = a;
    else if ((mux_add_a == 2'd1) && (mux_add_b == 2'd3))
        // (A*B) + 0
        addop_res = a * b;
    else if ((mux_add_a == 2'd2) && (mux_add_b == 2'd3))
        // Tree_L + 0
        addop_res = tree_l;
    else if ((mux_add_a == 2'd3) && (mux_add_b == 2'd3))
        // 0 + 0
        addop_res = '0;

    // Calculate "SatOp" result
    if (~mux_c_acc && (mux_sat8 == 2'd0))
        // SAT8(C)
        satop_res = sat8(c);
    else if (mux_c_acc && (mux_sat8 == 2'd0))
        // SAT8(acc)
        satop_res = sat8(prev_acc);
    else if (mux_sat8 == 2'd1)
        // SAT8(A*B)
        satop_res = sat8(mult_res);
    else if (mux_sat8 == 2'd2)
        // SAT8(AddOp)
        satop_res = sat8(addop_res);
    else if (mux_sat8 == 2'd3)
        // SAT8(0)
        satop_res = '0;

    // Calculate ReLUOp result
    if (~mux_relu)
        // ReLU(6,A)
        relu_res = relu6(a);
    else if (mux_relu)
        // ReLU(6, SatOp)
        relu_res = relu6(satop_res);

    if (mux_comb)
        // Choose which output to select and SAT8 it
        case(mux_res)
            2'd0: // Multiply
                final_res = mult_res[7:0];
            2'd1: // AddOp - must be SAT12
                final_res = sat12(addop_res)[7:0];
            2'd2: // satop_res
                final_res = satop_res[7:0];
            2'd3: // ReLUop
                final_res = relu_res[7:0];
        endcase
    else
        final_res = prev_acc[7:0];

    $display("mult_res: %d", mult_res);
    $display("addop_res: %d", addop_res);
    $display("satop_res: %d", satop_res);
    $display("relu_res: %d", relu_res);

    // Check that the SAT8 value matches what RTL is producing
    if (pe0.r == final_res)
    begin
        $display("PASS");
        // return 1'b1;
    end
    else
    begin
        $display("FAIL");
        $display("r: %d Expected: %d", r, final_res);
        print_test();
        // return 1'b0;
    end


endfunction

function logic signed [7:0] sat8;
    input logic signed [12:0] x;
    if (x > 127)
    begin
        $display("SAT8 %d MAX", x);
        return 8'd127;
    end
    else if (x < -128)
    begin
        $display("SAT8 %d MIN", x);
        return -8'd128;
    end
    else
    begin
        $display("SAT8 %d PASS", x);
        return x;
    end
endfunction

function logic signed [11:0] sat12;
    input logic signed [12:0] x;
    if (x > 2047)
    begin
        $display("SAT12 %d MAX", x);
        return 12'd2047;
    end
    else if (x < -2048)
    begin
        $display("SAT12 %d MIN", x);
        return -12'd2048;
    end
    else
    begin
        $display("SAT12 %d PASS", x);
        return x;
    end
endfunction

function logic signed [7:0] relu6;
    input logic signed [7:0] x;
    if (x[7])
        return 8'd0;
    else if (x > (6<<4))
        return 8'b01100000;
    else
        return x;
endfunction

endmodule
