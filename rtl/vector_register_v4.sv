module VectorRegister
#(parameter Registerlength= 64, 
parameter numRegisters=8, 
parameter AddressLength=$clog2(numRegisters),
parameter elementSize=8,
parameter numReadPorts=3,
parameter numWritePorts=1
)

(
input  clk, nreset,
input  [AddressLength-1:0] readAddress [numReadPorts-1:0] ,
input   [(Registerlength/elementSize)-1:0] readEn[2:0],
output logic [Registerlength-1:0] ReadData [numReadPorts-1:0] ,
input   [AddressLength-1:0] writeAddress [numWritePorts-1:0],
input   [(Registerlength/elementSize)-1:0] writeEn[numWritePorts-1:0],
input  [Registerlength-1:0]writeData [numWritePorts-1:0] 

);


logic  [Registerlength-1:0]vecRegisters [numRegisters-1:0] ;
logic  [Registerlength-1:0]nextVecRegisters [numRegisters-1:0] ;




always_comb
begin

ReadData[0][7:0]=(readEn[0][0] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][7:0]:  0;
ReadData[0][15:8]=(readEn[0][1] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][15:8]:  0;
ReadData[0][23:16]=(readEn[0][2] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][23:16]:  0;
ReadData[0][31:24]=(readEn[0][3] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][31:24]:  0;
ReadData[0][39:31]=(readEn[0][4] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][39:31]:  0;
ReadData[0][47:40]=(readEn[0][5] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][47:40]:  0;
ReadData[0][55:48]=(readEn[0][6] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][55:48]:  0;
ReadData[0][63:56]=(readEn[0][7] && (readAddress[0]!=0))?vecRegisters[readAddress[0]][63:56]:  0;

ReadData[1][7:0]=(readEn[1][0] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][7:0]:  0;
ReadData[1][15:8]=(readEn[1][1] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][15:8]:  0;
ReadData[1][23:16]=(readEn[1][2] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][23:16]:  0;
ReadData[1][31:24]=(readEn[1][3] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][31:24]:  0;
ReadData[1][39:31]=(readEn[1][4] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][39:31]:  0;
ReadData[1][47:40]=(readEn[1][5] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][47:40]:  0;
ReadData[1][55:48]=(readEn[1][6] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][55:48]:  0;
ReadData[1][63:56]=(readEn[1][7] && (readAddress[1]!=0))?vecRegisters[readAddress[1]][63:56]:  0;

ReadData[2][7:0]=(readEn[2][0] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][7:0]:  0;
ReadData[2][15:8]=(readEn[2][1] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][15:8]:  0;
ReadData[2][23:16]=(readEn[2][2] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][23:16]:  0;
ReadData[2][31:24]=(readEn[2][3] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][31:24]:  0;
ReadData[2][39:31]=(readEn[2][4] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][39:31]:  0;
ReadData[2][47:40]=(readEn[2][5] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][47:40]:  0;
ReadData[2][55:48]=(readEn[2][6] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][55:48]:  0;
ReadData[2][63:56]=(readEn[2][7] && (readAddress[2]!=0))?vecRegisters[readAddress[2]][63:56]:  0;


nextVecRegisters[0] = vecRegisters[0];

if (writeAddress[0]==1)
	begin
	nextVecRegisters[1][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[1][7:0];
	nextVecRegisters[1][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[1][15:8] ;
	nextVecRegisters[1][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[1][23:16];
	nextVecRegisters[1][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[1][31:24];
	nextVecRegisters[1][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[1][39:31];
	nextVecRegisters[1][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[1][47:40];
	nextVecRegisters[1][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[1][55:48];
	nextVecRegisters[1][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[1][63:56];
	end
else 
	nextVecRegisters[1] = vecRegisters[1];


if (writeAddress[0]==2)
	begin
	nextVecRegisters[2][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[2][7:0];
	nextVecRegisters[2][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[2][15:8] ;
	nextVecRegisters[2][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[2][23:16];
	nextVecRegisters[2][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[2][31:24];
	nextVecRegisters[2][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[2][39:31];
	nextVecRegisters[2][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[2][47:40];
	nextVecRegisters[2][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[2][55:48];
	nextVecRegisters[2][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[2][63:56];
	end
else 
	nextVecRegisters[2] = vecRegisters[2];


if (writeAddress[0]==3)
	begin
	nextVecRegisters[3][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[3][7:0];
	nextVecRegisters[3][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[3][15:8] ;
	nextVecRegisters[3][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[3][23:16];
	nextVecRegisters[3][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[3][31:24];
	nextVecRegisters[3][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[3][39:31];
	nextVecRegisters[3][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[3][47:40];
	nextVecRegisters[3][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[3][55:48];
	nextVecRegisters[3][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[3][63:56];
	end
else 
	nextVecRegisters[3] = vecRegisters[3];


if (writeAddress[0]==4)
	begin
	nextVecRegisters[4][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[4][7:0];
	nextVecRegisters[4][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[4][15:8] ;
	nextVecRegisters[4][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[4][23:16];
	nextVecRegisters[4][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[4][31:24];
	nextVecRegisters[4][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[4][39:31];
	nextVecRegisters[4][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[4][47:40];
	nextVecRegisters[4][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[4][55:48];
	nextVecRegisters[4][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[4][63:56];
	end
else 
	nextVecRegisters[4] = vecRegisters[4];



if (writeAddress[0]==5)
	begin
	nextVecRegisters[5][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[5][7:0];
	nextVecRegisters[5][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[5][15:8] ;
	nextVecRegisters[5][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[5][23:16];
	nextVecRegisters[5][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[5][31:24];
	nextVecRegisters[5][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[5][39:31];
	nextVecRegisters[5][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[5][47:40];
	nextVecRegisters[5][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[5][55:48];
	nextVecRegisters[5][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[5][63:56];
	end
else 
	nextVecRegisters[5] = vecRegisters[5];



if (writeAddress[0]==6)
	begin
	nextVecRegisters[6][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[6][7:0];
	nextVecRegisters[6][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[6][15:8] ;
	nextVecRegisters[6][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[6][23:16];
	nextVecRegisters[6][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[6][31:24];
	nextVecRegisters[6][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[6][39:31];
	nextVecRegisters[6][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[6][47:40];
	nextVecRegisters[6][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[6][55:48];
	nextVecRegisters[6][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[6][63:56];
	end
else 
	nextVecRegisters[6] = vecRegisters[6];

if (writeAddress[0]==7)
	begin
	nextVecRegisters[7][7:0] = writeEn[0][0]?writeData[0][7:0]:vecRegisters[7][7:0];
	nextVecRegisters[7][15:8] = writeEn[0][1]?writeData[0][15:8]:vecRegisters[7][15:8] ;
	nextVecRegisters[7][23:16] = writeEn[0][2]?writeData[0][23:16]:vecRegisters[7][23:16];
	nextVecRegisters[7][31:24] = writeEn[0][3]?writeData[0][31:24]:vecRegisters[7][31:24];
	nextVecRegisters[7][39:31] = writeEn[0][4]?writeData[0][39:31]:vecRegisters[7][39:31];
	nextVecRegisters[7][47:40] = writeEn[0][5]?writeData[0][47:40]:vecRegisters[7][47:40];
	nextVecRegisters[7][55:48] = writeEn[0][6]?writeData[0][55:48]:vecRegisters[7][55:48];
	nextVecRegisters[7][63:56] = writeEn[0][7]?writeData[0][63:56]:vecRegisters[7][63:56];
end
else 
	nextVecRegisters[7] = vecRegisters[7];



end


always_ff@(posedge clk, negedge nreset)

if (~nreset)
	begin
		for(int i =0;i<numRegisters;i++)
			begin
			vecRegisters[i]<=0;
			end
	end


else
	begin
	if(writeEn[0] && writeAddress[0]!=0 )
		vecRegisters[writeAddress[0]]<=writeData[0];
	end

endmodule