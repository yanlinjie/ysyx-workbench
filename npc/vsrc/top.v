module top(
    input                               clk                        ,
    input                               rst                         
);

//**************************cpu-core************************//
    //AR master读地址
wire                   [  31:0]         araddr                 ;
wire                                    arvalid                ;
wire                                    arready                ;

    //R master 读数据
wire                   [  31:0]         rdata                  ;
wire                   [   1:0]         rresp                  ;
wire                                    rvalid                 ;
wire                                    rready                 ;

    //AW master 写地址 未完善
wire                   [  31:0]         awaddr                 ;
wire                                    awvalid                ;
wire                                    awready                ;

    //W master 写数据  未完善
wire                   [  31:0]         wdata                  ;
wire                   [   3:0]         wstrb                  ;
wire                                    wvalid                 ;
wire                                    wready                 ;
    
    // // B 写回复
wire                   [   1:0]         bresp                  ;
wire                                    bvalid                 ;
wire                                    bready                 ;

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
//***********************************UART*********************************//    
//AR master读地址
wire                   [  31:0]         s1_araddr                  ;
wire                                    s1_arvalid                 ;
wire                                    s1_arready                 ;
//R master 读数据
wire                   [  31:0]         s1_rdata                   ;
wire                   [   1:0]         s1_rresp                   ;
wire                                    s1_rvalid                  ;
wire                                    s1_rready                  ;
    //AW master 写地址 未完善
wire                   [  31:0]         s1_awaddr                  ;
wire                                    s1_awvalid                 ;
wire                                    s1_awready                 ;
    //W master 写数据  未完善
wire                   [  31:0]         s1_wdata                   ;
wire                   [   3:0]         s1_wstrb                   ;
wire                                    s1_wvalid                  ;
wire                                    s1_wready                  ;
    // // B 写回复
wire                   [   1:0]         s1_bresp                   ;
wire                                    s1_bvalid                  ;
wire                                    s1_bready                  ;
//***********************************CLINT*********************************//    
//AR master读地址
wire                   [  31:0]         s2_araddr                  ;
wire                                    s2_arvalid                 ;
wire                                    s2_arready                 ;
//R master 读数据
wire                   [  31:0]         s2_rdata                   ;
wire                   [   1:0]         s2_rresp                   ;
wire                                    s2_rvalid                  ;
wire                                    s2_rready                  ;
    //AW master 写地址 未完善
wire                   [  31:0]         s2_awaddr                  ;
wire                                    s2_awvalid                 ;
wire                                    s2_awready                 ;
    //W master 写数据  未完善
wire                   [  31:0]         s2_wdata                   ;
wire                   [   3:0]         s2_wstrb                   ;
wire                                    s2_wvalid                  ;
wire                                    s2_wready                  ;
    // // B 写回复
wire                   [   1:0]         s2_bresp                   ;
wire                                    s2_bvalid                  ;
wire                                    s2_bready                  ;


riscv32 u_riscv32(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .araddr                            (araddr                    ),
    .arvalid                           (arvalid                   ),
    .arready                           (arready                   ),

    .rdata                             (rdata                     ),
    .rresp                             (rresp                     ),
    .rvalid                            (rvalid                    ),
    .rready                            (rready                    ),

    .awaddr                            (awaddr                    ),
    .awvalid                           (awvalid                   ),
    .awready                           (awready                   ),

    .wdata                             (wdata                     ),
    .wstrb                             (wstrb                     ),
    .wvalid                            (wvalid                    ),
    .wready                            (wready                    ),
    
    .bresp                             (bresp                     ),
    .bvalid                            (bvalid                    ),
    .bready                            (bready                    ) 
);


Xbar u_Xbar(
    .araddr                        (araddr                ),
    .arvalid                       (arvalid               ),
    .arready                       (arready               ),

    .rdata                         (rdata                 ),
    .rresp                         (rresp                 ),
    .rvalid                        (rvalid                ),
    .rready                        (rready                ),


    .awaddr                        (awaddr                ),
    .awvalid                       (awvalid               ),
    .awready                       (awready               ),

    .wdata                         (wdata                 ),
    .wstrb                         (wstrb                 ),
    .wvalid                        (wvalid                ),
    .wready                        (wready                ),
    
    .bresp                         (bresp                 ),
    .bvalid                        (bvalid                ),
    .bready                        (bready                ),

//***********************************RAM*********************************//    
    //AR master读地址
    .s0_araddr                         (s0_araddr                 ),
    .s0_arvalid                        (s0_arvalid                ),
    .s0_arready                        (s0_arready                ),

    //R master 读数据
    .s0_rdata                          (s0_rdata                  ),
    .s0_rresp                          (s0_rresp                  ),
    .s0_rvalid                         (s0_rvalid                 ),
    .s0_rready                         (s0_rready                 ),

    //AW master 写地址 未完善
    .s0_awaddr                         (s0_awaddr                 ),
    .s0_awvalid                        (s0_awvalid                ),
    .s0_awready                        (s0_awready                ),

    //W master 写数据  未完善
    .s0_wdata                          (s0_wdata                  ),
    .s0_wstrb                          (s0_wstrb                  ),
    .s0_wvalid                         (s0_wvalid                 ),
    .s0_wready                         (s0_wready                 ),
    
    // // B 写回复
    .s0_bresp                          (s0_bresp                  ),
    .s0_bvalid                         (s0_bvalid                 ),
    .s0_bready                         (s0_bready                 ),
//***********************************UART*********************************//    
    .s1_araddr                         (s1_araddr                 ),
    .s1_arvalid                        (s1_arvalid                ),
    .s1_arready                        (s1_arready                ),

    .s1_rdata                          (s1_rdata                  ),
    .s1_rresp                          (s1_rresp                  ),
    .s1_rvalid                         (s1_rvalid                 ),
    .s1_rready                         (s1_rready                 ),

    .s1_awaddr                         (s1_awaddr                 ),
    .s1_awvalid                        (s1_awvalid                ),
    .s1_awready                        (s1_awready                ),

    .s1_wdata                          (s1_wdata                  ),
    .s1_wstrb                          (s1_wstrb                  ),
    .s1_wvalid                         (s1_wvalid                 ),
    .s1_wready                         (s1_wready                 ),

    .s1_bresp                          (s1_bresp                  ),
    .s1_bvalid                         (s1_bvalid                 ),
    .s1_bready                         (s1_bready                 ) 
);






// output declaration of module dual_ram_template


dual_ram_template #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (32'h100_0000              ) 

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
    .rvalid                            (s0_rvalid                 ),
    .rready                            (s0_rready                 ),

    .w_addr_i                          (s0_awaddr                 ),
    .awvalid                           (s0_awvalid                ),
    .awready                           (s0_awready                ),
    
    .w_data_i                          (s0_wdata                  ),
    .wmask                             (s0_wstrb                  ),
    .wen                               (s0_wvalid                 ),
    .wready                            (s0_wready                 ),

    .bresp                             (s0_bresp                  ),
    .bvalid                            (s0_bvalid                 ),
    .bready                            (s0_bready                 ) 

);

uart_slave #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (32'h1000                  ) 

    )
u_uart_slave(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .araddr                            (s1_araddr                 ),
    .arvalid                           (s1_arvalid                ),
    .arready                           (s1_arready                ),

    .rdata                             (s1_rdata                  ),
    .rresp                             (s1_rresp                  ),
    .rvalid                            (s1_rvalid                 ),
    .rready                            (s1_rready                 ),

    .awaddr                            (s1_awaddr                 ),
    .awvalid                           (s1_awvalid                ),
    .awready                           (s1_awready                ),
    
    .wdata                             (s1_wdata                  ),
    .wstrb                             (s1_wstrb                  ),
    .wvalid                            (s1_wvalid                 ),
    .wready                            (s1_wready                 ),

    .bresp                             (s1_bresp                  ),
    .bvalid                            (s1_bvalid                 ),
    .bready                            (s1_bready                 ) 
);

// clint_slave #(
//     .DW                                (32                        ),
//     .AW                                (32                        ),
//     .MEM_NUM                           (32'h1_0000                  ) 

//     )
// u_clint_slave(
//     .clk                               (clk                       ),
//     .rst                               (rst                       ),

//     .araddr                            (s2_araddr                 ),
//     .arvalid                           (s2_arvalid                ),
//     .arready                           (s2_arready                ),

//     .rdata                             (s2_rdata                  ),
//     .rresp                             (s2_rresp                  ),
//     .rvalid                            (s2_rvalid                 ),
//     .rready                            (s2_rready                 ),

//     .awaddr                            (s2_awaddr                 ),
//     .awvalid                           (s2_awvalid                ),
//     .awready                           (s2_awready                ),
    
//     .wdata                             (s2_wdata                  ),
//     .wstrb                             (s2_wstrb                  ),
//     .wvalid                            (s2_wvalid                 ),
//     .wready                            (s2_wready                 ),

//     .bresp                             (s2_bresp                  ),
//     .bvalid                            (s2_bvalid                 ),
//     .bready                            (s2_bready                 ) 
// );

endmodule
