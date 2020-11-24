// NOTE (Matthew Johns) - there is similarity between parts of this code and the
// csr.sv module made by me in my third-year project. This is because the
// functionality is similar and therefore I'm using what I learnt previously.

module vector_csrs (
    output logic [4:0] vl,
    output logic [1:0] vsew,
    output logic [1:0] vlmul,
    input wire clk,
    input wire n_reset,
    input wire [31:0] avl_in,
    input wire [4:0] vtype_in,
    input wire write,
    input wire saturate_flag,
    input wire preserve_vl,
    input wire set_vl_max
);

// CSRs included in this implementation:
// 0x009    vxsat   fixed-point saturate flag
// 0x00A    vxrm    fixed-point rounding mode (fixed to )
// 0xC20    vl      vector length
// 0xC21    vtype   vector data type register
// 0xC22    vlenb   vector register length in bytes
// For this accelerator they're separate from the standard CSR file - so we
// might as well put them in one block of their own, in this order

logic [31:0] csrs [4:0];

logic [4:0] vl_next;
logic [4:0] max_vl;
logic [2:0] per_reg;

always_ff @(posedge clk, negedge n_reset)
    if (~n_reset)
    begin
        for (int i=0; i<4; i++)
            csrs[i] <= '0;
            // vlenb is read-only, so can assign it at reset
        csrs[4] <= 32'd4;
    end
    else
    begin
        if (write)
        begin
            // vtype will be changed for every vsetvli instruction
            csrs[3] <= {'0, vtype_in};

            // Don't always want to write VL, eg. if rd == 0 and rs1 == 0
            // preserve_vl controls when it's left unchanged
            if (~preserve_vl)
                csrs[2] <= {'0 , vl_next};
        end
    end


always_comb
begin
    // Spec defines vsew as 3 bits of vtype, but our max element is 32b so the
    // top bit will always be zero and we can just look at the lower two
    vsew = csrs[3][3:2];
    vlmul = csrs[3][1:0];

    // If the AVL being suggested in the instruction is larger than max_vl, need
    // to set VL to max_vl. Also do this if set_vl_max asserted
    if ( set_vl_max | (avl_in > max_vl) )
        vl_next = max_vl;
    else
        vl_next = avl_in[4:0];

end

// VL will update on the next clock edge, but that's ok because there will be at
// least a single cycle delay before another instruction comes due to the state
// machine for the APU interface
assign vl = csrs[2][4:0];

// How many elements fit into a single register for each value of VSEW?
// Can work this out by dividing vlenb by vsew
assign per_reg = csrs[4][2:0] >> vsew;

// Max VL value equals the max number of elements per register * LMUL. LMUL is
// in powers of 2 so can use a shift
assign max_vl = per_reg << vtype_in[1:0];

endmodule
