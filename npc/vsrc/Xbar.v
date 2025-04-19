// // import "DPI-C" function void monitor_mem_write(input int address, input byte data, input int wtype);

// module Xbar (
//     input              [  31:0]         araddr                     ,//  IFU(pc) or LSU
//     input                               arvalid                    ,//  IFU or LSU
//     output reg                          arready                    ,

//     output reg         [  31:0]         rdata                      ,// to IFU(inst) or WBU(rd_data)
//     output             [   1:0]         rresp                      ,//未添加
//     output reg                          rvalid                     ,
//     input                               rready                     ,

//     input              [  31:0]         awaddr                     ,
//     input                               awvalid                    ,
//     output reg                          awready                    ,//未添加

//     input              [  31:0]         wdata                      ,// LSU
//     input              [   3:0]         wstrb                      ,
//     input                               wvalid                     ,//  LSU
//     output reg                          wready                     ,
    
//     output reg         [   1:0]         bresp                      ,//未添加
//     output reg                          bvalid                     ,//未添加
//     input                               bready                     ,//未添加

// //***********************************RAM*********************************//    
//     //AR master读地址
//     output reg         [  31:0]         s0_araddr                  ,//  IFU(pc) or LSU
//     output reg                          s0_arvalid                 ,//  IFU or LSU
//     input                               s0_arready                 ,

//     //R master 读数据
//     input              [  31:0]         s0_rdata                   ,// to IFU(inst) or WBU(rd_data)
//     input              [   1:0]         s0_rresp                   ,// 目前只返回0
//     input                               s0_rvalid                  ,
//     output reg                          s0_rready                  ,

//     //AW master 写地址 未完善
//     output reg         [  31:0]         s0_awaddr                  ,
//     output reg                          s0_awvalid                 ,
//     input                               s0_awready                 ,//

//     //W master 写数据  未完善
//     output reg         [  31:0]         s0_wdata                   ,// LSU
//     output reg         [   3:0]         s0_wstrb                   ,
//     output reg                          s0_wvalid                  ,//  LSU
//     input                               s0_wready                  ,
    
//     // // B 写回复
//     input              [   1:0]         s0_bresp                   ,// 目前只会返回0
//     input                               s0_bvalid                  ,//
//     output reg                          s0_bready                  ,//
// //***********************************UART*********************************//    
//     //AR master读地址
//     output reg         [  31:0]         s1_araddr                  ,//  IFU(pc) or LSU
//     output reg                          s1_arvalid                 ,//  IFU or LSU
//     input                               s1_arready                 ,

//     //R master 读数据
//     input              [  31:0]         s1_rdata                   ,// to IFU(inst) or WBU(rd_data)
//     input              [   1:0]         s1_rresp                   ,// 目前只返回0
//     input                               s1_rvalid                  ,
//     output reg                          s1_rready                  ,

//     //AW master 写地址 未完善
//     output reg         [  31:0]         s1_awaddr                  ,
//     output reg                          s1_awvalid                 ,
//     input                               s1_awready                 ,//

//     //W master 写数据  未完善
//     output reg         [  31:0]         s1_wdata                   ,// LSU
//     output reg         [   3:0]         s1_wstrb                   ,
//     output reg                          s1_wvalid                  ,//  LSU
//     input                               s1_wready                  ,
    
//     // // B 写回复
//     input              [   1:0]         s1_bresp                   ,// 目前只会返回0
//     input                               s1_bvalid                  ,//
//     output reg                          s1_bready                   //
// );

//   localparam UART_BASE  = 32'ha0000000;
//   localparam UART_MASK  = 32'hfffff000;
//   localparam CLINT_BASE = 32'h20000000;
//   localparam CLINT_MASK = 32'hfffff000;
//   localparam SRAM_BASE  = 32'h80000000;
//   localparam SRAM_MASK  = 32'hff000000;

// //***********************************master*****************************//
// //AR master读地址
// reg                    [  31:0]         m_araddr                  ;
// reg                                     m_arvalid                 ;
// reg                                     m_arready                 ;
// //R master 读数据
// reg                    [  31:0]         m_rdata                   ;
// reg                    [   1:0]         m_rresp                   ;
// reg                                     m_rvalid                  ;
// reg                                     m_rready                  ;
// //AW master 写地址 未完善
// reg                    [  31:0]         m_awaddr                  ;
// reg                                     m_awvalid                 ;
// reg                                     m_awready                 ;
// //W master 写数据  未完善
// reg                    [  31:0]         m_wdata                   ;
// reg                    [   3:0]         m_wstrb                   ;
// reg                                     m_wvalid                  ;
// reg                                     m_wready                  ;
// // // B 写回复
// reg                    [   1:0]         m_bresp                   ;
// reg                                     m_bvalid                  ;
// reg                                     m_bready                  ;

// //***********************************slave****************************//
// //AR master读地址
// reg                    [  31:0]         s_araddr                  ;
// reg                                     s_arvalid                 ;
// reg                                     s_arready                 ;
// //R master 读数据
// reg                    [  31:0]         s_rdata                   ;
// reg                    [   1:0]         s_rresp                   ;
// reg                                     s_rvalid                  ;
// reg                                     s_rready                  ;
// //AW master 写地址 未完善
// reg                    [  31:0]         s_awaddr                  ;
// reg                                     s_awvalid                 ;
// reg                                     s_awready                 ;
// //W master 写数据  未完善
// reg                    [  31:0]         s_wdata                   ;
// reg                    [   3:0]         s_wstrb                   ;
// reg                                     s_wvalid                  ;
// reg                                     s_wready                  ;
// // // B 写回复
// reg                    [   1:0]         s_bresp                   ;
// reg                                     s_bvalid                  ;
// reg                                     s_bready                  ;

// // //读-master: IFU/LSU
// // always @(*) begin
// //         m_arvalid  = 1'b0;
// //         m_rready = 1'b0;
// //     if (lsu_arvalid | lsu_rready) begin
// //         m_araddr = ((lsu_araddr - 32'h80000000 )>>2) ;
// //         m_arvalid   = lsu_arvalid;
// //         lsu_arready = m_arready;

// //         lsu_rdata = m_rdata;                                       
// //         lsu_rvalid = m_rvalid;                                    
// //         m_rready = lsu_rready;                                     
// //     end else if(ifu_arvalid | ifu_rready) begin
// //         m_araddr = ((ifu_araddr - 32'h80000000 )>>2);
// //         m_arvalid   = ifu_arvalid;
// //         ifu_arready = m_arready;

// //         ifu_rdata = m_rdata;
// //         ifu_rvalid = m_rvalid;
// //         m_rready = ifu_rready;
// //     end

// // end
// //
// always @(*) begin
//     s0_araddr = araddr;//out
//     s0_arvalid   = arvalid;//out
//     arready = s0_arready;

//     rdata = s0_rdata;//in
//     rvalid = s0_rvalid;//in
//     s0_rready = rready;//out
// end

// //写数据-master：只有LSU  //写的话根据地址去选择   
// always @(*) begin
//     if (awaddr == 32'ha000_03f8) begin
//         s1_awaddr = awaddr;
//         s1_awvalid = awvalid;
//         awready = s1_awready;

//         s1_wdata  =  wdata  ;
//         s1_wstrb  =  wstrb  ;
//         s1_wvalid =  wvalid ;
//         wready = s1_wready  ;

//         bresp = s1_bresp  ;
//         bvalid = s1_bvalid ;
//         s1_bready = bready;
//     end else 
//     begin
//         s0_awaddr  = ((awaddr - 32'h80000000 )>>2) ;
//         s0_awvalid = awvalid;
//         awready = s0_awready;

//         s0_wdata  =  wdata  ;
//         s0_wstrb  =  wstrb  ;
//         s0_wvalid =  wvalid ;
//         wready = s0_wready  ;

//         bresp = s0_bresp  ;
//         bvalid = s0_bvalid ;
//         s0_bready = bready;
//     end

// end





// endmodule