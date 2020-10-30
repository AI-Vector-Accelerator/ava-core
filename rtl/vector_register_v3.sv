module VectorRegister
#(parameter Registerlength= 64, 
parameter numRegisters=8, 
parameter AddressLength=$clog2(numRegisters),
parameter elementSize=8,
parameter numReadPorts=3,
parameter numWritePorts=1
)

(
input wire clk, nreset,
input wire [AddressLength-1:0] readAddress [numReadPorts-1:0] ,
input wire  [(Registerlength/elementSize)-1:0] readEn[2:0],
output logic [Registerlength-1:0] ReadData [numReadPorts-1:0] ,
input wire  [AddressLength-1:0] writeAddress [numWritePorts-1:0],
input wire  writeEn[numWritePorts-1:0],
input wire [Registerlength-1:0]writeData [numWritePorts-1:0] 

);


logic  [Registerlength-1:0]vecRegisters [numRegisters-1:0] ;



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