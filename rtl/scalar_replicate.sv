// import accelerator_pkg::*;

module scalar_replicate (
    output logic [127:0] replicated_out,
    input wire [31:0] scalar_in,
    input wire [1:0] vsew
);

// When a scalar operand comes into the accelerator there is only one copy of
// it. However, each PE needs a copy for it's calculation, so it must be
// replicated into the right position for each PE. This module does that.

always_comb
    case (vsew)
        2'd0: // 8b
            replicated_out = {
                24'd0,
                scalar_in[7:0],
                24'd0,
                scalar_in[7:0],
                24'd0,
                scalar_in[7:0],
                24'd0,
                scalar_in[7:0]
            };
        2'd1: // 16b
            replicated_out = {
                16'd0,
                scalar_in[15:0],
                16'd0,
                scalar_in[15:0],
                16'd0,
                scalar_in[15:0],
                16'd0,
                scalar_in[15:0]
            };
        2'd2: // 32b
            replicated_out = {
                {4{scalar_in}}
            };
        default:
            replicated_out = {'0, scalar_in};
    endcase


endmodule
