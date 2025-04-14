import "DPI-C" function int pmem_read(input int raddr);

module clint_slave#(
	parameter DW = 32,
	parameter AW = 32,
	parameter MEM_NUM = 32'h1_0000
)(
    input  wire                         clk                        ,
    input  wire                         rst                        ,
//读事务总线
    input  wire        [AW-1:0]         araddr                   ,
    input                               arvalid                  ,
    output reg                          arready                  ,
    
    output reg         [DW-1:0]         rdata                    ,
    output reg         [   1:0]         rresp                    ,
    output reg                          rvalid                   ,
    input                               rready                   

    // input  wire        [AW-1:0]         awaddr                   ,
    // input                               awvalid                  ,
    // output reg                          awready                  ,

    // input  wire        [DW-1:0]         wdata                    ,
    // input              [   3:0]         wstrb                    ,
    // input  wire                         wvalid                   ,
    // output reg                          wready                   ,

    // output reg         [   1:0]         bresp                    ,
    // output reg                          bvalid                   ,
    // input                               bready                    
);
//目前该模块只读   
reg[DW-1:0] memory[0:MEM_NUM-1];
localparam READ_IDLE = 2'b00 ;
localparam MASTER_READ_DATA = 2'b01;

reg [1:0] state , next_state;
reg [AW-1:0]	r_addr;//寄存read地址
always @(posedge clk or posedge rst) begin
	if(rst) begin
		state <= READ_IDLE;
	end
	else begin
		state <= next_state; 
	end
end

//读事务
always @(*) begin
	case (state)
		READ_IDLE: begin
			arready = 1'b0;
			rvalid =1'b0;
			if(arvalid ) begin
					r_addr = araddr;//master 读地址有效，寄存地址
					arready = 1'b1;
					next_state = MASTER_READ_DATA; 
			end 
			else next_state = READ_IDLE;
		end 

		MASTER_READ_DATA: begin
			arready = 1'b0;//slave 拉低接收地址ready信号
				if(r_addr == 32'ha000_0048) rdata = pmem_read (r_addr);
				else if(r_addr == 32'ha000_004c) rdata = pmem_read (r_addr);
				rresp = 2'b0;
				rvalid =1'b1;// 拉高数据有效信号

			if (rready) begin //等待data握手
					next_state = READ_IDLE;
				end else begin
					next_state = MASTER_READ_DATA; //如果master 的 addr有效（en） 且master接收数据ready 则发送输出，数据会在下一时钟周期输出
				end
			end
		default: begin
		end
	endcase

end

endmodule