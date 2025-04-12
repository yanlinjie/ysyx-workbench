module top(
    input                               clk                        ,
    input                               rst                         
);



// output declaration of module riscv32
wire                   [   3:0]         wmask                      ;
// wire wen;
wire                   [  31:0]         waddr                      ;
wire                   [  31:0]         wdata                      ;
// wire ren;
wire                   [  31:0]         raddr                      ;
wire                   [  31:0]         rdata                      ;
wire                                    wready                     ;
wire                   [   1:0]         rresp                      ;
wire                                    awvalid                    ;
wire                                    awready                    ;
wire                   [   1:0]         bresp                      ;
wire                                    bvalid                     ;
wire                                    bready                     ;

riscv32 u_riscv32(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .araddr                            (raddr                     ),
    .arvalid                           (arvalid                   ),//arvalid
    .arready                           (arready                   ),//arready

    .rdata                             (rdata                     ),
    .rresp                             (rresp                     ),//未添加
    .rvalid                            (rvalid                    ),// input                               rvalid                     ,
    .rready                            (rready                    ),//     output                              rready                     ,

    .awaddr                            (waddr                     ),
    .awvalid                           (awvalid                   ),
    .awready                           (awready                   ),//未添加

    .wdata                             (wdata                     ),
    .wstrb                             (wmask                     ),
    .wvalid                            (wen                       ),
    .wready                            (wready                    ),
    
    .bresp                             (bresp                     ),//未添加
    .bvalid                            (bvalid                    ),//未添加
    .bready                            (bready                    ) //未添加



);




// output declaration of module dual_ram_template
wire                                    rready                     ;
wire                                    arready                    ;
wire                                    arvalid                    ;
wire                                    rvalid                     ;


wire                                    wen                        ;


wire                   [  31:0]         w_addr_i                   ;
wire                   [  31:0]         w_data_i                   ;

wire                   [  31:0]         r_addr_i                   ;
wire                   [  31:0]         r_data_o                   ;

dual_ram_template #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    // .MEM_NUM                           (40960000                  ) 
    .MEM_NUM                           (40960000                  ) 

    )
u_dual_ram_template(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

//读事务总线
    .r_addr_i                          (raddr                     ),
    .arvalid                           (arvalid                   ),
    .arready                           (arready                   ),

    .r_data_o                          (rdata                     ),
    .rresp                             (rresp                     ),
    .rvalid                            (rvalid                    ),// output reg rvalid,
    .rready                            (rready                    ),// input 	rready,//master 接收data ready

    .w_addr_i                          (waddr                     ),
    .awvalid                           (awvalid                   ),
    .awready                           (awready                   ),
    
    .w_data_i                          (wdata                     ),
    .wmask                             (wmask                     ),
    .wen                               (wen                       ),
    .wready                            (wready                    ) 

);



endmodule
