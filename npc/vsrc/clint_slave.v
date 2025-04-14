module clint_slave#(
	parameter DW = 32,
	parameter AW = 32,
	parameter MEM_NUM = 32'h1_0000
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
//目前该模块只读   


endmodule