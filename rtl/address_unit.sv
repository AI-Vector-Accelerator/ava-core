//
// SPDX-License-Identifier: CERN-OHL-S-2.0+
//
// Copyright (C) 2020-21 Embecosm Limited <www.embecosm.com>
// Contributed by:
// Byron Theobald <bt4g16@soton.ac.uk>
//
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
// A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable
// conditions.
// Source location: https://github.com/AI-Vector-Accelerator
//

/* verilator lint_off ALWCOMBORDER */
module address_unit(
    input logic clk_i, n_rst_i,
    input logic [31:0] base_addr_i,
    input logic [31:0] stride_i,
    input logic [4:0] vl_i,
    input logic [1:0] vsew_i,
    input logic au_start_i,
    input logic au_next_i,
    output logic [3:0] au_be_o,
    output logic [6:0] au_bc_o,
    output logic [31:0] au_addr_o,
    output logic [6:0] vd_offset_o,
    output logic au_valid_o,
    output logic au_ready_o,
    output logic au_final_o);

    logic [1:0] ib_select; // Low 2 bits of initial address
    logic [3:0] be_gen;
    
    logic [31:0] next_el_pre, next_el_addr;
    logic [31:0] cycle_addr;
    logic [6:0] cycle_bytes;

    typedef enum {RESET, FIRST, CYCLE, WAIT, FINAL} be_state;
    be_state current_state, next_state;

    logic signed [6:0] byte_track, byte_track_next;
    logic cycle_load;

    assign vd_offset_o = (vl_i << vsew_i) - byte_track;

    always_comb begin
        if(au_valid_o) begin // Make sure that all our addresses are word aligned
            au_addr_o = {cycle_addr[31:2], 2'd0};
            au_be_o = be_gen;
        end else begin
            au_addr_o = 32'd0;
            au_be_o = 4'b0000;
        end
    end

    always_comb begin
        if(au_start_i)
            byte_track_next = {2'd0, vl_i} << vsew_i; // Bytes dependent on element size
        else if(current_state != CYCLE)
            byte_track_next = byte_track;
        else 
            byte_track_next = (byte_track >= cycle_bytes) ? (byte_track - cycle_bytes) : 7'd0;
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
        else if(au_start_i)
            cycle_addr <= base_addr_i;
        else if(current_state != CYCLE)  
            cycle_addr <= cycle_addr;
        else 
            cycle_addr <= next_el_addr;
    end

    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

    always_comb begin
        be_gen = 4'b0000;
        case(vsew_i)
            2'b00 : begin // 8 Bit
                ib_select = cycle_addr[1:0];

                if(stride_i > 1) begin
                    be_gen[ib_select] = 1'b1;

                    // Where is our next byte?
                    next_el_pre = cycle_addr + stride_i;
                    if(next_el_pre[31:2] == cycle_addr[31:2] && byte_track > 1) begin
                        be_gen[next_el_pre[1:0]] = 1'b1;
                        next_el_addr = next_el_pre + stride_i; // Stride by second element
                    end else begin
                        next_el_addr = next_el_pre;
                    end

                    // Calculate the number of bytes for cycle
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if(stride_i == 1) begin
                    be_gen[0] = (ib_select == 0) ? 1 : 0;
                    be_gen[1] = (ib_select == 1 || byte_track > 1) ? 1'b1 : 1'b0;
                    be_gen[2] = (ib_select == 2 || byte_track > 2) ? 1'b1 : 1'b0;
                    be_gen[3] = (ib_select == 3 || byte_track > 3) ? 1'b1 : 1'b0;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + 32'd4;

                    // Calculate the number of bytes for cycle
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};    
                end else if(stride_i == 0) begin
                    be_gen[ib_select] = 1'b1;
                    cycle_bytes = {2'b0, vl_i}; // Read all bytes in 1 cycle
                end
            end
            2'b01 : begin // 16 Bit
                ib_select = {cycle_addr[1], 1'b0}; // Force alignment byte 0 or 2

                if(stride_i > 2) begin // Always 1 element
                    // Always set 2 bytes
                    be_gen[ib_select] = 1'b1;   
                    be_gen[ib_select+1] = 1'b1;
                    next_el_addr = {cycle_addr[31:1], 1'b0} + {stride_i[31:1], 1'b0};
                
                    // Calculate the number of bytes for cycle
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if (stride_i == 2) begin // Up to 2 Elements
                    be_gen[1:0] = (ib_select == 0) ? 2'b11 : 2'b00;
                    be_gen[3:2] = (ib_select == 2 || byte_track > 2) ? 2'b11 : 2'b00;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + 32'd4;
                    
                    // Calculate the number of bytes for cycle
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if (stride_i == 0) begin  
                    be_gen[ib_select] = 1'b1;
                    be_gen[ib_select+1] = 1'b1;
                    cycle_bytes = {1'b0, vl_i, 1'b0}; // Read all bytes in 1 cycle
                end
            end
            2'b10 : begin // 32 Bit
                ib_select = 2'd0; // Force alignment to byte 0

                if(stride_i >= 4) begin // Always 1 element
                    be_gen = 4'b1111;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + {stride_i[31:2], 2'b0}; // stride_i is always a multiple of 4
                    
                    // Calculate the number of bytes for cycle
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if(stride_i == 0) begin
                    be_gen = 4'b1111;
                    cycle_bytes = {1'b0, vl_i, 1'b0}; // Read all bytes in 1 cycle
                end
            end
            default : $error("Invalid VSEW"); 
        endcase
    end

    always_comb begin
        cycle_load = 1'b0;
        au_valid_o = 1'b0;
        au_ready_o = 1'b0;
        au_final_o = 1'b0;
        case(current_state)
            RESET: begin
                au_ready_o = 1'b1;
                if(au_start_i)
                    next_state = FIRST;
                else
                    next_state = RESET;
            end
            FIRST: begin
                au_valid_o = 1'b1;
                if(stride_i != 0) begin
                    next_state = WAIT;
                end else begin
                    next_state = RESET;
                end
            end
            CYCLE: begin
                au_valid_o = 1'b1;
                if(byte_track_next == 0) begin
                    next_state = WAIT;
                end else begin
                    cycle_load = 1'b1;
                    next_state = WAIT;
                end
            end
            WAIT: begin
                if(au_next_i)
                    next_state = CYCLE;
                else if(byte_track_next == 0)
                    next_state = FINAL;
                else
                    next_state = WAIT;
            end
            FINAL: begin
                au_final_o = 1'b1;
                next_state = RESET;
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
