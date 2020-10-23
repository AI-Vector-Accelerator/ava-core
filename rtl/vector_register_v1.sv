module vector_register_v1

   #(parameter W=32;   //width of register
	parameter L=32;    //length of register
	parameter NP=4;   //number of ports
	parameter A=5)  //address length log2(L)-1

	
  (inout [W-1:0] data [NP-1:0] ,    
  input write [NP-1:0],
  input [A-1:0] address [NP-1:0] ,
  input  clk,  
  input  n_reset   
  );
  
  
 
 logic [W-1:0] Vector_register [L-1:0];
 
 always_comb
 begin
	for (int i =0;i<NP;i++)
		begin
		if (write[i])
			data[i][W-1:0] = 'z;
		else 
			data[i][W-1:0] = Vector_register[address[i][A-1:0]][W-1:0];
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
		Vector_register[address[i]] <= data[i];
	end 
  end
 end
 endmodule 