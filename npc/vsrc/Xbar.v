module Xbar (
//***********************************IFU*********************************//    
    //AR master读地址
    input              [  31:0]         ifu_araddr                 ,//  IFU(pc) or LSU
    input                               ifu_arvalid                ,//  IFU or LSU
    output reg                          ifu_arready                ,

    //R master 读数据
    output reg         [  31:0]         ifu_rdata                  ,// to IFU(inst) or WBU(rd_data)
    output             [   1:0]         ifu_rresp                  ,//未添加
    output reg                          ifu_rvalid                 ,
    input                               ifu_rready                 ,

//***********************************LSU*********************************//    
        //AR master读地址
    input              [  31:0]         lsu_araddr                 ,//  IFU(pc) or LSU
    input                               lsu_arvalid                ,//  IFU or LSU
    output reg                          lsu_arready                ,

    //R master 读数据
    output reg         [  31:0]         lsu_rdata                  ,// to IFU(inst) or WBU(rd_data)
    output             [   1:0]         lsu_rresp                  ,//未添加
    output reg                          lsu_rvalid                 ,
    input                               lsu_rready                 ,

    //AW master 写地址 未完善
    input              [  31:0]         lsu_awaddr                 ,
    input                               lsu_awvalid                ,
    output                              lsu_awready                ,//未添加

    //W master 写数据  未完善
    input              [  31:0]         lsu_wdata                  ,// LSU
    input              [   3:0]         lsu_wstrb                  ,
    input                               lsu_wvalid                 ,//  LSU
    output                              lsu_wready                 ,
    
    // // B 写回复
    output             [   1:0]         lsu_bresp                  ,//未添加
    output                              lsu_bvalid                 ,//未添加
    input                               lsu_bready                 ,//未添加

//***********************************RAM*********************************//    
    //AR master读地址
    output reg         [  31:0]         s0_araddr                  ,//  IFU(pc) or LSU
    output reg                          s0_arvalid                 ,//  IFU or LSU
    input                               s0_arready                 ,

    //R master 读数据
    input              [  31:0]         s0_rdata                   ,// to IFU(inst) or WBU(rd_data)
    input              [   1:0]         s0_rresp                   ,// 目前只返回0
    input                               s0_rvalid                  ,
    output reg                          s0_rready                  ,

    //AW master 写地址 未完善
    output             [  31:0]         s0_awaddr                  ,
    output                              s0_awvalid                 ,
    input                               s0_awready                 ,//

    //W master 写数据  未完善
    output             [  31:0]         s0_wdata                   ,// LSU
    output             [   3:0]         s0_wstrb                   ,
    output                              s0_wvalid                  ,//  LSU
    input                               s0_wready                  ,
    
    // // B 写回复
    input              [   1:0]         s0_bresp                   ,// 目前只会返回0
    input                               s0_bvalid                  ,//
    output                              s0_bready                   //

);

//读通道
always @(*) begin
    s0_arvalid  = 1'b0;
    s0_rready = 1'b0;
    if (lsu_arvalid | lsu_rready) begin
        s0_araddr = lsu_araddr;//out
        s0_arvalid   = lsu_arvalid;//out
        lsu_arready = s0_arready;

        lsu_rdata = s0_rdata;//in
        lsu_rvalid = s0_rvalid;//in
        s0_rready = lsu_rready;//out
    end else if(ifu_arvalid | ifu_rready)  begin
        s0_araddr = ifu_araddr;
        s0_arvalid   = ifu_arvalid;
        ifu_arready = s0_arready;

        ifu_rdata = s0_rdata;
        ifu_rvalid = s0_rvalid;
        s0_rready = ifu_rready;

    end 
end


assign  s0_awaddr  = lsu_awaddr ;
assign  s0_awvalid = lsu_awvalid;
assign  lsu_awready = s0_awready;

assign s0_wdata  =  lsu_wdata  ;
assign s0_wstrb  =  lsu_wstrb  ;
assign s0_wvalid =  lsu_wvalid ;
assign lsu_wready = s0_wready  ;

assign lsu_bresp = s0_bresp  ;
assign lsu_bvalid = s0_bvalid ;
assign s0_bready = lsu_bready;

// always @(*) begin
//     arvalid   = 1'b0;
//     rready = 1'b0;
//     if (ls_arvalid | ls_rready) begin
//         araddr = ((ls_read_mem_addr - 32'h80000000 )>>2);//out
//         arvalid   = ls_arvalid;//out
//         lsu_arready = arready;

//         lsu_rdata = rdata;//in
//         lsu_rvalid = rvalid;//in
//         rready = ls_rready;//out
//     end else if(read_en | if_rready)  begin
//         araddr = ((pc - 32'h80000000 )>>2);
//         arvalid   = read_en;
//         rready = if_rready;
//         ifu_rdata = rdata;
//         ifu_rvalid = rvalid;
//         ifu_arready = arready;
//     end 
// end

endmodule