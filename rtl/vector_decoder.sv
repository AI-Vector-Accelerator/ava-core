// `include "defs.sv"
import accelerator_pkg::*;

module vector_decoder (
    output logic apu_rvalid,
    output logic apu_gnt,
    output logic [31:0] scalar_operand1,
    output logic [31:0] scalar_operand2,
    output logic [10:0] immediate_operand,
    output logic [4:0] vs1_addr,
    output logic [4:0] vs2_addr,
    output logic [4:0] vd_addr,
    output logic csr_write,
    output logic preserve_vl,
    output logic set_vl_max,
    output logic [1:0] elements_to_write,
    output logic [1:0] cycle_count,
    output logic vec_reg_write,
    output vreg_wb_src_t vd_data_src,
    output pe_arith_op_t pe_op,
    output pe_saturate_mode_t saturate_mode,
    output pe_output_mode_t output_mode,
    output pe_operand_t operand_select,
    output logic [1:0] pe_mul_us,
    output logic [1:0] widening,
    output apu_result_src_t apu_result_select,
    input wire clk,
    input wire n_reset,
    input wire apu_req,
    input wire [31:0] apu_operands [2:0],
    input wire [5:0] apu_op,
    input wire [14:0] apu_flags_i,
    input wire [4:0] vl,
    input wire [1:0] vsew,
    output logic vlsu_en_o,
    output logic vlsu_load_o,
    output logic vlsu_store_o,
    output logic vlsu_strided_o,
    input logic vlsu_ready_i,
    output logic core_halt_o
);

enum {WAIT, EXEC, VALID} state, next_state;

logic [1:0] max_cycle_count;
// logic [1:0] cycle_count;
logic multi_cycle_instr;
logic fix_vd_addr;

// Registers to store values from APU interface during instruction execution
logic [31:0] reg_apu_operands [2:0];
logic [5:0] reg_apu_op;
logic [14:0] reg_apu_flags_i;

// Assign variables for individual parts of instructions for readability
logic [2:0] funct3;
logic [6:0] major_opcode;
logic [5:0] funct6;
logic [4:0] source1;
logic [4:0] source2;
logic [4:0] destination;
logic [2:0] mop; // Vector Addressing Mode
assign funct3 = reg_apu_operands[0][14:12];
assign major_opcode = reg_apu_operands[0][6:0];
assign funct6 = reg_apu_operands[0][31:26];
assign source1 = reg_apu_operands[0][19:15];
assign source2 = reg_apu_operands[0][24:20];
assign destination = reg_apu_operands[0][11:7];
assign mop = funct6[2:0];

assign scalar_operand1 = reg_apu_operands[1];
assign scalar_operand2 = reg_apu_operands[2];

always_ff @(posedge clk, negedge n_reset)
    if(~n_reset)
    begin
        state <= WAIT;
        reg_apu_operands <= '{3{'0}};
        reg_apu_op <= '0;
        reg_apu_flags_i <= '0;
    end
    else
    begin
        state <= next_state;

        // In wait state, can load data from APU interface ready for the next
        // instruction. Only do this when it's valid, otherwise will screw any
        // invalid instruction checking code
        if ((state == WAIT) & apu_req)
        begin
            reg_apu_operands[0] <= apu_operands[0];
            reg_apu_operands[1] <= apu_operands[1];
            reg_apu_operands[2] <= apu_operands[2];
            reg_apu_op <= apu_op;
            reg_apu_flags_i <= apu_flags_i;
        end
    end

logic core_halt_ctrl;

assign core_halt_o = core_halt_ctrl;

/*always_ff @(posedge clk, negedge n_reset) begin
    if(~n_reset)
        core_halt_o <= 1'b0;
    else
        core_halt_o <= core_halt_ctrl;
end*/

always_comb
begin
    apu_rvalid = 1'b0;
    apu_gnt = 1'b0;
    next_state = state;
    core_halt_ctrl = 1'b0;

    case (state)
        WAIT:
        begin
            apu_gnt = 1'b1;
            if (apu_req)
                next_state = EXEC;
            else
                next_state = WAIT;
        end
        EXEC:
        begin
            core_halt_ctrl = 1'b1;
            if (cycle_count == max_cycle_count) begin
                if (vlsu_load_o | vlsu_store_o) begin
                    if(vlsu_ready_i) begin
                        apu_rvalid = 1'b1;
                        next_state = WAIT;
                    end
                end else begin
                    apu_rvalid = 1'b1;
                    next_state = WAIT;
                end
            end
        end
    endcase
end

// VECTOR REGISTER ADDRESS GENERATION
always_ff @(posedge clk, negedge n_reset)
    if (~n_reset)
    begin
        cycle_count <= '0;
    end
    else
    begin
        if (state == WAIT)
            cycle_count <= '0;
        else
            if((vlsu_load_o | vlsu_store_o) & vlsu_ready_i | ~(vlsu_load_o | vlsu_store_o))
                cycle_count <= cycle_count + 1'b1;
            else
                cycle_count <= cycle_count;

    end


logic [3:0] vl_zero_indexed;

always_comb
begin
    // Subtract 1 because if VL=4/8/16 it will want another cycle otherwise
    // Number of loads dependant on SEW (For contiguous 8-bit values)
    // TODO: Determine strided count
    // vl_zero_indexed = (vl - 1'b1) >> (2'd2 - vsew); // Used for memory
    vl_zero_indexed = vl - 1'b1;
    // Elements can be handled 4 at a time so divide VL by 4, or force 0
    max_cycle_count = multi_cycle_instr ? vl_zero_indexed[3:2] : 2'd0;

    case (vsew)
        2'd0: // 8b
        begin
            vs1_addr = source1 + cycle_count;
            vs2_addr = source2 + cycle_count;
            if (fix_vd_addr)
                vd_addr = destination;
            else
                vd_addr = destination + cycle_count;
        end
        2'd1: // 16b
        begin
            vs1_addr = source1 + {cycle_count, 1'b0};
            vs2_addr = source2 + {cycle_count, 1'b0};
            if (fix_vd_addr)
                vd_addr = destination;
            else
                vd_addr = destination + {cycle_count, 1'b0};
        end
        default:
        begin
            vs1_addr = source1 + cycle_count;
            vs2_addr = source2 + cycle_count;
            if (fix_vd_addr)
                vd_addr = destination;
            else
                vd_addr = destination + cycle_count;
        end
    endcase

    if (funct3 == V_OPCFG)
        immediate_operand = reg_apu_operands[0][30:20];
    else
        immediate_operand = {'0, reg_apu_operands[0][19:15]};
end

always_comb
begin
    elements_to_write = 2'd0;

    if (multi_cycle_instr)
    begin
        if (cycle_count == max_cycle_count)
            if (operand_select == PE_OPERAND_RIPPLE)
            // Reductions only want to write in last cycle to only one element
                elements_to_write = 2'd1;
            else
            // On last cycle, work out how many elements remain
                elements_to_write = vl[1:0];
        else
            elements_to_write = 2'd0;
    end
end

////////////////////////////////////////////////////////////////////////////////
// ACCELERATOR CONTROL SIGNALS
always_comb
begin
    // Assign defaults for when not executing
    csr_write = 1'b0;
    preserve_vl = 1'b0;
    set_vl_max = 1'b0;
    vec_reg_write = 1'b0;
    vd_data_src = VREG_WB_SRC_ARITH;
    pe_op = PE_ARITH_ADD;
    operand_select = PE_OPERAND_VS1;
    saturate_mode = PE_SAT_NONE;
    output_mode = PE_OP_MODE_RESULT;
    pe_mul_us = 2'b00;
    widening = 2'b00;
    apu_result_select = APU_RESULT_SRC_VL;
    multi_cycle_instr = 1'b0;

    vlsu_en_o = 1'b0;
    vlsu_load_o = 1'b0;
    vlsu_store_o = 1'b0;
    vlsu_strided_o = 1'b0;

    // Used to control decoder module itself
    fix_vd_addr = 1'b0;

    // Control signals during instruction execution
    if (state == EXEC)
    begin
        if (major_opcode == V_MAJOR_LOAD_FP)
        begin
            if(funct3 == 3'b111) begin
                vd_data_src = VREG_WB_SRC_MEMORY;
                multi_cycle_instr = 1'b1;
                vlsu_en_o = 1'b1;
                vlsu_load_o = 1'b1;
                if(mop) vlsu_strided_o = 1'b1;
            end else $error("Unimplemented LOAD_FP instruction");
        end
        else if (major_opcode == V_MAJOR_STORE_FP)
        begin
            if(funct3 == 3'b111) begin
                fix_vd_addr = 1'b1;
                vlsu_en_o = 1'b1;
                vlsu_store_o = 1'b1;
            end else $error("Unimplemented STORE_FP instruction");
        end
        else if (major_opcode == V_MAJOR_OP_V)
        begin
            // Consider vsetvli instructions separately (different format)
            if (funct3 == V_OPCFG)
            begin
                csr_write = 1'b1;
                apu_result_select = APU_RESULT_SRC_VL;
                if (source1 == '0)
                begin
                    if (destination == '0)
                        preserve_vl = 1'b1;
                    else
                        set_vl_max = 1'b1;
                end
            end
            else
            begin
                // Look for all other OP-V instructions
                case (funct6)

                    // vadd, vredsum
                    6'b000000:
                    begin
                        pe_op = PE_ARITH_ADD;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        // vadd.vv
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        // vadd.vx
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == V_OPMVV) // vredsum
                        begin
                            operand_select = PE_OPERAND_RIPPLE;
                            fix_vd_addr = 1'b1;
                        end
                    end

                    // vsub
                    6'b000010:
                    begin
                        pe_op = PE_ARITH_SUB;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b0;
                    end

                    // vmin
                    6'b000101:
                    begin
                        pe_op = PE_ARITH_SUB;
                        output_mode = PE_OP_MODE_PASS_MIN;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        // Supports vmin.vv and vmin.vx
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    // vmax, vredmax
                    6'b000111:
                    begin
                        pe_op = PE_ARITH_SUB;
                        vec_reg_write = 1'b1;
                        output_mode = PE_OP_MODE_PASS_MAX;
                        multi_cycle_instr = 1'b1;
                        // vredmax
                        if (funct3 == V_OPMVV)
                        begin
                            fix_vd_addr = 1'b1;
                            operand_select = PE_OPERAND_RIPPLE;
                        end
                        // Supports vmax.vv and vmax.vx
                        else if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    // vand
                    6'b001001:
                    begin
                        pe_op = PE_ARITH_AND;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // vor
                    6'b001010:
                    begin
                        pe_op = PE_ARITH_OR;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // vxor
                    6'b001011:
                    begin
                        pe_op = PE_ARITH_XOR;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // VWXUNARY0 (vmv.x.s)
                    6'b010000:
                    begin
                        apu_result_select = APU_RESULT_SRC_VS2_0;
                    end

                    // vmv.v
                    6'b010111:
                    begin
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        vd_data_src = VREG_WB_SRC_SCALAR;
                        // vmv.v.i
                        if (funct3 == V_OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                        // vmv.v.x
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    // vsadd
                    6'b100001:
                    begin
                        pe_op = PE_ARITH_ADD;
                        saturate_mode = PE_SAT;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // vsll
                    6'b100101:
                    begin
                        // Different variants???
                        pe_op = PE_ARITH_LSHIFT;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == V_OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vsmul
                    6'b100111:
                    begin
                        pe_op = PE_ARITH_MUL;
                        saturate_mode = PE_SAT_UPPER;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    // vsrl
                    6'b101000:
                    begin
                        pe_op = PE_ARITH_RSHIFT_LOG;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == V_OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vsra
                    6'b101001:
                    begin
                        pe_op = PE_ARITH_RSHIFT_AR;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == V_OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vwredsum
                    6'b110001:
                    begin
                        pe_op = PE_ARITH_ADD;
                        operand_select = PE_OPERAND_RIPPLE;
                        vec_reg_write = 1'b1;
                        fix_vd_addr = 1'b1;
                        multi_cycle_instr = 1'b1;
                        widening = 2'b01;
                    end

                    // vwmul
                    6'b111011:
                    begin
                        pe_op = PE_ARITH_MUL;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        widening = 2'b01;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == V_OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    default:
                        $error("Unsupported vector instruction");

                endcase
            end
        end
        else
            $error("Unrecognised major opcode");
    end
end

endmodule
