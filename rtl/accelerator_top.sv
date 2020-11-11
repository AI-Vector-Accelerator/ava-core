`include "defs.sv"

module accelerator_top (
    // Guessing these ports will match the OBI port on the APU
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
pe_arith_op_t op;
pe_saturation_mode_t saturation_mode;
pe_output_mode_t output_mode;
wire pe_ripple_inputs;

// VLSU OUTPUTS

// VECTOR REGISTERS OUTPUTS
wire [127:0] vs1_data;
wire [127:0] vs2_data;
wire [127:0] vs3_data;

// PE OUTPUTS
wire [31:0] pe0_out;
wire [31:0] pe1_out;
wire [31:0] pe2_out;
wire [31:0] pe3_out;
wire [127:0] pe_out_combined;


////////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATION
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////
// CSRs
vector_csrs vcsrs0 (
    .vl(vl),
    .vsew(vsew),
    .vlmul(vlmul)
);

////////////////////////////////////////
// DECODER
vector_decoder vdec0 (
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vd_addr(vd_addr),
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
    .vd_data(),
    .vsew(),
    .elements_to_write(),
    .clk(),
    .n_reset(),
    .write(),
    .widening_op() // Could replace this with widening[1:0] as in PEs
);

////////////////////////////////////////
// PEs
// Need four instances for SIMD. pe0 is least significant.
logic [31:0] pe0_b_data;
logic [31:0] pe1_b_data;
logic [31:0] pe2_b_data;
logic [31:0] pe3_b_data;

// PEs may need different inputs depending on the operation
// a:
// - just vs2_data from vector registers, for now
// - in future may need immediate operands
// b:
// - vs1_data from vector registers
// - output from next-less-significant PE for chained reductions
// - for pe0: vs1[0] for reductions instead
always_comb
begin
    if (pe_ripple_inputs)
    begin
        pe0_b_data = vs1_data[31:0];
        pe1_b_data = pe0_out;
        pe2_b_data = pe1_out;
        pe3_b_data = pe2_out;
    end
    else
    begin
        pe0_b_data = vs1_data[31:0];
        pe1_b_data = vs1_data[63:32];
        pe2_b_data = vs1_data[95:54];
        pe3_b_data = vs1_data[127:96];
    end
end

// Generally the outputs of the PEs are aligned correctly to go into the vector
// registers, with exceptions.
// For reduction operations, the final result comes from pe3, but needs to be in
// the position of the output of pe0 to write into vd[0].
always_comb
begin
    if (pe_ripple_inputs)
        pe_out[31:0] = pe3_out;
    else
        pe_out[31:0] = pe0_out;
    pe_out[63:32] = pe1_out;
    pe_out[95:64] = pe2_out;
    pe_out[127:96] = pe3_out;
end

pe_32b pe0 (
    .out(pe0_out),
    .a(vs2_data[31:0]),
    .b(pe0_b_data),
    .c(vs3_data[31:0]),
    .op(op),
    .vsew(vsew),
    .widening(),
    .mul_us(),
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
    .widening(),
    .mul_us(),
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
    .widening(),
    .mul_us(),
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
    .widening(),
    .mul_us(),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode)
);


endmodule
