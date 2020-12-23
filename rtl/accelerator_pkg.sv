package accelerator_pkg;

// Arithmetic operations inside PEs
typedef enum logic [3:0] {
    PE_ARITH_ADD,
    PE_ARITH_SUB,
    PE_ARITH_LSHIFT, // left-shift
    PE_ARITH_MUL,
    PE_ARITH_MULADD, // multiply-add
    PE_ARITH_XOR,
    PE_ARITH_RSHIFT_LOG, // logical right-shift
    PE_ARITH_RSHIFT_AR, // arithmetic right-shift
    PE_ARITH_OR,
    PE_ARITH_AND
} pe_arith_op_t;

// PE output mode
// PE_OP_MODE_RESULT: pass through arithmetic result
// PE_OP_MODE_PASS_MAX: pass larger of operands A and B
// PE_OP_MODE_PASS_MIN: pass smaller of operands A and B
typedef enum logic [1:0] {
    PE_OP_MODE_RESULT,
    PE_OP_MODE_PASS_MAX,
    PE_OP_MODE_PASS_MIN
} pe_output_mode_t;

// PE saturation mode
// PE_SAT_NONE: not saturation of output
// PE_SAT: saturate to element width, keep decimal in same position
// PE_SAT_UPPER: saturate to element width, keeping upper half of result only
typedef enum logic [1:0] {
    PE_SAT_NONE,
    PE_SAT,
    PE_SAT_UPPER
} pe_saturate_mode_t;

// PE operand selection - select B operand for PE
// PE_OPERAND_VS1: vector from vs1 vector register
// PE_OPERAND_SCALAR: scalar passed from x-register
// PE_OPERAND_IMMEDIATE: scalar immediate passed from instruction
// PE_OPERAND_RIPPLE: configure PEs in ripple mode for reductions
typedef enum logic [1:0] {
    PE_OPERAND_VS1,
    PE_OPERAND_SCALAR,
    PE_OPERAND_IMMEDIATE,
    PE_OPERAND_RIPPLE
} pe_operand_t;

// Source of data written back to vd in vector registers
// VREG_WB_SRC_ARITH: data output from arithmetic stage
// VREG_WB_SRC_MEMORY: data retrieved from RAM
// VREG_WB_SRC_SCALAR: scalar value taken from scalar replicator
typedef enum logic [1:0] {
    VREG_WB_SRC_ARITH,
    VREG_WB_SRC_MEMORY,
    VREG_WB_SRC_SCALAR
} vreg_wb_src_t;

// Source of address of selected vector register
// VREG_ADDR_SRC_DECODE: address from decoder
// VREG_ADDR_SRC_VLSU: address from vlsu / address unit
typedef enum logic {
    VS3_ADDR_SRC_DECODE,
    VS3_ADDR_SRC_VLSU
} vreg_addr_src_t;

// Source of data returned to CPU by via apu_result
// APU_RESULT_SRC_VL: return VL value. For vsetvli
// APU_RESULT_SRC_VS2_0: return first element of vs2. For vmv.x.s
typedef enum logic {
    APU_RESULT_SRC_VL,
    APU_RESULT_SRC_VS2_0
}   apu_result_src_t;

// Major opcodes converted into 2 bits for the vector accelerator
// parameter V_MAJOR_LOAD_FP   = 2'b00;
// parameter V_MAJOR_STORE_FP  = 2'b01;
// parameter V_MAJOR_OP_V      = 2'b10;
// parameter V_MAJOR_CUSTOM    = 2'b11;
parameter V_MAJOR_LOAD_FP   = 7'b0000111;
parameter V_MAJOR_STORE_FP  = 7'b0100111;
parameter V_MAJOR_OP_V      = 7'b1010111;
// parameter V_MAJOR_CUSTOM    = 7'b;

// funct3 bit fields from vector instructions (describe operand/source types)
parameter V_OPIVV = 3'b000;
parameter V_OPFVV = 3'b001;
parameter V_OPMVV = 3'b010;
parameter V_OPIVI = 3'b011;
parameter V_OPIVX = 3'b100;
parameter V_OPFVF = 3'b101;
parameter V_OPMVX = 3'b110;
parameter V_OPCFG = 3'b111;


endpackage
