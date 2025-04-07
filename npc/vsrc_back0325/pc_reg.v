module pc_reg(
	input wire 		 clk,
	input wire 		 rst,
	output reg[31:0] pc_o
);

	always @(posedge clk) begin
		if(rst == 1'b0)
			pc_o <=32'h80000000;
		else
			pc_o <= pc_o + 32'd4;
	end




endmodule
