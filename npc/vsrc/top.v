module top(
    input                               clk                        ,
    input                               rst                         
);



// output declaration of module riscv32
// wire [31:0] M0_raddr;
// wire M0_arvalid;
// wire M0_rready;
// wire [31:0] M0_awaddr;
// wire M0_awvalid;
// wire [31:0] M0_wdata;
// wire [3:0] M0_wstrb;
// wire M0_wvalid;
// wire M0_bready;
// wire [31:0] M1_raddr;
// wire M1_arvalid;
// wire M1_rready;
// wire [31:0] M1_awaddr;
// wire M1_awvalid;
// wire [31:0] M1_wdata;
// wire [3:0] M1_wstrb;
// wire M1_wvalid;
// wire M1_bready;

//   parameter ADDR_WIDTH = 32,
localparam  ADDR_WIDTH = 32;
localparam DATA_WIDTH = 32;

// output declaration of module Xbar

//AR master读地址
wire                   [  31:0]         ifu_araddr                   ;
wire                                    ifu_arvalid                 ;
wire                                    ifu_arready                 ;
//R master 读数据
wire                   [  31:0]         ifu_rdata                   ;
wire                   [   1:0]         ifu_rresp                   ;
wire                                    ifu_rvalid                  ;
wire                                    ifu_rready                  ;
//AW master 写地址 未完善
wire                   [  31:0]         ifu_awaddr                  ;
wire                                    ifu_awvalid                 ;
wire                                    ifu_awready                 ;
//W master 写数据  未完善
wire                   [  31:0]         ifu_wdata                   ;
wire                   [   3:0]         ifu_wstrb                   ;
wire                                    ifu_wvalid                  ;
wire                                    ifu_wready                  ;
// // B 写回复
wire                   [   1:0]         ifu_bresp                   ;
wire                                    ifu_bvalid                  ;
wire                                    ifu_bready                  ;

//AR master读地址
wire                   [  31:0]         lsu_araddr                   ;
wire                                    lsu_arvalid                 ;
wire                                    lsu_arready                 ;
//R master 读数据
wire                   [  31:0]         lsu_rdata                   ;
wire                   [   1:0]         lsu_rresp                   ;
wire                                    lsu_rvalid                  ;
wire                                    lsu_rready                  ;
//AW master 写地址 未完善
wire                   [  31:0]         lsu_awaddr                  ;
wire                                    lsu_awvalid                 ;
wire                                    lsu_awready                 ;
//W master 写数据  未完善
wire                   [  31:0]         lsu_wdata                   ;
wire                   [   3:0]         lsu_wstrb                   ;
wire                                    lsu_wvalid                  ;
wire                                    lsu_wready                  ;
// // B 写回复
wire                   [   1:0]         lsu_bresp                   ;
wire                                    lsu_bvalid                  ;
wire                                    lsu_bready                  ;

wire                   [  31:0]         s0_araddr                   ;
wire                                    s0_arvalid                 ;
wire                                    s0_arready                 ;
wire                   [  31:0]         s0_rdata                   ;
wire                   [   1:0]         s0_rresp                   ;
wire                                    s0_rvalid                  ;
wire                                    s0_rready                  ;
wire                   [  31:0]         s0_awaddr                  ;
wire                                    s0_awvalid                 ;
wire                                    s0_awready                 ;
wire                   [  31:0]         s0_wdata                   ;
wire                   [   3:0]         s0_wstrb                   ;
wire                                    s0_wvalid                  ;
wire                                    s0_wready                  ;
wire                   [   1:0]         s0_bresp                   ;
wire                                    s0_bvalid                  ;
wire                                    s0_bready                  ;

wire                   [  31:0]         s1_araddr                   ;
wire                                    s1_arvalid                 ;
wire                                    s1_arready                 ;
wire                   [  31:0]         s1_rdata                   ;
wire                   [   1:0]         s1_rresp                   ;
wire                                    s1_rvalid                  ;
wire                                    s1_rready                  ;
wire                   [  31:0]         s1_awaddr                  ;
wire                                    s1_awvalid                 ;
wire                                    s1_awready                 ;
wire                   [  31:0]         s1_wdata                   ;
wire                   [   3:0]         s1_wstrb                   ;
wire                                    s1_wvalid                  ;
wire                                    s1_wready                  ;
wire                   [   1:0]         s1_bresp                   ;
wire                                    s1_bvalid                  ;
wire                                    s1_bready                  ;

wire                   [  31:0]         s2_araddr                   ;
wire                                    s2_arvalid                 ;
wire                                    s2_arready                 ;
wire                   [  31:0]         s2_rdata                   ;
wire                   [   1:0]         s2_rresp                   ;
wire                                    s2_rvalid                  ;
wire                                    s2_rready                  ;
wire                   [  31:0]         s2_awaddr                  ;
wire                                    s2_awvalid                 ;
wire                                    s2_awready                 ;
wire                   [  31:0]         s2_wdata                   ;
wire                   [   3:0]         s2_wstrb                   ;
wire                                    s2_wvalid                  ;
wire                                    s2_wready                  ;
wire                   [   1:0]         s2_bresp                   ;
wire                                    s2_bvalid                  ;
wire                                    s2_bready                  ;



riscv32 u_riscv32(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .M0_raddr                          (ifu_araddr                ),
    .M0_arvalid                        (ifu_arvalid               ),
    .M0_arready                        (ifu_arready               ),

    .M0_rdata                          (ifu_rdata                 ),
    .M0_rresp                          (ifu_rresp                 ),
    .M0_rvalid                         (ifu_rvalid                ),
    .M0_rready                         (ifu_rready                ),

    .M0_awaddr                         (ifu_awaddr                ),
    .M0_awvalid                        (ifu_awvalid               ),
    .M0_awready                        (ifu_awready               ),

    .M0_wdata                          (ifu_wdata                 ),
    .M0_wstrb                          (ifu_wstrb                 ),
    .M0_wvalid                         (ifu_wvalid                ),
    .M0_wready                         (ifu_wready                ),

    .M0_bresp                          (ifu_bresp                 ),
    .M0_bvalid                         (ifu_bvalid                ),
    .M0_bready                         (ifu_bready                ),

    .M1_raddr                          (lsu_araddr                ),
    .M1_arvalid                        (lsu_arvalid               ),
    .M1_arready                        (lsu_arready               ),

    .M1_rdata                          (lsu_rdata                 ),
    .M1_rresp                          (lsu_rresp                 ),
    .M1_rvalid                         (lsu_rvalid                ),
    .M1_rready                         (lsu_rready                ),

    .M1_awaddr                         (lsu_awaddr                ),
    .M1_awvalid                        (lsu_awvalid               ),
    .M1_awready                        (lsu_awready               ),

    .M1_wdata                          (lsu_wdata                 ),
    .M1_wstrb                          (lsu_wstrb                 ),
    .M1_wvalid                         (lsu_wvalid                ),
    .M1_wready                         (lsu_wready                ),

    .M1_bresp                          (lsu_bresp                 ),
    .M1_bvalid                         (lsu_bvalid                ),
    .M1_bready                         (lsu_bready                ) 
);



Xbar #(
    .ADDR_WIDTH 	(32  ),
    .DATA_WIDTH 	(32  ))
u_Xbar(
    .clk         	(clk          ),
    .reset       	(rst        ),

    .ifu_awaddr  	(ifu_awaddr   ),
    .ifu_awvalid 	(ifu_awvalid  ),
    .ifu_awready 	(ifu_awready  ),

    .ifu_wdata   	(ifu_wdata    ),
    .ifu_wstrb   	(ifu_wstrb    ),
    .ifu_wvalid  	(ifu_wvalid   ),
    .ifu_wready  	(ifu_wready   ),


    .ifu_bresp   	(ifu_bresp    ),
    .ifu_bvalid  	(ifu_bvalid   ),
    .ifu_bready  	(ifu_bready   ),

    .ifu_araddr  	(ifu_araddr   ),
    .ifu_arvalid 	(ifu_arvalid  ),
    .ifu_arready 	(ifu_arready  ),

    .ifu_rdata   	(ifu_rdata    ),
    .ifu_rresp   	(ifu_rresp    ),
    .ifu_rvalid  	(ifu_rvalid   ),
    .ifu_rready  	(ifu_rready   ),

    .lsu_awaddr  	(lsu_awaddr   ),
    .lsu_awvalid 	(lsu_awvalid  ),
    .lsu_awready 	(lsu_awready  ),

    .lsu_wdata   	(lsu_wdata    ),
    .lsu_wstrb   	(lsu_wstrb    ),
    .lsu_wvalid  	(lsu_wvalid   ),
    .lsu_wready  	(lsu_wready   ),

    .lsu_bresp   	(lsu_bresp    ),
    .lsu_bvalid  	(lsu_bvalid   ),
    .lsu_bready  	(lsu_bready   ),

    .lsu_araddr  	(lsu_araddr   ),
    .lsu_arvalid 	(lsu_arvalid  ),
    .lsu_arready 	(lsu_arready  ),

    .lsu_rdata   	(lsu_rdata    ),
    .lsu_rresp   	(lsu_rresp    ),
    .lsu_rvalid  	(lsu_rvalid   ),
    .lsu_rready  	(lsu_rready   ),

//UART
    .s0_awaddr   	(s0_awaddr    ),
    .s0_awvalid  	(s0_awvalid   ),
    .s0_awready  	(s0_awready   ),
    .s0_wdata    	(s0_wdata     ),
    .s0_wstrb    	(s0_wstrb     ),
    .s0_wvalid   	(s0_wvalid    ),
    .s0_wready   	(s0_wready    ),
    .s0_bresp    	(s0_bresp     ),
    .s0_bvalid   	(s0_bvalid    ),
    .s0_bready   	(s0_bready    ),
    .s0_araddr   	(s0_araddr    ),
    .s0_arvalid  	(s0_arvalid   ),
    .s0_arready  	(s0_arready   ),
    .s0_rdata    	(s0_rdata     ),
    .s0_rresp    	(s0_rresp     ),
    .s0_rvalid   	(s0_rvalid    ),
    .s0_rready   	(s0_rready    ),

    .s1_awaddr   	(s1_awaddr    ),
    .s1_awvalid  	(s1_awvalid   ),
    .s1_awready  	(s1_awready   ),
    .s1_wdata    	(s1_wdata     ),
    .s1_wstrb    	(s1_wstrb     ),
    .s1_wvalid   	(s1_wvalid    ),
    .s1_wready   	(s1_wready    ),
    .s1_bresp    	(s1_bresp     ),
    .s1_bvalid   	(s1_bvalid    ),
    .s1_bready   	(s1_bready    ),
    .s1_araddr   	(s1_araddr    ),
    .s1_arvalid  	(s1_arvalid   ),
    .s1_arready  	(s1_arready   ),
    .s1_rdata    	(s1_rdata     ),
    .s1_rresp    	(s1_rresp     ),
    .s1_rvalid   	(s1_rvalid    ),
    .s1_rready   	(s1_rready    ),
//sram
    .s2_awaddr   	(s2_awaddr    ),
    .s2_awvalid  	(s2_awvalid   ),
    .s2_awready  	(s2_awready   ),
    
    .s2_wdata    	(s2_wdata     ),
    .s2_wstrb    	(s2_wstrb     ),
    .s2_wvalid   	(s2_wvalid    ),
    .s2_wready   	(s2_wready    ),

    .s2_bresp    	(s2_bresp     ),
    .s2_bvalid   	(s2_bvalid    ),
    .s2_bready   	(s2_bready    ),

    .s2_araddr   	(s2_araddr    ),
    .s2_arvalid  	(s2_arvalid   ),
    .s2_arready  	(s2_arready   ),

    .s2_rdata    	(s2_rdata     ),
    .s2_rresp    	(s2_rresp     ),
    .s2_rvalid   	(s2_rvalid    ),
    .s2_rready   	(s2_rready    )
);



// output declaration of module dual_ram_template

dual_ram_template #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (80960000                  ) 
    )
u_dual_ram_template(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

//读事务总线
    .r_addr_i                          (s2_araddr                 ),
    .arvalid                           (s2_arvalid                ),
    .arready                           (s2_arready                ),
    
    .r_data_o                          (s2_rdata                  ),
    .rresp                             (s2_rresp                  ),
    .rvalid                            (s2_rvalid                 ),// output reg rvalid,
    .rready                            (s2_rready                 ),// input 	rready,//master 接收data ready

    .w_addr_i                          (s2_awaddr                 ),
    .awvalid                           (s2_awvalid                ),
    .awready                           (s2_awready                ),

    .w_data_i                          (s2_wdata                  ),
    .wmask                             (s2_wstrb                  ),
    .wen                               (s2_wvalid                 ),
    .wready                            (s2_wready                 ),

    .bresp                             (s2_bresp                  ),
    .bvalid                            (s2_bvalid                 ),
    .bready                            (s2_bready                 ) 

);



endmodule
