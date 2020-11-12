module vector_decoder (
    output logic apu_valid,
    output logic apu_gnt,
    input wire clk,
    input wire n_reset,
    input wire apu_req,
);

enum logic {WAIT, EXEC} state, next_state;

always_ff @(posedge clk, negedge n_reset)
    if(~n_reset)
        state <= WAIT;
    else
        state <= next_state;

always_comb
begin
    apu_valid = 1'b0;
    apu_gnd = 1'b0;
    next_state = state;

    case (state)
        WAIT:
        begin
            apu_valid = 1'b1;
            if (apu_req)
                next_state = EXEC;
            else
                next_state = WAIT;
        end
        EXEC:
        begin
            if (count == max_count)
            begin
                next_state = WAIT;
                apu_valid = 1'b1;
            end
        end
    endcase
end

endmodule
