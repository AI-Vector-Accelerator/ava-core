module vector_register_v2

   #(parameter W=16;   //width of register
	parameter L=32;    //length of register
	parameter NP=4;   //number of ports
	parameter A=5)  //address length log2(L)

	
  (output [W-1:0] dataout [NP-1:0],    
  input write [NP-1:0],
  input [W-1:0] datain [NP-1:0],
  input [A-1:0] address [NP-1:0],
  input   clk,  
  input  n_reset   
  );
  
  
  logic [W-1:0] Vector_register [L-1:0];
  
  
  always_comb
  
  begin
  
	for (int i =0;i<NP;i++)
	begin
		if (write[i])
			dataout[i][W-1:0] = 'x;
		else 
			dataout[i][W-1:0] = Vector_register[address[i][A-1:0]][W-1:0];
	end

  end
  
  
 always_ff @(posedge clk, negedge n_reset)  
 begin
 

  if (!n_reset)
  begin 
	for	(int i =0;i<L;i++)
	begin
		Vector_register[i] <= '0;
	end
  end
  else if (clk)
  begin
	for (int i =0;i<NP;i++)
	begin
   if (write[i])
		Vector_register[address[i]] <= datain[i];
	end 
  end
  end 
 endmodule 