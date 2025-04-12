module Xbar (
    //AR master读地址
    input              [  31:0]         raddr                      ,//  IFU(pc) or LSU
    input                               arvalid                    ,//  IFU or LSU
    output                              arready                    ,

    //R master 读数据
    output             [  31:0]         rdata                      ,// to IFU(inst) or WBU(rd_data)
    output             [   1:0]         rresp                      ,//未添加
    output                              rvalid                     ,
    input                               rready                     ,

    //AW master 写地址 未完善
    input              [  31:0]         awaddr                     ,
    input                               awvalid                    ,
    output                              awready                    ,//未添加

    //W master 写数据  未完善
    input              [  31:0]         wdata                      ,// LSU
    input              [   3:0]         wstrb                      ,
    input                               wvalid                     ,//  LSU
    output                              wready                     ,
    
    // // B 写回复
    output             [   1:0]         bresp                      ,//未添加
    output                              bvalid                     ,//未添加
    input                               bready                      //未添加
    
);
    
endmodule