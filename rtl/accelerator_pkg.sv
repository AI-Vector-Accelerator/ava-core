package accelerator_pkg;

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

// Major opcodes converted into 2 bits for the vector accelerator
parameter V_MAJOR_LOAD_FP   = 2'b00;
parameter V_MAJOR_STORE_FP  = 2'b01;
parameter V_MAJOR_OP_V      = 2'b10;
parameter V_MAJOR_CUSTOM    = 2'b11;

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
