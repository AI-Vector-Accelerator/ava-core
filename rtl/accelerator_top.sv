// `include "defs.sv"
import accelerator_pkg::*;

module accelerator_top (
    output logic [31:0] apu_result,
    output logic [4:0] apu_flags_o,
    output logic apu_gnt,
    output logic apu_rvalid,
    input wire clk,
    input wire n_reset,
    input wire apu_req,
    input wire [31:0] apu_operands [2:0],
    input wire [5:0] apu_op,
    input wire [14:0] apu_flags_i
);

////////////////////////////////////////////////////////////////////////////////
// OUTPUT VARIABLE DECLARATIONS
////////////////////////////////////////////////////////////////////////////////

// CSR OUTPUTS
wire [4:0] vl;
wire [1:0] vsew;
wire [1:0] vlmul;

// DECODER OUTPUTS
wire [4:0] vs1_addr;
wire [4:0] vs2_addr;
wire [4:0] vd_addr;
wire [31:0] scalar_operand1;
wire [31:0] scalar_operand2;
wire csr_write;
wire preserve_vl;
wire set_vl_max;
wire [1:0] elements_to_write;
wire vec_reg_write;
wire vec_reg_widening; // Could be replaced with widening[1:0] used for PE
pe_arith_op_t pe_op;
pe_saturation_mode_t saturation_mode;
pe_output_mode_t output_mode;
wire pe_ripple_inputs;
wire [1:0] pe_mul_us;
wire [1:0] pe_widening;

// VLSU OUTPUTS

// VECTOR REGISTERS OUTPUTS
wire [127:0] vs1_data;
wire [127:0] vs2_data;
wire [127:0] vs3_data;

// ARITHMETIC STAGE OUTPUTS
wire [127:0] arith_out;

////////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATION
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////
// CSRs
vector_csrs vcsrs0 (
    .vl(vl),
    .vsew(vsew),
    .vlmul(vlmul),
    .clk(clk),
    .n_reset(n_reset),
    .avl_in(), // needs to be rs1 data
    .vtype_in(), // needs to come from immediate argument
    .write(csr_write),
    .saturate_flag(),
    .preserve_vl(preserve_vl),
    .set_vl_max(set_vl_max)
);

////////////////////////////////////////
// DECODER
vector_decoder vdec0 (
    .apu_rvalid(apu_rvalid),
    .apu_gnt(apu_gnt),
    .scalar_operand1(scalar_operand1),
    .scalar_operand2(scalar_operand2),
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vd_addr(vd_addr),
    .clk(clk),
    .n_reset(n_reset),
    .apu_req(apu_req),
    .apu_operands(apu_operands),
    .apu_op(apu_op),
    .apu_flags_i(apu_flags_i),
    .vl(vl),

    .pe_ripple_inputs(pe_ripple_inputs),
);

////////////////////////////////////////
// VLSU

////////////////////////////////////////
// VECTOR REGISTERS
vector_registers vreg0 (
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vs3_data(vs3_data),
    .vd_data(), // Presumably this will need some muxing
    .vsew(vsew),
    .elements_to_write(elements_to_write),
    .clk(clk),
    .n_reset(n_reset),
    .write(vec_reg_write),
    .widening_op(vec_reg_widening) // Could replace this with widening[1:0] as in PEs
);

////////////////////////////////////////
// PEs CONTAINED IN ARITHMETIC STAGE WRAPPER
arith_stage arith_stage0 (
    .arith_output(arith_out),
    .clk(clk),
    .n_reset(n_reset),
    .vs1_data(vs1_data),
    .vs2_data(vs2_data),
    .vs3_data(vs3_data),
    .scalar_operand(scalar_operand1),
    .imm_operand(), //////////
    .elements_to_write(elements_to_write),
    .cycle_count(cycle_count),
    .op(pe_op),
    .saturation_mode(saturation_mode),
    .output_mode(output_mode),
    .operand_select(operand_select),
    .widening(pe_widening),
    .mul_us(pe_mul_us),
    .vl(vl)
);

endmodule
