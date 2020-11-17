// `include "defs.sv"
import accelerator_pkg::*;

module vector_decoder (
    output logic apu_rvalid,
    output logic apu_gnt,
    output logic [31:0] scalar_operand1;
    output logic [31:0] scalar_operand2;
    output logic [4:0] vs1_addr,
    output logic [4:0] vs2_addr,
    output logic [4:0] vd_addr,
    output logic csr_write,
    output logic preserve_vl,
    output logic set_vl_max,
    output logic [1:0] elements_to_write,
    output logic [1:0] cycle_count,
    output logic vec_reg_write,
    output logic vec_reg_widening, // Could be replaced with pe_widening[1:0]?
    output pe_arith_op_t pe_op,
    output pe_saturation_mode_t saturation_mode,
    output pe_output_mode_t output_mode,
    output pe_operand_t operand_select,
    output logic [1:0] pe_mul_us,
    output logic [1:0] pe_widening,
    input wire clk,
    input wire n_reset,
    input wire apu_req,
    input wire [31:0] apu_operands [2:0],
    input wire [5:0] apu_op,
    input wire [14:0] apu_flags_i,
    input wire [4:0] vl
);

enum logic {WAIT, EXEC} state, next_state;

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
logic [1:0] major_opcode;
logic [5:0] funct6;
logic [4:0] source1;
logic [4:0] source2;
logic [4:0] destination;
assign funct3 = reg_apu_op[5:3];
assign major_opcode = reg_apu_op[1:0];
assign funct6 = reg_apu_operands[0][11:6];
assign source1 = apu_operands[0][19:15];
assign source2 = apu_operands[0][24:20];
assign destination = apu_operands[0][11:7];

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

always_comb
begin
    apu_rvalid = 1'b0;
    apu_gnt = 1'b0;
    next_state = state;

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
            if (cycle_count == max_cycle_count)
            begin
                next_state = WAIT;
                apu_rvalid = 1'b1;
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
            cycle_count <= cycle_count + 1'b1;
    end


always_comb
begin
    if (multi_cycle_instr)
        // Elements can be handled 4 at a time so divide VL by 4
        max_cycle_count = vl[4:2];
    else
    // Force single-cycle instruction
        max_cycle_count = '0;

    if (fix_vd_addr)
    begin
        vs1_addr = source1;
        vs2_addr = source2;
        vd_addr = destination;
    end
    else
    begin
        vs1_addr = source1 + cycle_count;
        vs2_addr = source2 + cycle_count;
        vd_addr = destination + cycle_count;
    end
end

always_comb
begin
    elements_to_write = 2'd0;
    if (multi_cycle_instr)
    begin
        if (cycle_count == max_cycle_count)
        // On last cycle, work out how many elements remain
            elements_to_write = vl[1:0];
        else if (operand_select == PE_OPERAND_RIPPLE)
            elements_to_write = 2'd1;
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
    vec_reg_widening = 1'b0;
    pe_op = PE_ARITH_ADD;
    operand_select = PE_OPERAND_VS1;
    saturation_mode = PE_SAT_NONE;
    output_mode = PE_OP_MODE_RESULT;
    pe_mul_us = 2'b00;
    pe_widening = 2'b00;
    multi_cycle_instr = 1'b0;

    // Used to control decoder module itself
    fix_vd_addr = 1'b0;

    // Control signals during instruction execution
    if (state == EXEC)
    begin
        if (major_opcode == LOAD_FP)
        begin

        end
        else if (major_opcode == STORE_FP)
        begin

        end
        else if (major_opcode == OP_V)
        begin
            // Consider vsetvli instructions separately (different format)
            if (funct3 == V_OPCFG)
            begin
                csr_write = 1'b1;
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
                case (funct6):

                    // vadd, vredsum
                    6'b000000:
                    begin
                        pe_op = PE_ARITH_ADD;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        // vadd.vv
                        // if (funct3 == V_OPIVV)
                        // begin
                            // At some point may need to select imm. operand
                        // end
                        if (funct3 == V_OPMVV) // vredsum
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
                        multi_cycle_instr = 1'b1;
                    end

                    // vmin
                    6'b000101:
                    begin
                        pe_op = PE_ARITH_SUB;
                        output_mode = PE_OP_MODE_PASS_MIN;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // vmax, vredmax
                    6'b000111:
                    begin
                        pe_op = PE_ARITH_SUB;
                        vec_reg_write = 1'b1;
                        output_mode = PE_OP_PASS_MAX;
                        multi_cycle_instr = 1'b1;
                        // vredmax
                        else if (funct3 == V_OPMVV)
                        begin
                            fix_vd_addr = 1'b1;
                            operand_select = PE_OPERAND_RIPPLE;
                        end
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
                        // TODO: honestly don't know what to do for now
                        vec_reg_write = 1'b1;
                    end

                    // vmv (.vi)
                    6'b010111:
                    begin
                        // TODO: honestly don't know what to do for now
                        vec_reg_write = 1'b1;
                    end

                    // vsadd
                    6'b100001:
                    begin
                        pe_op = PE_ARITH_ADD;
                        saturation_mode = PE_SAT;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                    end

                    // vsll
                    6'b100101:
                    begin
                        // Different variants???
                        pe_op = PE_ARITH_SLL;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vsmul
                    6'b100111:
                    begin
                        pe_op = PE_ARITH_MUL;
                        saturation_mode = PE_SAT_UPPER;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                    end

                    // vsrl
                    6'b101000:
                    begin
                        pe_op = PE_ARITH_SRL;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vsra
                    6'b101001:
                    begin
                        pe_op = PE_ARITH_SRA;
                        vec_reg_write = 1'b1;
                        multi_cycle_instr = 1'b1;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == OPIVX)
                            operand_select = PE_OPERAND_SCALAR;
                        else if (funct3 == OPIVI)
                            operand_select = PE_OPERAND_IMMEDIATE;
                    end

                    // vwredsum
                    6'b110001:
                    begin
                        pe_op = PE_ARITH_ADD;
                        pe_ripple_inputs = 1'b1;
                        vec_reg_write = 1'b1;
                        fix_vd_addr = 1'b1;
                        vec_reg_widening = 1'b1;
                        multi_cycle_instr = 1'b1;
                        // Should unify widening here really
                        // pe_widening = 2'b01;
                    end

                    // vwmul
                    6'b111011:
                    begin
                        pe_op = PE_ARITH_MUL;
                        vec_reg_write = 1'b1;
                        vec_reg_widening = 1'b1;
                        multi_cycle_instr = 1'b1;
                        // pe_widening = 2'b01;
                        if (funct3 == V_OPIVV)
                            operand_select = PE_OPERAND_VS1;
                        else if (funct3 == OPIVX)
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
