// NOTE (Matthew Johns) - there is similarity between parts of this code and the
// proc_unit.sv module made by me in my third-year project. This is because the
// functionality is similar and therefore I'm using what I learnt previously.

// `include "defs.sv"
import accelerator_pkg::*;

module pe_32 (
    output logic [31:0] out
    // output logic flag_saturated // TODO: add this flag for CSRs
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input pe_arith_op_t op,
    input wire [1:0] vsew,
    input wire [1:0] widening, // 2'd1 for widening, 2'd2 for quad widening
    input wire [1:0] mul_us, // Specifies each multiplier input as signed or unsigned
    input pe_saturation_mode_t saturate_mode,
    input pe_output_mode_t output_mode,
);

// Usually input "a" is vs2, input "b" is vs1 and "c" is vs3/vd. (This is for
// most standard arithmetic operations)

logic signed [32:0] mult_a;
logic signed [32:0] mult_b;
logic signed [65:0] mult_wide;
logic signed [32:0] selected_mult_out;

logic [32:0] add_out;
logic [32:0] add_a;
logic [32:0] add_b;
logic [32:0] addend;

// Intermediate before saturation/ReLU
// Has to be 33 bits to give at least one bit for saturation
logic [32:0] arith_result;

logic macc;
logic subtract;

// Instantiate sign extension module for inputs a, b and c
wire [31:0] sign_ext_a;
wire [31:0] sign_ext_b;
wire [31:0] sign_ext_c;
vw_sign_ext se0 (
    .sign_ext_a(sign_ext_a),
    .sign_ext_b(sign_ext_b),
    .sign_ext_c(sign_ext_c),
    .a(a),
    .b(b),
    .c(c),
    .vsew(vsew)
);

////////////////////////////////////////////////////////////////////////////////
// ARITHMETIC STAGE
////////////////////////////////////////////////////////////////////////////////
always_comb
begin
    subtract = 1'b0;
    macc = 1'b0;
    arith_result = 1'b0;

    case (op)
        // 4'h0: // Add
        PE_ARITH_ADD:
            arith_result = add_out;
        // 4'h1: // Sub
        PE_ARITH_SUB:
        begin
            arith_result = add_out;
            subtract = 1'b1;
        end
        // 4'h2: // Left-shift
        PE_ARITH_LSHIFT:
            arith_result = {1'b0, (a << b)};
        // 4'h3: // Multiply
        PE_ARITH_MUL:
            arith_result = selected_mult_out;
        // 4'h4: // Multiply-add
        PE_ARITH_MULADD:
        begin
            macc = 1'b1;
            arith_result = add_out;
        end
        // 4'h5: // XOR
        PE_ARITH_XOR:
            arith_result = {1'b0, (a ^ b)};
        // 4'h6: // Right-shift
        PE_ARITH_RSHIFT_LOG:
            arith_result = {1'b0, (a >> b)};
        // 4'h7: // Right-shift (arithmetic)
        PE_ARITH_RSHIFT_AR:
            arith_result = {1'b0, (a >>> b)};
        // 4'h8: // OR
        PE_ARITH_OR:
            arith_result = {1'b0, (a | b)};
        // 4'h9: // AND
        PE_ARITH_AND:
            arith_result = {1'b0, (a & b)};
    endcase
end

always_comb
begin
    // Multiplier needs to be able to be toggled between signed/unsigned for the
    // individual operands (depending on instructions). Can do this by adding an
    // extra bit to the inputs and sign-extending them for signed operations.
    // Then take the correct number of bits from the bottom.
    if (mul_us[1])
        mult_a = {1'b0, a};
    else
        mult_a = {sign_ext_a[31], sign_ext_a};
    if (mul_us[0])
        mult_b = {1'b0, b};
    else
        mult_b = {sign_ext_b[31], sign_ext_b};

    mult_wide = mult_a * mult_b;

    // Select adder inputs
    if (macc)
    begin
        add_a = {1'b0, mult_wide[31:0]};
        add_b = {1'b0, c};
    end
    else if (saturate_mode != PE_SAT_NONE)
    begin
        // Need to sign extend for saturated ops as another bit is gained to be
        // used for saturation. Technically this means this instruction is always
        // a signed operation. Would have to split this up if wanted to toggle
        add_a = {a[31], a};
        add_b = {b[31], b};
    end
    else
    begin
        add_a = {1'b0, a};
        add_b = {1'b0, b};
    end

    if (subtract)
        addend = ~add_b + 1'b1;
    else
        addend = add_b;
    add_out = add_a + addend;

end

// Select multiplier output. V spec requires fractional saturating multiplies to
// take the upper bits for saturation instead of lower bits. Should be able to
// toggle this as we might need to saturate it and keep lower bits later on
always_comb
begin
    if (saturate_mode == PE_SAT_UPPER)
        case (vsew)
            2'd0: // 8b
                selected_mult_out = {{24{1'b0}}, mult_wide[8:0]};
            2'd1: // 16b
                selected_mult_out = {{16{1'b0}}, mult_wide[16:0]};
            2'd2: // 32b
                selected_mult_out = mult_wide[33:0];
            default:
                selected_mult_out = mult_wide[33:0];
        endcase
    else
        selected_mult_out = mult_wide[33:0];
end

////////////////////////////////////////////////////////////////////////////////
// SATURATE STAGE
////////////////////////////////////////////////////////////////////////////////
logic [31:0] sat_result;
// Instantiate the saturation blocks. One for each element width. Output is
// selected from one of them at a time.
wire [7:0] sat8_result;
sat_unit #(
    .W_IN(33),
    .W_OUT(8)
) sat8
(
    .a_in(arith_result),
    .a_out(sat8_result)
);
wire [15:0] sat16_result;
sat_unit #(
    .W_IN(33),
    .W_out(16)
) sat16
(
    .a_in(arith_result),
    .a_out(sat16_result)
);
wire [31:0] sat32_result;
sat_unit #(
    .W_IN(33),
    .W_OUT(32)
) sat32
(
    .a_in(arith_result),
    .a_out(sat32_result)
);

always_comb
begin
    sat_result = arith_result[31:0];
    // For widening, need to saturate to next larger element size
    if (widening[0])
        case (vsew)
            2'd0: // 8b -> 16b
                sat_result = sat16_result;
            2'd1: // 16b -> 32b
                sat_result = sat32_result;
        endcase
    // Quad widening should always use 32b
    else if (widening[1])
        sat_result = sat32_result;
    // For non-widening, use vsew
    else
        case (vsew)
            2'd0: // 8b
                sat_result = sat8_result;
            2'd1: // 16b
                sat_result = sat16_result;
            2'd2: // 32b
                sat_result = sat32_result;
        endcase
end

////////////////////////////////////////////////////////////////////////////////
// OUTPUT MODE SELECT
////////////////////////////////////////////////////////////////////////////////
always_comb
begin
    out = arith_result;
    case (output_mode)
        PE_OP_MODE_RESULT:
            if (saturate_mode == PE_SAT_NONE)
                out = arith_result;
            else
                out = sat_result;
        PE_OP_MODE_PASS_MAX:
            // Will do arithmetic op of a-b. If negative, b is larger so pass b
            if (arith_result[31])
                out = b;
            else
                out = a;
        PE_OP_MODE_PASS_MIN:
            if (arith_result[31])
                out = a;
            else
                out = b;
            // Important point for this: am looking at bit 31 (not 32) because
            // the inputs aren't sign-extended for anything non-saturating.
    endcase
end

endmodule
