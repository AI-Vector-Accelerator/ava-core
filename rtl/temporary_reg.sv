// 32-Bit input, byte_position selects the bytes to load.
// Selected bytes will be packed and loaded into the 
// register starting from byte_loaded

module temporary_reg (
    input  logic clk_i, n_rst_i,
    input  logic byte_enable_valid,
    input  logic read_data_valid,
    input  logic clear_register,
    input  logic [31:0] memory_read_i,
    input  logic [3:0] byte_enable_i,
    input  logic [6:0] byte_select_i,
    output logic [127:0] wide_vd_o);

    logic [3:0] byte_enable_reg;

    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i)
            byte_enable_reg <= 1'b0;
        else if(byte_enable_valid)
            byte_enable_reg <= byte_enable_i;
    end

    // Tempoary register, split into bytes.
    logic [7:0] temp_reg [15:0];

    // Split memory read into bytes
    logic [7:0] memory_read_bytes [3:0];
    
    always_comb begin // Split bytes out of word
        memory_read_bytes[0] = memory_read_i[7:0];
        memory_read_bytes[1] = memory_read_i[15:8];
        memory_read_bytes[2] = memory_read_i[23:16];
        memory_read_bytes[3] = memory_read_i[31:24];     
    end

    // Packed read bytes, shift higher elements down
    logic [7:0] memory_read_packed [3:0];
    logic [3:0] packed_set;

    always_comb begin
		  memory_read_packed = '{default:0};
        packed_set = 4'b0000;
        if(byte_enable_reg[0]) begin
            packed_set[0] = 1'b1;
            memory_read_packed[0] = memory_read_bytes[0];
        end
        if(byte_enable_reg[1]) begin
            casez(packed_set)
                4'bzzz0 : begin
                    packed_set[0] = 1'b1;
                    memory_read_packed[0] = memory_read_bytes[1];
                end
                4'bzzz1 : begin
                    packed_set[1] = 1'b1;
                    memory_read_packed[1] = memory_read_bytes[1];
                end
					 default: begin
						  memory_read_packed[1] = '0;
					 end
            endcase
        end
        if(byte_enable_reg[2]) begin
            casez(packed_set)
                4'bzz00 : begin
                    packed_set[0] = 1'b1;
                    memory_read_packed[0] = memory_read_bytes[2];
                end
                4'bzz01 : begin
                    packed_set[1] = 1'b1;
                    memory_read_packed[1] = memory_read_bytes[2];
                end
                4'bzz11 : begin
                    packed_set[2] = 1'b1;
                    memory_read_packed[2] = memory_read_bytes[2];
                end
					 default: begin
						  memory_read_packed[2] = '0;
					 end
            endcase
        end
        if(byte_enable_reg[3]) begin
            casez(packed_set)
                4'bz000 : begin
                    packed_set[0] = 1'b1;
                    memory_read_packed[0] = memory_read_bytes[3];
                end
                4'bz001 : begin
                    packed_set[1] = 1'b1;
                    memory_read_packed[1] = memory_read_bytes[3];
                end
                4'bz011 : begin
                    packed_set[2] = 1'b1;
                    memory_read_packed[2] = memory_read_bytes[3];
                end
                4'bz111 : begin
                    packed_set[3] = 1'b1;
                    memory_read_packed[3] = memory_read_bytes[3];
                end
					 default: begin
						  memory_read_packed[3] = '0;
					 end
            endcase
        end
    end

    // Write elements into register
    always_ff @(posedge clk_i, negedge n_rst_i) begin
        if(~n_rst_i) begin
            temp_reg <= '{default: 8'd0}; 
        end else if(clear_register) begin 
            temp_reg <= '{default: 8'd0};
        end else if(read_data_valid) begin
            if(packed_set[0]) temp_reg[byte_select_i+0] <= memory_read_packed[0];
            if(packed_set[1]) temp_reg[byte_select_i+1] <= memory_read_packed[1];
            if(packed_set[2]) temp_reg[byte_select_i+2] <= memory_read_packed[2];
            if(packed_set[3]) temp_reg[byte_select_i+3] <= memory_read_packed[3];
        end
    end

    assign wide_vd_o = {temp_reg[15], temp_reg[14], temp_reg[13], temp_reg[12],
                            temp_reg[11], temp_reg[10], temp_reg[ 9], temp_reg[ 8], 
                            temp_reg[ 7], temp_reg[ 6], temp_reg[ 5], temp_reg[ 4], 
                            temp_reg[ 3], temp_reg[ 2], temp_reg[ 1], temp_reg[ 0]};

endmodule
