import "DPI-C" function void monitor_mem_write(input int address, input byte data, input int wtype);
module uart_slave #(
	parameter DW = 32,
	parameter AW = 32,
	parameter MEM_NUM = 32'h1000
)(
    input  wire                         clk                        ,
    input  wire                         rst                        ,
//读事务总线
    input  wire        [AW-1:0]         araddr                   ,
    input                               arvalid                  ,//ask read valid
    output reg                          arready                  ,//ask read ready
    
    output reg         [DW-1:0]         rdata                    ,
    output reg         [   1:0]         rresp                    ,
    output reg                          rvalid                   ,
    input                               rready                   ,//master 接收data ready

    input  wire        [AW-1:0]         awaddr                   ,
    input                               awvalid                  ,
    output reg                          awready                  ,

    input  wire        [DW-1:0]         wdata                    ,
    input              [   3:0]         wstrb                    ,
    input  wire                         wvalid                   ,
    output reg                          wready                   ,

    output reg         [   1:0]         bresp                    ,
    output reg                          bvalid                   ,
    input                               bready                    
);
//目前只用到了写！
//uart 软件地址定义在 /home/ylj/ysyx-workbench/abstract-machine/am/src/riscv/npc/include/npc.h
//更改地址的话，需要去头文件中更改
reg[DW-1:0] memory[0:MEM_NUM-1];
wire [31:0] wmask_full;//wmask展开
reg  [10:0] cnt_2 ;
reg  [10:0] cnt_3 ;

localparam WRITE_IDLE = 2'b00 ;
localparam MASTER_WRITE_DATA = 2'b01;
localparam DELAY_WREADY = 40;
localparam DELAY_BVALID = 30;
reg [1:0] write_state , write_next_state;

assign wmask_full = { {8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}} };

//延迟wready 和 awready返回信号
always @(posedge clk or posedge rst) begin
  if (rst)
    cnt_2 <= 0;
  else if ( awvalid  && cnt_2 < DELAY_WREADY)
    cnt_2 <= cnt_2 + 1;
  else if (cnt_2 == DELAY_WREADY)
    cnt_2 <= 0;  // 成功传输后重置
end

//延迟写回复bvalid返回信号
always @(posedge clk or posedge rst) begin
  if (rst)
    cnt_3 <= 0;
  else if (write_state == MASTER_WRITE_DATA && cnt_3 < DELAY_BVALID)
    cnt_3 <= cnt_3 + 1;
  else if (cnt_3 == DELAY_BVALID)
    cnt_3 <= 0;  // 成功传输后重置
end



always @(posedge clk or posedge rst) begin
	if(rst) begin
		write_state <= WRITE_IDLE;
	end
	else begin
		write_state <= write_next_state;
	end
end

always @(*)begin
	case (write_state)
		WRITE_IDLE:begin
			awready = 1'b0;			
			wready = 1'b0;		
			bvalid = 1'b0;

			if(awvalid && wvalid) begin
				if(cnt_2 == DELAY_WREADY) begin
				awready = 1'b1;			
				wready = 1'b1;	
				write_next_state = MASTER_WRITE_DATA;
				end 
			end
			else write_next_state = WRITE_IDLE;
		end

		MASTER_WRITE_DATA:begin
			if (cnt_3 == DELAY_BVALID) begin
				bresp = 2'b00;//表示写数据ok
				bvalid = 1'b1;
				if(bready) begin
					write_next_state = WRITE_IDLE;
				end else write_next_state = MASTER_WRITE_DATA;
			end	
		end 
	default:begin
	end
	endcase	
end

always @(posedge clk)begin
	if(~rst && awvalid && wvalid && awready && wready)
	begin
			monitor_mem_write(awaddr, wdata[7:0], 0);
			//后续如果要写入寄存器中，应该是要做字节对齐，目前我还没写  
		// memory[awaddr] <= (wdata & wmask_full) | ( memory[awaddr] & ~wmask_full );
	end

end




endmodule