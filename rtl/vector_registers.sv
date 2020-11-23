module vector_registers (
    output logic [127:0] vs1_data,
    output logic [127:0] vs2_data,
    output logic [127:0] vs3_data,
    input wire [127:0] vd_data,
    input wire [4:0] vs1_addr,
    input wire [4:0] vs2_addr,
    input wire [4:0] vd_addr,   // Generally this doubles up as vs3 address
    input wire [1:0] vsew,
    input wire [1:0] elements_to_write,
    input wire clk,
    input wire n_reset,
    input wire write,
    input wire widening_op
);

localparam VLEN = 32;

logic [VLEN-1:0] vregs [31:0];

// Addresses for each of the read ports for each operand.
// Each operand may require up to four read ports.
// Reason: need 4 elements per operand per cycle to maintain throughput in
// the 4 PEs. For 8b elements, 4 elements are stored in a single register;
// however with 32b elements they will be spread across 4 registers (when
// LMUL > 1). Otherwise SIMD throughput would be tiny.
// These addresses will be consecutive for each operand. Just want a tidy
// efficient way of producing them without an adder for each one.
logic [4:0] vs1_addr0;
logic [4:0] vs1_addr1;
logic [4:0] vs1_addr2;
logic [4:0] vs1_addr3;

logic [4:0] vs2_addr0;
logic [4:0] vs2_addr1;
logic [4:0] vs2_addr2;
logic [4:0] vs2_addr3;

logic [4:0] vd_addr0;
logic [4:0] vd_addr1;
logic [4:0] vd_addr2;
logic [4:0] vd_addr3;

// Structured data to write back to registers
logic [VLEN-1:0] vd_wr_data0;
logic [VLEN-1:0] vd_wr_data1;
logic [VLEN-1:0] vd_wr_data2;
logic [VLEN-1:0] vd_wr_data3;

// Unstructured data read from registers
logic [VLEN-1:0] vs1_rd_data0;
logic [VLEN-1:0] vs1_rd_data1;
logic [VLEN-1:0] vs1_rd_data2;
logic [VLEN-1:0] vs1_rd_data3;

logic [VLEN-1:0] vs2_rd_data0;
logic [VLEN-1:0] vs2_rd_data1;
logic [VLEN-1:0] vs2_rd_data2;
logic [VLEN-1:0] vs2_rd_data3;

logic [VLEN-1:0] vs3_rd_data0;
logic [VLEN-1:0] vs3_rd_data1;
logic [VLEN-1:0] vs3_rd_data2;
logic [VLEN-1:0] vs3_rd_data3;

// Write-enable signals for each write port. Could get away with making wr_en1
// only 2 bits, as will only write 16b elements. Similarly could make wr_en2 and
// wr_en3 single bits. But I don't know what that would synthesise to if I did
logic [3:0] wr_en0;
logic [3:0] wr_en1;
logic [3:0] wr_en2;
logic [3:0] wr_en3;

// Effective vsew can be modified for widening ops
logic [1:0] eff_vsew;


// REGISTER WRITE
always_ff @(posedge clk, negedge n_reset)
    if (~n_reset)
        vregs <= '{VLEN{'0}};
    else
    begin
        // Don't want to write to v0 (reserved for vector mask)
        if (write && vd_addr)
        begin
            if (wr_en0[0])
                vregs[vd_addr0][7:0] <= vd_wr_data0[7:0];
            if (wr_en0[1])
                vregs[vd_addr0][15:8] <= vd_wr_data0[15:8];
            if (wr_en0[2])
                vregs[vd_addr0][23:16] <= vd_wr_data0[23:16];
            if (wr_en0[3])
                vregs[vd_addr0][31:24] <= vd_wr_data0[31:24];

            if (wr_en1[0])
                vregs[vd_addr1][7:0] <= vd_wr_data1[7:0];
            if (wr_en1[1])
                vregs[vd_addr1][15:8] <= vd_wr_data1[15:8];
            if (wr_en1[2])
                vregs[vd_addr1][23:16] <= vd_wr_data1[23:16];
            if (wr_en1[3])
                vregs[vd_addr1][31:24] <= vd_wr_data1[31:24];

            if (wr_en2[0])
                vregs[vd_addr2][7:0] <= vd_wr_data2[7:0];
            if (wr_en2[1])
                vregs[vd_addr2][15:8] <= vd_wr_data2[15:8];
            if (wr_en2[2])
                vregs[vd_addr2][23:16] <= vd_wr_data2[23:16];
            if (wr_en2[3])
                vregs[vd_addr2][31:24] <= vd_wr_data2[31:24];

            if (wr_en3[0])
                vregs[vd_addr3][7:0] <= vd_wr_data3[7:0];
            if (wr_en3[1])
                vregs[vd_addr3][15:8] <= vd_wr_data3[15:8];
            if (wr_en3[2])
                vregs[vd_addr3][23:16] <= vd_wr_data3[23:16];
            if (wr_en3[3])
                vregs[vd_addr3][31:24] <= vd_wr_data3[31:24];
        end
    end


// REGISTER READ
assign vs1_rd_data0 = vregs[vs1_addr0];
assign vs1_rd_data1 = vregs[vs1_addr1];
assign vs1_rd_data2 = vregs[vs1_addr2];
assign vs1_rd_data3 = vregs[vs1_addr3];
assign vs2_rd_data0 = vregs[vs2_addr0];
assign vs2_rd_data1 = vregs[vs2_addr1];
assign vs2_rd_data2 = vregs[vs2_addr2];
assign vs2_rd_data3 = vregs[vs2_addr3];
assign vs3_rd_data0 = vregs[vd_addr0];
assign vs3_rd_data1 = vregs[vd_addr1];
assign vs3_rd_data2 = vregs[vd_addr2];
assign vs3_rd_data3 = vregs[vd_addr3];


// ADDRESS CALCULATION
always_comb
begin
    // Logic behind this: Need 4 consecutive addresses, but don't want to just
    // have adders for each one to increment the address.
    // This is only useful for LMUL > 1, as for LMUL = 1, only one register will
    // be read anyway. If LMUL > 1, base addresses will always be even. So can
    // add one to it by making last bit 1. Add 2 by making second-last bit 1.
    // Add 3 by doing both.
    // If LMUL = 2 then adding 2 that way won't work, but also it won't be used
    // because only the first 2 registers will be used.
    vs1_addr0 = vs1_addr;
    vs1_addr1 = {vs1_addr[4:1], 1'b1};
    vs1_addr2 = {vs1_addr[4:2], 1'b1, vs1_addr[0]};
    vs1_addr3 = {vs1_addr[4:2], 2'b11};

    vs2_addr0 = vs2_addr;
    vs2_addr1 = {vs2_addr[4:1], 1'b1};
    vs2_addr2 = {vs2_addr[4:2], 1'b1, vs2_addr[0]};
    vs2_addr3 = {vs2_addr[4:2], 2'b11};

    vd_addr0 = vd_addr;
    vd_addr1 = {vd_addr[4:1], 1'b1};
    vd_addr2 = {vd_addr[4:2], 1'b1, vd_addr[0]};
    vd_addr3 = {vd_addr[4:2], 2'b11};
end


// WRITE-ENABLE GENERATION
always_comb
begin
    // Note: can ignore LMUL in below cases as LMUL will restrict the max of VL,
    // which will prevent from writing to higher registers than LMUL wants

    if (widening_op)
        case (vsew)
            2'd0: // 8b -> 16b
                eff_vsew = 2'd1;
            2'd1: // 16b -> 32b
                eff_vsew = 2'd2;
            default:
            begin
                // Shouldn't come to this
                eff_vsew = vsew;
                $error("Widening ops with VSEW=32b are not supported");
            end
        endcase
    else
        eff_vsew = vsew;

    wr_en0 = '0;
    wr_en1 = '0;
    wr_en2 = '0;
    wr_en3 = '0;

    case (eff_vsew)
        2'd0: // 8b
        begin
            // Only interested in first write port
            case (elements_to_write)
                2'd0: // Write all elements
                    wr_en0 = 4'b1111;
                2'd1:
                    wr_en0 = 4'b0001;
                2'd2:
                    wr_en0 = 4'b0011;
                2'd3:
                    wr_en0 = 4'b0111;
            endcase
        end
        2'd1: // 16b
        begin
            // Only interested in first 2 write ports
            case (elements_to_write)
                2'd0: // Write all elements
                begin
                    wr_en0 = 4'b1111;
                    wr_en1 = 4'b1111;
                end
                2'd1:
                begin
                    wr_en0 = 4'b0011;
                end
                2'd2:
                begin
                    wr_en0 = 4'b1111;
                end
                4'd3:
                begin
                    wr_en0 = 4'b1111;
                    wr_en1 = 4'b0011;
                end
            endcase
        end
        2'd2: // 32b
        begin
            // Need to consider all write ports
            // wr_en0 always enabled, otherwise would be writing no elements
            case (elements_to_write)
                2'd0: // Write all elements
                begin
                    wr_en1 = 4'b1111;
                    wr_en2 = 4'b1111;
                    wr_en3 = 4'b1111;
                end
                // 2'd1: // Not needed, just wr_en0 = '1
                2'd2:
                begin
                    wr_en1 = 4'b1111;
                end
                2'd3:
                begin
                    wr_en1 = 4'b1111;
                    wr_en2 = 4'b1111;
                end
            endcase
        end
    endcase
end


// OUTPUT DATA MAP
// TODO: consider need for sign extension for VSEW<32b
// Have to pad the extra space when using smaller elements to give correct
// alignment into the PEs
always_comb
begin
    case (vsew)
        2'd0: // 8b
        begin
            vs1_data = {
                {24{1'b0}},
                vs1_rd_data0[31:24],
                {24{1'b0}},
                vs1_rd_data0[23:16],
                {24{1'b0}},
                vs1_rd_data0[15:8],
                {24{1'b0}},
                vs1_rd_data0[7:0]
            };
            vs2_data = {
                {24{1'b0}},
                vs2_rd_data0[31:24],
                {24{1'b0}},
                vs2_rd_data0[23:16],
                {24{1'b0}},
                vs2_rd_data0[15:8],
                {24{1'b0}},
                vs2_rd_data0[7:0]
            };
            // For widening ops such as MACC, the third operand needs to be the
            // widened width rather than VSEW. Copy the mapping of vs3 from the
            // next largest element. Does not apply to VSEW=32b as widening ops
            // are not supported.
            if (widening_op)
                vs3_data = {
                    {16{1'b0}},
                    vs3_rd_data1[31:16],
                    {16{1'b0}},
                    vs3_rd_data1[15:0],
                    {16{1'b0}},
                    vs3_rd_data0[31:16],
                    {16{1'b0}},
                    vs3_rd_data0[15:0]
                };
            else
                vs3_data = {
                    {24{1'b0}},
                    vs3_rd_data0[31:24],
                    {24{1'b0}},
                    vs3_rd_data0[23:16],
                    {24{1'b0}},
                    vs3_rd_data0[15:8],
                    {24{1'b0}},
                    vs3_rd_data0[7:0]
                };
        end
        2'd1: // 16b
        begin
            vs1_data = {
                {16{1'b0}},
                vs1_rd_data1[31:16],
                {16{1'b0}},
                vs1_rd_data1[15:0],
                {16{1'b0}},
                vs1_rd_data0[31:16],
                {16{1'b0}},
                vs1_rd_data0[15:0]
            };
            vs2_data = {
                {16{1'b0}},
                vs2_rd_data1[31:16],
                {16{1'b0}},
                vs2_rd_data1[15:0],
                {16{1'b0}},
                vs2_rd_data0[31:16],
                {16{1'b0}},
                vs2_rd_data0[15:0]
            };
            if (widening_op)
                vs3_data = {
                    vs3_rd_data3,
                    vs3_rd_data2,
                    vs3_rd_data1,
                    vs3_rd_data0
                };
            else
                vs3_data = {
                    {16{1'b0}},
                    vs3_rd_data1[31:16],
                    {16{1'b0}},
                    vs3_rd_data1[15:0],
                    {16{1'b0}},
                    vs3_rd_data0[31:16],
                    {16{1'b0}},
                    vs3_rd_data0[15:0]
                };
        end
        2'd2: // 32b
        begin
            vs1_data = {
                vs1_rd_data3,
                vs1_rd_data2,
                vs1_rd_data1,
                vs1_rd_data0
            };
            vs2_data = {
                vs2_rd_data3,
                vs2_rd_data2,
                vs2_rd_data1,
                vs2_rd_data0
            };
            vs3_data = {
                vs3_rd_data3,
                vs3_rd_data2,
                vs3_rd_data1,
                vs3_rd_data0
            };
        end
        default:
        begin
            vs1_data = '0;
            vs2_data = '0;
            vs3_data = '0;
        end
    endcase
end


// INPUT DATA MAP
// Take wide combined result data from PEs and remove padding
always_comb
begin
    vd_wr_data3 = '0;
    vd_wr_data2 = '0;
    vd_wr_data1 = '0;
    vd_wr_data0 = '0;

    case (eff_vsew)
        2'd0: // 8b
            vd_wr_data0 = {
                vd_data[103:96],
                vd_data[71:64],
                vd_data[39:32],
                vd_data[7:0]
            };
        2'd1: // 16b
        begin
            vd_wr_data1 = {
                vd_data[111:96],
                vd_data[79:64]
            };
            vd_wr_data0 = {
                vd_data[47:32],
                vd_data[15:0]
            };
        end
        2'd2: // 32b
        begin
            vd_wr_data3 = vd_data[127:96];
            vd_wr_data2 = vd_data[95:64];
            vd_wr_data1 = vd_data[63:32];
            vd_wr_data0 = vd_data[31:0];
        end
    endcase
end

endmodule