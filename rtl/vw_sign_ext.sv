// Variable width sign extension module. Used to sign-extend 3 PE inputs for
// signed/widening multiplication

module vw_sign_ext (
    output logic [31:0] sign_ext_a,
    output logic [31:0] sign_ext_b,
    output logic [31:0] sign_ext_c,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [1:0] widening, // 2'd1 for 2*widening, 2'd2 for quad widening
    input wire [1:0] vsew
);

always_comb
    case(vsew)
        2'd0: // 8b
        begin
            sign_ext_a = {{24{a[7]}}, a[7:0]};
            sign_ext_b = {{24{b[7]}}, b[7:0]};
            if (widening[0])
                sign_ext_c = {{16{c[15]}}, c[15:0]};
            else if (widening[1])
                sign_ext_c = c;
            else
                sign_ext_c = {{24{c[7]}}, c[7:0]};
        end
        2'd1: // 16b
        begin
            sign_ext_a = {{16{a[15]}}, a[15:0]};
            sign_ext_b = {{16{b[15]}}, b[15:0]};
            if (widening[0])
                sign_ext_c = c;
            else if (widening[1])
                $error("Trying to quad-widen 16b elements!");
            else
                sign_ext_c = {{16{c[15]}}, c[15:0]};
        end
        default:
        begin
            sign_ext_a = a;
            sign_ext_b = b;
            sign_ext_c = c;
        end
    endcase

endmodule