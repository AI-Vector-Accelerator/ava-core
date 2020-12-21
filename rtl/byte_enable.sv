/* verilator lint_off ALWCOMBORDER */
module byte_enable(
    input logic clk_i, n_rst_i,
    input logic [31:0] base_addr_i,
    input logic [31:0] stride,
    input logic [4:0] vl_i,
    input logic load_first,
    output logic [3:0] cycle_be,
    output logic out_valid);

    logic [1:0] ib_select; // Low 2 bits of initial address
    logic [3:0] be_gen;
    
    logic [31:0] cycle_addr;
    logic [31:0] next_byte, next_byte_cycle;
    
    logic [6:0] cycle_bytes;

    typedef enum {RESET, FIRST, CYCLE} be_state;
    be_state current_state, next_state;

    logic signed [6:0] byte_track, byte_track_next;
    logic cycle_load;

    always_comb begin
        if(load_first)
            byte_track_next = {2'd0, vl_i};
        else
            byte_track_next = (byte_track >= cycle_bytes) ? byte_track - cycle_bytes : 7'd0;
    end 

    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i)
            byte_track <= 7'd0;
        else 
            byte_track <= byte_track_next;
    end

    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i)
            cycle_addr <= 32'd0;
        else if(load_first)
            cycle_addr <= base_addr_i;
        else if(cycle_load)
            cycle_addr <= next_byte_cycle;
        else    
            cycle_addr <= cycle_addr;
    end

    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

    always_comb begin
        ib_select = cycle_addr[1:0];

        if(stride > 1) begin
            be_gen = 4'b0;
            be_gen[ib_select] = 1'b1;

            // Where is our next byte?
            next_byte = stride + cycle_addr;
            if(next_byte[31:2] == cycle_addr[31:2] && byte_track > 1) begin
                be_gen[next_byte[1:0]] = 1'b1;
                next_byte_cycle = next_byte + stride;
            end else begin
                next_byte_cycle = next_byte;
            end

            // Calculate the number of bytes written
            /* verilator lint_off WIDTH */
            cycle_bytes = be_gen[3] + be_gen[2] + be_gen[1] + be_gen[0];    
            /* verilator lint_on WIDTH */

        end else if(stride == 1) begin
            be_gen[0] = (ib_select == 0) ? 1 : 0;
            be_gen[1] = (ib_select == 1 || byte_track > 1) ? 1 : 1'b0;
            be_gen[2] = (ib_select == 2 || byte_track > 2) ? 1 : 1'b0;
            be_gen[3] = (ib_select == 3 || byte_track > 3) ? 1 : 1'b0;
            next_byte_cycle = {cycle_addr[31:2], 2'b0} + 32'd4;
        
            // Calculate the number of bytes written
            /* verilator lint_off WIDTH */
            cycle_bytes = be_gen[3] + be_gen[2] + be_gen[1] + be_gen[0];    
            /* verilator lint_on WIDTH */

        end else if(stride == 0) begin
            be_gen = 4'b0;
            be_gen[ib_select] = 1'b1;
            cycle_bytes = {2'b0, vl_i};
        end
        

        cycle_load = 1'b0;
        out_valid = 1'b0;
        case(current_state)
            RESET: begin
                if(load_first)
                    next_state = FIRST;
                else
                    next_state = RESET;
            end
            FIRST: begin
                cycle_load = 1'b1;
                out_valid = 1'b1;
                if(stride != 0)
                    next_state = CYCLE;
                else
                    next_state = RESET;
            end
            CYCLE: begin
                out_valid = 1'b1;
                if(byte_track_next == 0) begin
                    next_state = RESET;
                end else begin
                    cycle_load = 1'b1;
                    next_state = CYCLE;
                end
            end
        endcase
    end

    initial begin
      $dumpfile("test.vcd");
      $dumpvars;
      $display(" Model running...\n");
   end
endmodule
/* verilator lint_on ALWCOMBORDER */