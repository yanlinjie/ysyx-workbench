module ifetch(
	//from pc
	input  wire[31:0] pc_addr_i, //指令地址
	//from rom 
	input  wire[31:0] rom_inst_i, //指令
	//to rom
	output wire[31:0] if2rom_addr_o, //指令地址,指令地址给rom，从rom中获取指令
	// to if_id
	output wire[31:0] inst_addr_o, //输出指令地址
	output wire[31:0] inst_o       //输出指令
	);


	assign if2rom_addr_o = pc_addr_i;
	
	assign inst_addr_o  = pc_addr_i;
	
	assign inst_o = rom_inst_i;



endmodule