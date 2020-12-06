// `include "defs.sv"
import accelerator_pkg::*;

module accelerator_top (
    output logic  [31:0] apu_result,
    output logic  [4:0]  apu_flags_o,
    output logic         apu_gnt,
    output logic         apu_rvalid,
    input  wire         clk,
    input  wire         n_reset,
    input  wire         apu_req,
    input  wire  [2:0][31:0] apu_operands_i,
    input  wire  [5:0]  apu_op,
    input  wire  [14:0] apu_flags_i,
    output wire         data_req_o,
    input  wire         data_gnt_i,
    input  wire         data_rvalid_i,
    output wire         data_we_o,
    output wire  [3:0]  data_be_o,
    output wire  [31:0] data_addr_o,
    output wire  [31:0] data_wdata_o,
    input  wire  [31:0] data_rdata_i
);

////////////////////////////////////////////////////////////////////////////////
// OUTPUT VARIABLE DECLARATIONS
////////////////////////////////////////////////////////////////////////////////

// CSR OUTPUTS
wire [4:0] vl;
wire [1:0] vsew;
wire [1:0] vlmul;

// DECODER OUTPUTS
wire [31:0] scalar_operand1;
wire [31:0] scalar_operand2;
wire [10:0] immediate_operand;
wire [4:0] vs1_addr;
wire [4:0] vs2_addr;
wire [4:0] vd_addr;
wire csr_write;
wire preserve_vl;
wire set_vl_max;
wire [1:0] elements_to_write;
wire [1:0] cycle_count;
wire vec_reg_write;
vreg_wb_src_t vd_data_src;
pe_arith_op_t pe_op;
pe_saturate_mode_t saturate_mode;
pe_output_mode_t output_mode;
pe_operand_t operand_select;
wire [1:0] pe_mul_us;
wire [1:0] widening;
apu_result_src_t apu_result_select;

// VLSU OUTPUTS
wire [127:0] vlsu_wdata;
logic vec_reg_write_lsu;

logic [4:0] vl_next_comb;

// VECTOR REGISTERS OUTPUTS
wire [127:0] vs1_data;
wire [127:0] vs2_data;
wire [127:0] vs3_data;

// ARITHMETIC STAGE OUTPUTS
wire [127:0] arith_output;
wire [127:0] replicated_scalar;

////////////////////////////////////////////////////////////////////////////////
// MODULE INSTANTIATION
////////////////////////////////////////////////////////////////////////////////

wire [31:0] apu_operands [2:0];
assign apu_operands[0] = apu_operands_i[0];
assign apu_operands[1] = apu_operands_i[1];
assign apu_operands[2] = apu_operands_i[2];

////////////////////////////////////////
// CSRs
vector_csrs vcsrs0 (
    .vl(vl),
    .vsew(vsew),
    .vlmul(vlmul),
    .vl_next_comb(vl_next_comb),
    .clk(clk),
    .n_reset(n_reset),
    .avl_in(scalar_operand1),
    .vtype_in(immediate_operand[4:0]),
    .write(csr_write),
    .saturate_flag(1'b0),
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
    .immediate_operand(immediate_operand),
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vd_addr(vd_addr),
    .csr_write(csr_write),
    .preserve_vl(preserve_vl),
    .set_vl_max(set_vl_max),
    .elements_to_write(elements_to_write),
    .cycle_count(cycle_count),
    .vec_reg_write(vec_reg_write),
    .vd_data_src(vd_data_src),
    .pe_op(pe_op),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode),
    .operand_select(operand_select),
    .pe_mul_us(pe_mul_us),
    .widening(widening),
    .apu_result_select(apu_result_select),
    .clk(clk),
    .n_reset(n_reset),
    .apu_req(apu_req),
    .apu_operands(apu_operands),
    .apu_op(apu_op),
    .apu_flags_i(apu_flags_i),
    .vl(vl),
    .vsew(vsew),
    .vlsu_en_o(vlsu_en),
    .vlsu_load_o(vlsu_load),
    .vlsu_store_o(vlsu_store),
    .vlsu_strided_o(vlsu_strided),
    .vlsu_ready_i(vlsu_ready)
);

////////////////////////////////////////
// VECTOR REGISTERS
logic [127:0] vd_data;
always_comb
    case (vd_data_src)
        VREG_WB_SRC_MEMORY:
            vd_data = vlsu_wdata;
        VREG_WB_SRC_ARITH:
            vd_data = arith_output;
        VREG_WB_SRC_SCALAR:
            vd_data = replicated_scalar;
        default:
            vd_data = '0;
    endcase

vector_registers vreg0 (
    .vs1_data(vs1_data),
    .vs2_data(vs2_data),
    .vs3_data(vs3_data),
    .vd_data(vd_data),
    .vs1_addr(vs1_addr),
    .vs2_addr(vs2_addr),
    .vd_addr(vd_addr),
    .vsew(vsew),
    .elements_to_write(elements_to_write),
    .clk(clk),
    .n_reset(n_reset),
    .write(vec_reg_write | vec_reg_write_lsu ),
    .widening_op(widening[0])
);

////////////////////////////////////////
// PEs CONTAINED IN ARITHMETIC STAGE WRAPPER
arith_stage arith_stage0 (
    .arith_output(arith_output),
    .replicated_scalar(replicated_scalar),
    .clk(clk),
    .n_reset(n_reset),
    .vs1_data(vs1_data),
    .vs2_data(vs2_data),
    .vs3_data(vs3_data),
    .scalar_operand(scalar_operand1),
    .imm_operand(immediate_operand[4:0]),
    .elements_to_write(elements_to_write),
    .cycle_count(cycle_count),
    .op(pe_op),
    .saturate_mode(saturate_mode),
    .output_mode(output_mode),
    .operand_select(operand_select),
    .widening(widening),
    .mul_us(pe_mul_us),
    .vl(vl),
    .vsew(vsew)
);

////////////////////////////////////////
// VLSU
vector_lsu vlsu0 (
    .clk(clk),
    .n_reset(n_reset),

    .vl_i(vl),
    .vsew_i(vsew),
    .vlmul_i(vlmul),

    .vlsu_en_i(vlsu_en),
    .vlsu_load_i(vlsu_load),
    .vlsu_store_i(vlsu_store),
    .vlsu_strided_i(vlsu_strided),
    .vlsu_ready_o(vlsu_ready),

    .data_req_o(data_req_o),
    .data_gnt_i(data_gnt_i),
    .data_rvalid_i(data_rvalid_i),
    .data_addr_o(data_addr_o),
    .data_we_o(data_we_o),
    .data_be_o(data_be_o),
    .data_rdata_i(data_rdata_i),
    .data_wdata_o(data_wdata_o),

    .cycle_count_i(cycle_count),

    .op0_data_i(scalar_operand1),
    .op1_data_i(scalar_operand2),

    .vs_wdata_o(vlsu_wdata),
    .vs_rdata_i(vs3_data),
    .vr_addr_i(vd_addr),
    .vr_we_o(vec_reg_write_lsu)
);

////////////////////////////////////////////////////////////////////////////////
// RESULT SELECTION - what value to return to CPU
////////////////////////////////////////////////////////////////////////////////
logic [31:0] reg_apu_result;
assign apu_flags_o = '0;
assign apu_result = reg_apu_result;

/*always_ff @(posedge clk, negedge n_reset)
    if (~n_reset)
        reg_apu_result <= '0;
    else
    begin
        case (apu_result_select)
            APU_RESULT_SRC_VL:
                reg_apu_result <= {'0, vl};
            APU_RESULT_SRC_VS2_0:
                case (vsew)
                    2'd0: // 8b
                        reg_apu_result <= { {24{1'b0}}, vs2_data[7:0] };
                    2'd1: // 16b
                        reg_apu_result <= { {16{1'b0}}, vs2_data[15:0] };
                    2'd2:// 32b
                        reg_apu_result <= vs2_data[31:0];
                endcase
        endcase
    end*/

// Updated VL is arriving two cycles too late

always_comb begin
    case (apu_result_select)
        APU_RESULT_SRC_VL:
            reg_apu_result = {'0, vl_next_comb};
        APU_RESULT_SRC_VS2_0:
            case (vsew)
                2'd0: // 8b
                    reg_apu_result = { {24{1'b0}}, vs2_data[7:0] };
                2'd1: // 16b
                    reg_apu_result = { {16{1'b0}}, vs2_data[15:0] };
                2'd2:// 32b
                    reg_apu_result = vs2_data[31:0];
            endcase
    endcase
end


endmodule
