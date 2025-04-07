module instruction_mem (
    input clk,
    input [31: 0] pc,

    output [31: 0] instruction
);


	reg[31:0] rom_mem[0:40960000];  //4096 个 32b的 空间 
	

	assign	instruction = rom_mem[pc>>2];


endmodule

