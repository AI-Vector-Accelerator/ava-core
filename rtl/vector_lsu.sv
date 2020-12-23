import accelerator_pkg::*;

module vector_lsu (
    input  wire         clk,
    input  wire         n_reset,

    // Vector CSR
    input  wire [4:0]   vl_i,
    input  wire [1:0]   vsew_i,
    input  wire [1:0]   vlmul_i,

    // VLSU Decoded Control
    input  wire         vlsu_en_i,
    input  wire         vlsu_load_i,
    input  wire         vlsu_store_i,
    input  wire         vlsu_strided_i,
    output logic        vlsu_ready_o,
    output logic        vlsu_done_o,

    // OBI Memory Master
    output logic        data_req_o,
    input  logic        data_gnt_i,
    input  logic        data_rvalid_i,
    output logic [31:0] data_addr_o,
    output logic        data_we_o,
    output logic [3:0]  data_be_o,
    input  logic [31:0] data_rdata_i,
    output logic [31:0] data_wdata_o,

    input  logic [1:0]  cycle_count_i,
 
    // Target Data
    input  wire [31:0]  op0_data_i, // Source (Load) / Destination (Store)
    input  wire [31:0]  op1_data_i, // Stride

    // Wide vector register port
    output logic [127:0] vs_wdata_o,
    input  logic [127:0] vs_rdata_i,
    input  logic [4:0] vr_addr_i,
    output logic [4:0] vs3_addr_o, // Redirected vector register address
    output logic vr_we_o
);

    logic [31:0] vs_rdata_sel;
    logic [5:0] vsew_size;

    logic au_start;
    logic [3:0] au_be;
    logic [6:0] au_bc;
    logic [31:0] au_addr;
    logic au_valid, au_ready;
    logic au_final;
    logic [6:0] vd_offset;

    temporary_reg tr (
        .clk_i              (clk), 
        .n_rst_i            (n_reset),
        .byte_enable_valid  (data_req_o),
        .read_data_valid    (data_rvalid_i),
        .clear_register     (au_start),
        .memory_read_i      (data_rdata_i),
        .byte_enable_i      (au_be),
        .byte_select_i      (vd_offset + {vr_addr_i[1:0], 2'b00}),
        .wide_vd_o          (vs_wdata_o)
    );

    always_comb begin
        case(vsew_i)
            2'd0 : begin
                data_wdata_o = {vs_rdata_i[103:96], vs_rdata_i[71:64], vs_rdata_i[39:32], vs_rdata_i[7:0]};
            end
            2'd1 : begin
                case(vs3_addr_o[0])
                    1'd0 : data_wdata_o = {vs_rdata_i[47:32], vs_rdata_i[15:0]};
                    1'd1 : data_wdata_o = {vs_rdata_i[111:96], vs_rdata_i[79:64]};
                endcase
            end
            2'd2 : begin
                case(vs3_addr_o[1:0]) 
                    2'd0 : data_wdata_o = vs_rdata_i[31:0];
                    2'd1 : data_wdata_o = vs_rdata_i[63:32];
                    2'd2 : data_wdata_o = vs_rdata_i[95:64];
                    2'd3 : data_wdata_o = vs_rdata_i[127:96]; 
                endcase
            end
        endcase
    end

    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset)
            vr_we_o = 1'b0;
        else 
            vr_we_o = au_final;
    end

    logic [1:0] ib_select; // Low 2 bits of initial address
    logic [3:0] be_gen;

    logic [31:0] next_el_pre, next_el_addr;
    logic [31:0] cycle_addr, stride;
    logic [6:0] cycle_bytes;

    typedef enum {RESET, LOAD_FIRST, LOAD_CYCLE, LOAD_WAIT, LOAD_FINAL, STORE_CYCLE, STORE_WAIT, STORE_FINAL} be_state;
    be_state current_state, next_state;

    logic signed [6:0] byte_track, byte_track_next;
    logic cycle_load, cycle_addr_inc, store_cycles_inc;

    assign stride = vlsu_strided_i ? op1_data_i : (31'd1 << vsew_i);
    assign data_addr_o = vlsu_store_i ? ({cycle_addr[31:2], 2'd0} + (store_cycles_cnt << 2)) : {cycle_addr[31:2], 2'd0};
    assign au_be = be_gen;
    assign vd_offset = (vl_i << vsew_i) - byte_track;

    logic [1:0] store_cycle_bytes;
    logic [3:0] store_cycle_be;
    logic [1:0] store_cycles, store_cycles_cnt;

    always_comb begin
        store_cycle_bytes = byte_track % 4;
        case(store_cycle_bytes)
            2'd0 : store_cycle_be = 4'b1111;
            2'd1 : store_cycle_be = 4'b0001;
            2'd2 : store_cycle_be = 4'b0011;
            2'd3 : store_cycle_be = 4'b0111;
        endcase
        assign data_be_o = vlsu_store_i ? store_cycle_be : 4'b1111;
    end 

    always_comb begin
        if(au_start)
            byte_track_next = {2'd0, vl_i} << vsew_i; // Bytes dependent on element size
        else if(cycle_addr_inc)
            byte_track_next = (byte_track >= cycle_bytes) ? (byte_track - cycle_bytes) : 7'd0;
        else if(store_cycles_inc)
            byte_track_next = byte_track - store_cycle_bytes;
        else 
            byte_track_next = byte_track;
    end 

    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset)
            byte_track <= 7'd0;
        else 
            byte_track <= byte_track_next;
    end

    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset)
            cycle_addr <= 32'd0;
        else if(au_start)
            cycle_addr <= op0_data_i;
        else if(cycle_addr_inc)  
            cycle_addr <= next_el_addr;
        else 
            cycle_addr <= cycle_addr;
    end

    assign store_cycles = (vl_i-1 >> 2-vsew_i);
    assign vs3_addr_o = vr_addr_i + store_cycles_cnt;
    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset)
            store_cycles_cnt <= 2'd0;
        else if(au_start)
            store_cycles_cnt <= 2'd0;
        else if (store_cycles_inc)
            store_cycles_cnt <= store_cycles_cnt + 2'b1;
    end

    always_ff @(posedge clk, negedge n_reset) begin
        if(~n_reset)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

    always_comb begin
        be_gen = 4'b0000;
        case(vsew_i)
            2'b00 : begin // 8 Bit
                ib_select = cycle_addr[1:0];

                if(stride > 32'd1) begin
                    be_gen[ib_select] = 1'b1;

                    // Where is our next byte?
                    next_el_pre = cycle_addr + stride;
                    if(next_el_pre[31:2] == cycle_addr[31:2] && byte_track > 1) begin
                        be_gen[next_el_pre[1:0]] = 1'b1;
                        next_el_addr = next_el_pre + stride; // Stride by second element
                    end else begin
                        next_el_addr = next_el_pre;
                    end

                    // Calculate the number of bytes for LOAD_CYCLE
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if(stride == 1) begin
                    be_gen[0] = (ib_select == 32'd0) ? 1 : 0;
                    be_gen[1] = (ib_select == 1 || byte_track > 1) ? 1'b1 : 1'b0;
                    be_gen[2] = (ib_select == 2 || byte_track > 2) ? 1'b1 : 1'b0;
                    be_gen[3] = (ib_select == 3 || byte_track > 3) ? 1'b1 : 1'b0;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + 32'd4;

                    // Calculate the number of bytes for LOAD_CYCLE
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};    
                end else if(stride == 32'd0) begin
                    be_gen[ib_select] = 1'b1;
                    cycle_bytes = {2'b0, vl_i}; // Read all bytes in 1 LOAD_CYCLE
                end
            end
            2'b01 : begin // 16 Bit
                ib_select = {cycle_addr[1], 1'b0}; // Force alignment byte 0 or 2

                if(stride > 32'd2) begin // Always 1 element
                    // Always set 2 bytes
                    be_gen[ib_select] = 1'b1;   
                    be_gen[ib_select+1] = 1'b1;
                    next_el_addr = {cycle_addr[31:1], 1'b0} + {stride[31:1], 1'b0};
                
                    // Calculate the number of bytes for LOAD_CYCLE
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if (stride == 32'd2) begin // Up to 2 Elements
                    be_gen[1:0] = (ib_select == 0) ? 2'b11 : 2'b00;
                    be_gen[3:2] = (ib_select == 2 || byte_track > 2) ? 2'b11 : 2'b00;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + 32'd4;
                    
                    // Calculate the number of bytes for LOAD_CYCLE
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if (stride == 32'd0) begin  
                    be_gen[ib_select] = 1'b1;
                    be_gen[ib_select+1] = 1'b1;
                    cycle_bytes = {1'b0, vl_i, 1'b0}; // Read all bytes in 1 LOAD_CYCLE
                end
            end
            2'b10 : begin // 32 Bit
                ib_select = 2'd0; // Force alignment to byte 0

                if(stride >= 32'd4) begin // Always 1 element
                    be_gen = 4'b1111;
                    next_el_addr = {cycle_addr[31:2], 2'b0} + {stride[31:2], 2'b0}; // stride is always a multiple of 4
                    
                    // Calculate the number of bytes for LOAD_CYCLE
                    cycle_bytes = {5'd0, be_gen[3]} + {5'd0, be_gen[2]} + {5'd0, be_gen[1]} + {5'd0, be_gen[0]};
                end else if(stride == 32'd0) begin
                    be_gen = 4'b1111;
                    cycle_bytes = {1'b0, vl_i, 1'b0}; // Read all bytes in 1 LOAD_CYCLE
                end
            end
            default : $error("Invalid VSEW"); 
        endcase
    end

    always_comb begin
        cycle_load = 1'b0;
        data_req_o = 1'b0;
        data_we_o = 1'b0;
        au_start = 1'b0;
        au_ready = 1'b0;
        au_final = 1'b0;
        vlsu_done_o = 1'b0;
        vlsu_ready_o = 1'b0; 
        cycle_addr_inc = 1'b0;
        store_cycles_inc = 1'b0;
        case(current_state)
            RESET: begin
                vlsu_ready_o = 1'b1; 
                if(vlsu_load_i) begin
                    au_start = 1'b1;
                    next_state = LOAD_FIRST;
                end else if (vlsu_store_i) begin
                    au_start = 1'b1;
                    next_state = STORE_CYCLE;
                end else begin
                    next_state = RESET;
                end
            end
            LOAD_FIRST: begin
                next_state = LOAD_CYCLE;
            end
            LOAD_CYCLE: begin
                if(byte_track_next == 0) begin
                    next_state = LOAD_WAIT;
                end else begin
                    data_req_o = 1'b1;
                    cycle_load = 1'b1;
                    next_state = LOAD_WAIT;
                end
            end
            LOAD_WAIT: begin
                if(data_rvalid_i) begin
                    cycle_addr_inc = 1'b1;
                    next_state = LOAD_CYCLE;
                end else if(byte_track_next == 0)
                    next_state = LOAD_FINAL;
                else
                    next_state = LOAD_WAIT;
            end
            LOAD_FINAL: begin
                au_final = 1'b1;
                next_state = RESET;
                vlsu_done_o = 1'b1;
            end
            STORE_CYCLE: begin
                data_req_o = 1'b1;
                data_we_o = 1'b1;
                next_state = STORE_WAIT;
            end
            STORE_WAIT: begin
                if(data_rvalid_i) begin
                    if(store_cycles_cnt == store_cycles) begin
                        next_state = STORE_FINAL;
                    end else begin 
                        store_cycles_inc = 1'b1;
                        next_state = STORE_CYCLE;
                    end
                end else begin
                    next_state = STORE_WAIT;
                end
            end
            STORE_FINAL: begin
                vlsu_done_o = 1'b1;
                next_state = RESET;
            end
        endcase
    end


endmodule
