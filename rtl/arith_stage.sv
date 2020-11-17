// Module instance to contain the PEs and supporting logic such as input/output
// selection logic. This is just to tidy up the top-level a bit.

import accelerator_pkg::*;

module arith_stage (
    output logic [127:0] arith_output,
    input wire clk,
    input wire n_reset,
    input wire [127:0] vs1_data,
    input wire [127:0] vs2_data,
    input wire [127:0] vs3_data,
    input wire [31:0] scalar_operand,
    input wire [4:0] imm_operand,
    // input wire pe_ripple_inputs,
    input wire [1:0] elements_to_write,
    input wire [1:0] cycle_count,
    input pe_arith_op_t op,
    input pe_saturate_mode_t saturation_mode,
    input pe_output_mode_t output_mode,
    input pe_operand_t operand_select,
    input wire [1:0] widening,
    input wire 1:0] mul_us,
    input wire [2:0] vl,

);

logic [31:0] reduction_intermediate_reg;

logic [127:0] replicated_scalar;

wire [31:0] pe0_out;
wire [31:0] pe1_out;
wire [31:0] pe2_out;
wire [31:0] pe3_out;

logic [31:0] pe0_b_data;
logic [31:0] pe1_b_data;
logic [31:0] pe2_b_data;
logic [31:0] pe3_b_data;

pe_32b pe0 (
    .out(pe0_out),
    .a(vs2_data[31:0]),
    .b(pe0_b_data),
    .c(vs3_data[31:0]),
    .op(op),
    .vsew(vsew),
    .widening(pwidening),
    .mul_us(mul_us),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode)
);

pe_32b pe1 (
    .out(pe1_out),
    .a(vs2_data[63:32]),
    .b(pe1_b_data),
    .c(vs3_data[63:32]),
    .op(op),
    .vsew(vsew),
    .widening(widening),
    .mul_us(mul_us),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode)
);

pe_32b pe2 (
    .out(pe2_out),
    .a(vs2_data[95:64]),
    .b(pe2_b_data),
    .c(vs3_data[95:64]),
    .op(op),
    .vsew(vsew),
    .widening(widening),
    .mul_us(mul_us),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode)
);

pe_32b pe3 (
    .out(pe3_out),
    .a(vs2_data[127:96]),
    .b(pe2_b_data),
    .c(vs3_data[127:96]),
    .op(op),
    .vsew(vsew),
    .widening(widening),
    .mul_us(mul_us),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode)
);

scalar_replicate scalar_rep0 (
    .replicated_out(replicated_scalar),
    .scalar_in(scalar_operand),
    .vsew(vsew)
);

// Update the intermediate register used for reduction operations every cycle
always_ff @(posedge clk, negedge n_reset)
    if (~n_reset)
        reduction_intermediate_reg <= '0;
    else
        reduction_intermediate_reg <= pe3_out;

////////////////////////////////////////////////////////////////////////////////
// PE INPUT OPERAND SELECTION
////////////////////////////////////////////////////////////////////////////////
always_comb
    case (operand_select)
        PE_OPERAND_VS1:
        begin
            pe0_b_data = vs1_data[31:0];
            pe1_b_data = vs1_data[63:32];
            pe2_b_data = vs1_data[95:54];
            pe3_b_data = vs1_data[127:96];
        end
        PE_OPERAND_SCALAR:
        begin
            pe0_b_data = replicated_scalar[31:0];
            pe1_b_data = replicated_scalar[63:32];
            pe2_b_data = replicated_scalar[95:54];
            pe3_b_data = replicated_scalar[127:96];
        end
        PE_OPERAND_IMMEDIATE:
        begin
            pe0_b_data = imm_operand[31:0];
            pe1_b_data = imm_operand[63:32];
            pe2_b_data = imm_operand[95:54];
            pe3_b_data = imm_operand[127:96];
        end
        PE_OPERAND_RIPPLE:
        begin
            // For first cycle of reduction operation want to look at vs1[0].
            // For later cycles need the intermediate value from last cycle.
            if (cycle_count == 2'd0)
                pe0_b_data = vs1_data[31:0];
            else
                pe0_b_data = reduction_intermediate_reg;
            pe1_b_data = pe0_out;
            pe2_b_data = pe1_out;
            pe3_b_data = pe2_out;
        end
    endcase

////////////////////////////////////////////////////////////////////////////////
// PE OUTPUT SELECTION
////////////////////////////////////////////////////////////////////////////////
always_comb
begin
    // For reduction operations the output comes from a single PE (the last in
    // the chain), but which PE is last depends on VL.
    if (operand_select == PE_OPERAND_RIPPLE)
        case (vl[1:0])
            2'd0:
                // Perhaps counterintuitively, if vl[1:0] is zero that means all
                // four elements are being written so want the last PE.
                arith_output = {'0, pe3_out};
            2'd1:
                arith_output = {'0, pe0_out};
            2'd2:
                arith_output = {'0, pe1_out};
            2'd3:
                arith_output = {'0, pe2_out};
            default:
                arith_output = {'0, pe3_out};
        endcase
    else
        arith_output = {pe3_out, pe2_out, pe1_out, pe0_out};
end


endmodule
