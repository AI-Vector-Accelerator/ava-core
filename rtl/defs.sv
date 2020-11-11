// Arithmetic operations inside PEs
typedef enum logic [3:0] {
    PE_ARITH_ADD,
    PE_ARITH_SUB,
    PE_ARITH_LSHIFT,
    PE_ARITH_MUL,
    PE_ARITH_MULADD,
    PE_ARITH_XOR,
    PE_ARITH_RSHIFT_LOG,
    PE_ARITH_RSHIFT_AR,
    PE_ARITH_OR,
    PE_ARITH_AND
} pe_arith_op_t;

// PE output mode
typedef enum logic [1:0] {
    PE_OP_MODE_RESULT,
    PE_OP_MODE_PASS_MAX,
    PE_OP_MODE_PASS_MIN
} pe_output_mode_t;

// PE saturation mode
typedef enum logic [1:0] {
    PE_SAT_NONE,
    PE_SAT,
    PE_SAT_UPPER
} pe_saturation_mode_t;