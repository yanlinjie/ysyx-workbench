module top(
    input                               clk                        ,
    input                               rst                         
);



    //AR master读地址
wire                   [  31:0]         ifu_araddr                 ;
wire                                    ifu_arvalid                ;
wire                                    ifu_arready                ;

    //R master 读数据
wire                   [  31:0]         ifu_rdata                  ;
wire                   [   1:0]         ifu_rresp                  ;
wire                                    ifu_rvalid                 ;
wire                                    ifu_rready                 ;

    //AR master读地址
wire                   [  31:0]         lsu_araddr                 ;
wire                                    lsu_arvalid                ;
wire                                    lsu_arready                ;

    //R master 读数据
wire                   [  31:0]         lsu_rdata                  ;
wire                   [   1:0]         lsu_rresp                  ;
wire                                    lsu_rvalid                 ;
wire                                    lsu_rready                 ;

    //AW master 写地址 未完善
wire                   [  31:0]         lsu_awaddr                 ;
wire                                    lsu_awvalid                ;
wire                                    lsu_awready                ;

    //W master 写数据  未完善
wire                   [  31:0]         lsu_wdata                  ;
wire                   [   3:0]         lsu_wstrb                  ;
wire                                    lsu_wvalid                 ;
wire                                    lsu_wready                 ;
    
    // // B 写回复
wire                   [   1:0]         lsu_bresp                  ;
wire                                    lsu_bvalid                 ;
wire                                    lsu_bready                 ;

//***********************************RAM*********************************//    
    //AR master读地址
wire                   [  31:0]         s0_araddr                  ;
wire                                    s0_arvalid                 ;
wire                                    s0_arready                 ;

    //R master 读数据
wire                   [  31:0]         s0_rdata                   ;
wire                   [   1:0]         s0_rresp                   ;
wire                                    s0_rvalid                  ;
wire                                    s0_rready                  ;

    //AW master 写地址 未完善
wire                   [  31:0]         s0_awaddr                  ;
wire                                    s0_awvalid                 ;
wire                                    s0_awready                 ;

    //W master 写数据  未完善
wire                   [  31:0]         s0_wdata                   ;
wire                   [   3:0]         s0_wstrb                   ;
wire                                    s0_wvalid                  ;
wire                                    s0_wready                  ;
    
    // // B 写回复
wire                   [   1:0]         s0_bresp                   ;
wire                                    s0_bvalid                  ;
wire                                    s0_bready                  ;


riscv32 u_riscv32(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .ifu_araddr                            (ifu_araddr                    ),
    .ifu_arvalid                           (ifu_arvalid                   ),//arvalid
    .ifu_arready                           (ifu_arready                   ),//arready

    .ifu_rdata                             (ifu_rdata                     ),
    .ifu_rresp                             (ifu_rresp                     ),//未添加
    .ifu_rvalid                            (ifu_rvalid                    ),// input                               rvalid                     ,
    .ifu_rready                            (ifu_rready                    ),//     output                              rready                     ,


    .lsu_araddr                            (lsu_araddr                   ),
    .lsu_arvalid                           (lsu_arvalid                  ),//arvalid
    .lsu_arready                           (lsu_arready                  ),//arready

    .lsu_rdata                             (lsu_rdata                    ),
    .lsu_rresp                             (lsu_rresp                    ),//未添加
    .lsu_rvalid                            (lsu_rvalid                   ),// input                               rvalid                     ,
    .lsu_rready                            (lsu_rready                   ),//     output                              rready                     ,

    .lsu_awaddr                            (lsu_awaddr                   ),
    .lsu_awvalid                           (lsu_awvalid                  ),
    .lsu_awready                           (lsu_awready                  ),//未添加

    .lsu_wdata                             (lsu_wdata                    ),
    .lsu_wstrb                             (lsu_wstrb                    ),
    .lsu_wvalid                            (lsu_wvalid                   ),
    .lsu_wready                            (lsu_wready                   ),
    
    .lsu_bresp                             (lsu_bresp                    ),//未添加
    .lsu_bvalid                            (lsu_bvalid                   ),//未添加
    .lsu_bready                            (lsu_bready                   ) //未添加


);


Xbar u_Xbar(
//***********************************IFU*********************************//    
    //AR master读地址
    .ifu_araddr                        (ifu_araddr                ),//  IFU(pc) or LSU
    .ifu_arvalid                       (ifu_arvalid               ),//  IFU or LSU
    .ifu_arready                       (ifu_arready               ),

    //R master 读数据
    .ifu_rdata                         (ifu_rdata                 ),// to IFU(inst) or WBU(rd_data)
    .ifu_rresp                         (ifu_rresp                 ),//未添加
    .ifu_rvalid                        (ifu_rvalid                ),
    .ifu_rready                        (ifu_rready                ),

//***********************************LSU*********************************//    
        //AR master读地址
    .lsu_araddr                        (lsu_araddr                ),//  IFU(pc) or LSU
    .lsu_arvalid                       (lsu_arvalid               ),//  IFU or LSU
    .lsu_arready                       (lsu_arready               ),

    //R master 读数据
    .lsu_rdata                         (lsu_rdata                 ),// to IFU(inst) or WBU(rd_data)
    .lsu_rresp                         (lsu_rresp                 ),//未添加
    .lsu_rvalid                        (lsu_rvalid                ),
    .lsu_rready                        (lsu_rready                ),

    //AW master 写地址 未完善
    .lsu_awaddr                        (lsu_awaddr                ),
    .lsu_awvalid                       (lsu_awvalid               ),
    .lsu_awready                       (lsu_awready               ),//未添加

    //W master 写数据  未完善
    .lsu_wdata                         (lsu_wdata                 ),// LSU
    .lsu_wstrb                         (lsu_wstrb                 ),
    .lsu_wvalid                        (lsu_wvalid                ),//  LSU
    .lsu_wready                        (lsu_wready                ),
    
    // // B 写回复
    .lsu_bresp                         (lsu_bresp                 ),//未添加
    .lsu_bvalid                        (lsu_bvalid                ),//未添加
    .lsu_bready                        (lsu_bready                ),//未添加

//***********************************RAM*********************************//    
    //AR master读地址
    .s0_araddr                         (s0_araddr                 ),//  IFU(pc) or LSU
    .s0_arvalid                        (s0_arvalid                ),//  IFU or LSU
    .s0_arready                        (s0_arready                ),

    //R master 读数据
    .s0_rdata                          (s0_rdata                  ),// to IFU(inst) or WBU(rd_data)
    .s0_rresp                          (s0_rresp                  ),// 目前只返回0
    .s0_rvalid                         (s0_rvalid                 ),
    .s0_rready                         (s0_rready                 ),

    //AW master 写地址 未完善
    .s0_awaddr                         (s0_awaddr                 ),
    .s0_awvalid                        (s0_awvalid                ),
    .s0_awready                        (s0_awready                ),//

    //W master 写数据  未完善
    .s0_wdata                          (s0_wdata                  ),// LSU
    .s0_wstrb                          (s0_wstrb                  ),
    .s0_wvalid                         (s0_wvalid                 ),//  LSU
    .s0_wready                         (s0_wready                 ),
    
    // // B 写回复
    .s0_bresp                          (s0_bresp                  ),// 目前只会返回0
    .s0_bvalid                         (s0_bvalid                 ),//
    .s0_bready                         (s0_bready                 ) //

);






// output declaration of module dual_ram_template


dual_ram_template #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (40960000                  ) 

    )
u_dual_ram_template(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

//读事务总线
    .r_addr_i                          (s0_araddr                 ),
    .arvalid                           (s0_arvalid                ),
    .arready                           (s0_arready                ),

    .r_data_o                          (s0_rdata                  ),
    .rresp                             (s0_rresp                  ),
    .rvalid                            (s0_rvalid                 ),// output reg rvalid,
    .rready                            (s0_rready                 ),// input 	rready,//master 接收data ready

    .w_addr_i                          (s0_awaddr                 ),
    .awvalid                           (s0_awvalid                ),
    .awready                           (s0_awready                ),
    
    .w_data_i                          (s0_wdata                  ),
    .wmask                             (s0_wstrb                  ),
    .wen                               (s0_wvalid                 ),
    .wready                            (s0_wready                 ),

    .bresp                             (s0_bresp                  ),//未添加
    .bvalid                            (s0_bvalid                 ),//未添加
    .bready                            (s0_bready                 ) //未添加

);



endmodule
