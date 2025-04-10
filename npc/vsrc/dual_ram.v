
import "DPI-C" function void monitor_mem_write(input int address, input int data, input int wtype);
import "DPI-C" function int pmem_read(input int raddr);
module dual_ram_template #(
	parameter DW = 32,
	parameter AW = 32,
	parameter MEM_NUM = 65536
)
(
    input  wire                         clk                        ,
    input  wire                         rst                        ,
//读事务总线
    input                               arvalid                    ,//ask read valid
    output reg                          arready                    ,//ask read ready
    input                               rready                     ,//master 接收data ready
    output reg                          rvalid                     ,

    output wire                         wready                     ,
    input  wire                         wen                        ,
    input  wire        [AW-1:0]         w_addr_i                   ,
	input awvalid,
    input  wire        [DW-1:0]         w_data_i                   ,

    input  wire        [AW-1:0]         r_addr_i                   ,
    input              [   3:0]         wmask                      ,
    output reg         [DW-1:0]         r_data_o                    
);
	reg[DW-1:0] memory[0:MEM_NUM-1];
	wire [31:0] wmask_full;//wmask展开






localparam READ_IDLE = 2'b00 ;
localparam MASTER_READ_DATA = 2'b01;
localparam WAIT_MASTER_READY = 2'b10;

reg [1:0] state , next_state;
reg [AW-1:0]	r_addr;//寄存read地址
always @(posedge clk or posedge rst) begin
	if(rst)
		state <= READ_IDLE;
	else state <= next_state; 
	
end
assign wready = 1'b1;
//读事务
always @(*) begin
	case (state)
		READ_IDLE: begin
			arready = 1'b1;
			rvalid =1'b0;
			// rvalid_1 =1'b0;	
			if(arvalid) begin
				r_addr = r_addr_i;//master 读地址有效，寄存地址
				if ( ~ rready) begin
					next_state = WAIT_MASTER_READY;
				end else begin
					next_state = MASTER_READ_DATA; //如果master 的 addr有效（en） 且master接收数据ready 则发送输出，数据会在下一时钟周期输出
				end
			end else next_state = READ_IDLE;
		end 

		MASTER_READ_DATA: begin
			arready = 1'b0;
			if(r_addr == 32'h28000012) r_data_o = pmem_read (r_addr);
			else if(r_addr == 32'h28000013) r_data_o = pmem_read (r_addr);
			else r_data_o = memory[r_addr];
			rvalid =1'b1;
			next_state = READ_IDLE;
		end 

		WAIT_MASTER_READY: begin
			if(rready) next_state = MASTER_READ_DATA;
			else next_state = WAIT_MASTER_READY;
		end 
		default: begin
		end
	endcase

end

	assign wmask_full = { {8{wmask[3]}}, {8{wmask[2]}}, {8{wmask[1]}}, {8{wmask[0]}} };
wire [AW-1:0] w_addr_i_1;
assign w_addr_i_1 = awvalid ? w_addr_i : w_addr_i_1;
	always @(posedge clk)begin
		if(~rst && wen)
		begin
			memory[w_addr_i_1] <= (w_data_i & wmask_full) | ( memory[w_addr_i_1] & ~wmask_full );
			monitor_mem_write(w_addr_i_1, w_data_i, 0);  
		end

	end

endmodule