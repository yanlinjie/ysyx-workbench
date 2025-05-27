////nothing1111
module ysyx_25020033
(
    input                               clock                      ,
    input                               reset                      ,

    input                               io_interrupt               ,
//写地址通道
    input                               io_master_awready          ,
    output                              io_master_awvalid          ,
    output             [  31:0]         io_master_awaddr           ,
    output reg         [   3:0]         io_master_awid             ,//写事务 ID
    output reg         [   7:0]         io_master_awlen            ,//突发（burst）长度 awlen = 0 → 只传 1 个数据 awlen = 3 → 传输 4 个数据
    output reg         [   2:0]         io_master_awsize           ,//表示每次数据传输的 宽度 是多少个字节 000:1byte ; 001:2byte ; 010:4byte .... 
    output reg         [   1:0]         io_master_awburst          ,//突发传输类型
//写数据
    input                               io_master_wready           ,
    output                              io_master_wvalid           ,
    output             [  31:0]         io_master_wdata            ,
    output             [   3:0]         io_master_wstrb            ,
    output                              io_master_wlast            ,//标记写数据通道中一组 burst 的最后一拍
//写响应
    output                              io_master_bready           ,
    input                               io_master_bvalid           ,
    input              [   1:0]         io_master_bresp            ,
    input              [   3:0]         io_master_bid              ,
//读地址
    input                               io_master_arready          ,
    output reg                          io_master_arvalid          ,
    output reg         [  31:0]         io_master_araddr           ,
    output reg         [   3:0]         io_master_arid             ,
    output reg         [   7:0]         io_master_arlen            ,
    output reg         [   2:0]         io_master_arsize           ,
    output reg         [   1:0]         io_master_arburst          ,
//读数据
    output reg                          io_master_rready           ,
    input                               io_master_rvalid           ,
    input              [   1:0]         io_master_rresp            ,
    input              [  31:0]         io_master_rdata            ,
    input                               io_master_rlast            ,
    input              [   3:0]         io_master_rid              ,
//下面的接口目前不使用！
    output                              io_slave_awready           ,
    input                               io_slave_awvalid           ,
    input              [  31:0]         io_slave_awaddr            ,
    input              [   3:0]         io_slave_awid              ,
    input              [   7:0]         io_slave_awlen             ,
    input              [   2:0]         io_slave_awsize            ,
    input              [   1:0]         io_slave_awburst           ,
    output                              io_slave_wready            ,
    input                               io_slave_wvalid            ,
    input              [  31:0]         io_slave_wdata             ,
    input              [   3:0]         io_slave_wstrb             ,
    input                               io_slave_wlast             ,
    input                               io_slave_bready            ,
    output                              io_slave_bvalid            ,
    output             [   1:0]         io_slave_bresp             ,
    output             [   3:0]         io_slave_bid               ,
    output                              io_slave_arready           ,
    input                               io_slave_arvalid           ,
    input              [  31:0]         io_slave_araddr            ,
    input              [   3:0]         io_slave_arid              ,
    input              [   7:0]         io_slave_arlen             ,
    input              [   2:0]         io_slave_arsize            ,
    input              [   1:0]         io_slave_arburst           ,
    input                               io_slave_rready            ,
    output                              io_slave_rvalid            ,
    output             [   1:0]         io_slave_rresp             ,
    output             [  31:0]         io_slave_rdata             ,
    output                              io_slave_rlast             ,
    output             [   3:0]         io_slave_rid                

    // //AR master读地址
    // output reg         [  31:0]         araddr                     ,
    // output reg                          arvalid                    ,
    // input                               arready                    ,

    // //R master 读数据
    // input              [  31:0]         rdata                      ,
    // input              [   1:0]         rresp                      ,
    // input                               rvalid                     ,
    // output reg                          rready                     ,

    // //AW master 写地址 未完善
    // output             [  31:0]         awaddr                     ,
    // output                              awvalid                    ,
    // input                               awready                    ,

    // //W master 写数据  未完善
    // output             [  31:0]         wdata                      ,
    // output             [   3:0]         wstrb                      ,
    // output                              wvalid                     ,
    // input                               wready                     ,
    
    // // // B 写回复
    // input              [   1:0]         bresp                      ,
    // input                               bvalid                     ,
    // output                              bready                      
);
wire clk;
wire rst;

assign clk = clock;
assign rst = reset;

//握手总线信号
wire                                    inst_valid                 ;
wire                                    id_ready                   ;
wire                                    id_valid                   ;

wire                   [  31:0]         latter_pc                  ;


wire                   [   4:0]         csr_rd_addr                ;

wire                   [  31:0]         next_pc                    ;
wire                   [  31:0]         inst                       ;
//**************************BUS************************//
    //AR master读地址
wire                   [  31:0]         ifu_araddr                 ;
wire                                    ifu_arvalid                ;
reg                                     ifu_arready                ;

    //R master 读数据
reg                    [  31:0]         ifu_rdata                  ;
wire                   [   1:0]         ifu_rresp                  ;
reg                                     ifu_rvalid                 ;
wire                                    ifu_rready                 ;

    //AR master读地址
wire                   [  31:0]         lsu_araddr                 ;
wire                                    lsu_arvalid                ;
reg                                     lsu_arready                ;

    //R master 读数据
reg                    [  31:0]         lsu_rdata                  ;
wire                   [   1:0]         lsu_rresp                  ;
reg                                     lsu_rvalid                 ;
wire                                    lsu_rready                 ;
//***********************************CLINT*********************************//    
//AR master读地址
reg                   [  31:0]         s2_araddr                  ;
reg                                    s2_arvalid                 ;
wire                                    s2_arready                 ;
//R master 读数据
wire                   [  31:0]         s2_rdata                   ;
wire                   [   1:0]         s2_rresp                   ;
wire                                    s2_rvalid                  ;
reg                                    s2_rready                  ;
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



//读-master: IFU/LSU
always @(*) begin
        io_master_arvalid  = 1'b0;
        io_master_rready = 1'b0;
        lsu_rvalid = 1'b0;
    if (lsu_arvalid | lsu_rready) begin
        if (lsu_araddr == 32'ha000_0048 | lsu_araddr == 32'ha000_004c) begin
            s2_araddr = lsu_araddr ;
            s2_arvalid   = lsu_arvalid;
            lsu_arready = s2_arready;

            lsu_rdata = s2_rdata;                                       
            lsu_rvalid = s2_rvalid;                                    
            s2_rready = lsu_rready; 
        end else  if (lsu_araddr == 32'h10000000 | lsu_araddr == 32'h10000001 | lsu_araddr == 32'h10000002 |lsu_araddr == 32'h10000003 |lsu_araddr == 32'h10000004 |lsu_araddr == 32'h10000005 |lsu_araddr == 32'h10000006 |lsu_araddr == 32'h10000007) begin
                io_master_araddr = lsu_araddr ;
                io_master_arvalid   = lsu_arvalid;
                lsu_arready = io_master_arready;

                io_master_arid = 0;
                io_master_arlen = 0;
                io_master_arsize = 3'b000;
                io_master_arburst = 2'b11;

                lsu_rdata = io_master_rdata;                                       
                lsu_rvalid = io_master_rvalid;                                    
                io_master_rready = lsu_rready;  
        end else 
        begin
                io_master_araddr = lsu_araddr ;
                io_master_arvalid   = lsu_arvalid;
                lsu_arready = io_master_arready;

                io_master_arid = 0;
                io_master_arlen = 0;
                io_master_arsize = 3'b010;
                io_master_arburst = 2'b11;

                lsu_rdata = io_master_rdata;                                       
                lsu_rvalid = io_master_rvalid;                                    
                io_master_rready = lsu_rready;  
        end
                                   
    end else if(ifu_arvalid | ifu_rready) begin
        io_master_araddr = ifu_araddr;
        io_master_arvalid   = ifu_arvalid;
        ifu_arready = io_master_arready;
        io_master_arid = 0;
        io_master_arlen = 0;
        io_master_arsize = 3'b010;
        io_master_arburst = 2'b11;

        ifu_rdata = io_master_rdata;
        ifu_rvalid = io_master_rvalid;
        io_master_rready = ifu_rready;
    end
end

always @(*) begin
        io_master_awid   = 0;   
        io_master_awlen     = 0;
        io_master_awsize    = 3'b010;
        io_master_awburst   =2'b11;
    if (io_master_awaddr == 32'h10000000 | io_master_awaddr == 32'h10000001 | io_master_awaddr == 32'h10000002 |io_master_awaddr == 32'h10000003 |io_master_awaddr == 32'h10000004 |io_master_awaddr == 32'h10000005 |io_master_awaddr == 32'h10000006 |io_master_awaddr == 32'h10000007) begin
        io_master_awid   = 0;   
        io_master_awlen     = 0;
        io_master_awsize    = 3'b000;
        io_master_awburst   =2'b11;
    end
end


clint_slave #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (32'h1_0000                  ) 

    )
u_clint_slave(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .araddr                            (s2_araddr                 ),
    .arvalid                           (s2_arvalid                ),
    .arready                           (s2_arready                ),

    .rdata                             (s2_rdata                  ),
    .rresp                             (s2_rresp                  ),
    .rvalid                            (s2_rvalid                 ),
    .rready                            (s2_rready                 )

    // .awaddr                            (s2_awaddr                 ),
    // .awvalid                           (s2_awvalid                ),
    // .awready                           (s2_awready                ),
    
    // .wdata                             (s2_wdata                  ),
    // .wstrb                             (s2_wstrb                  ),
    // .wvalid                            (s2_wvalid                 ),
    // .wready                            (s2_wready                 ),

    // .bresp                             (s2_bresp                  ),
    // .bvalid                            (s2_bvalid                 ),
    // .bready                            (s2_bready                 ) 
);

IFU u_IFU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .pc                                (ifu_araddr                ),
    .read_en                           (ifu_arvalid               ),
    .arready                           (ifu_arready               ),

    .next_inst                         (ifu_rdata                 ),

    .rvalid                            (ifu_rvalid                ),
    .rready                            (ifu_rready                ),


    .next_pc                           (next_pc                   ),
    .id_ready                          (id_ready                  ),
    .down                              (down                      ),
    .jump_pc                           (jump_pc                   ),
    .jump_flag                         (jump_flag                 ),// input jump_flag,
    .imm                               (ex_imm                    ),// input [31:0] imm,
    .inst_valid                        (inst_valid                ),

    .latter_pc                         (latter_pc                 ),
    .inst                              (inst                      ) 
);





// output declaration of module IDU
wire                                    write_reg                  ;
wire                                    rd_aluout_mem              ;
wire                   [   1:0]         alua_rs1_pc_zero           ;
wire                   [   1:0]         alub_rs2_imm_4             ;
wire                   [   4:0]         alu_ctr                    ;
wire                   [  31:0]         imm_32                     ;
wire                                    write_mem_en               ;
wire                   [   1:0]         write_mem                  ;
wire                                    read_mem_en                ;
wire                   [   2:0]         read_mem                   ;
wire                                    next_pcimm_rs1imm          ;
wire                   [   4:0]         rs1_addr                   ;
wire                   [   4:0]         rs2_addr                   ;
wire                   [   4:0]         rd_addr                    ;
wire                   [   1:0]         jump                       ;

IDU u_IDU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),
    .pc                                (latter_pc                 ),
    .instruction                       (inst                      ),

    .pc_valid                          (inst_valid                ),
    .ex_ready                          (ex_ready                  ),

    .id_ready                          (id_ready                  ),
    .id_valid                          (id_valid                  ),

    .write_reg                         (write_reg                 ),
    .rd_aluout_mem                     (rd_aluout_mem             ),
    .alua_rs1_pc_zero                  (alua_rs1_pc_zero          ),
    .alub_rs2_imm_4                    (alub_rs2_imm_4            ),
    .alu_ctr                           (alu_ctr                   ),
    .imm_32                            (imm_32                    ),
    .write_mem_en                      (write_mem_en              ),
    .write_mem                         (write_mem                 ),
    .read_mem_en                       (read_mem_en               ),
    .read_mem                          (read_mem                  ),
    .next_pcimm_rs1imm                 (next_pcimm_rs1imm         ),
    .out_rddata_memaddr                (out_rddata_memaddr        ),
    .jump                              (jump                      ),
    .rs1_addr                          (rs1_addr                  ),
    .rs2_addr                          (rs2_addr                  ),
    .rd_addr                           (rd_addr                   ) 
);




// output declaration of module reg_file
wire [31:0] read_rs1_data;
wire [31:0] read_rs2_data;
wire write_csr_en;
wire [31:0] csr_rd_data;
reg_file u_reg_file(
    .rst                               (rst                       ),
    .clk                               (clk                       ),
    .write_reg                         (en                        ),
    .rs1                               (rs1_addr                  ),
    .rs2                               (rs2_addr                  ),
    .target_reg                        (addr                      ),
    .write_rd_data                     (data                      ),
    .reg_csr_rd_addr(csr_rd_addr),
    .csr_data                          (csr_rd_data               ),
    .write_csr_en                      (write_csr_en              ),

    .read_rs1_data                     (read_rs1_data             ),
    .read_rs2_data                     (read_rs2_data             ) 
);



// output declaration of module EXU
wire                   [  31:0]         out                        ;
wire                                    jump_flag                  ;
wire                                    ex_valid                   ;
wire                                    ex_ready                   ;
wire                                    ls_ready                   ;

wire                                    out_rddata_memaddr         ;//用来判断alu_out是 写入rd中，还是mem中

wire                                    ex_write_mem_en            ;
wire                                    ex_read_mem_en             ;
wire                   [   1:0]         ex_write_mem               ;
wire                   [   2:0]         ex_read_mem                ;
wire                                    ex_write_reg               ;
wire                   [   4:0]         ex_rd_addr                 ;
wire                                    ex_rd_aluout_mem           ;
wire                   [  31:0]         ex_imm                     ;
wire                   [  31:0]         jump_pc                    ;
wire                   [  31:0]         ex_jump_next_pc            ;
wire                   [   1:0]         ex_jump                    ;
wire                   [  31:0]         ex_rs2_data                ;
// wire ecall_pending;

EXU u_EXU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .jump                              (jump                      ),
    .ex_jump                           (ex_jump                   ),
    .write_mem_en                      (write_mem_en              ),
    .read_mem_en                       (read_mem_en               ),
    .write_mem                         (write_mem                 ),//     input [1:0] write_mem,
    .read_mem                          (read_mem                  ),// input [2:0] read_mem,
    .write_reg                         (write_reg                 ),// input write_reg,
    .rd_addr                           (rd_addr                   ),// input rd_addr,
    .rd_aluout_mem                     (rd_aluout_mem             ),// input rd_aluout_mem,//待会儿补充指令再使用 ，目前不使用
    .out_rddata_memaddr                (out_rddata_memaddr        ),// input out_rddata_memaddr,//用来判断alu_out是 写入rd中，还是mem中

    .ex_write_mem_en                   (ex_write_mem_en           ),// output ex_write_mem_en,
    .ex_read_mem_en                    (ex_read_mem_en            ),// output ex_read_mem_en,
    .ex_write_mem                      (ex_write_mem              ),// output [1:0] ex_write_mem,
    .ex_read_mem                       (ex_read_mem               ),// output [2:0] ex_read_mem,
    .ex_write_reg                      (ex_write_reg              ),// output ex_write_reg,
    .ex_rd_addr                        (ex_rd_addr                ),// output ex_rd_addr,
    .ex_rd_aluout_mem                  (ex_rd_aluout_mem          ),

    .jump_pc                           (jump_pc                   ),
    .instruction                       (inst                      ),
    .id_valid                          (id_valid                  ),
    .ls_ready                          (ls_ready                  ),
    .alu_ctr                           (alu_ctr                   ),

    .out_rd                            (out_rd                    ),//   output [31:0] out_rd,// alu的计算结果 
    .out_mem_addr                      (out_mem_addr              ),//     output [31:0] out_mem_addr,//计算结果输出给mem_addr 作为地址

    .jump_flag                         (jump_flag                 ),

    .muxa_ctr                          (alua_rs1_pc_zero          ),
    .rs1_data                          (read_rs1_data             ),
    .pc                                (latter_pc                 ),
    .muxb_ctr                          (alub_rs2_imm_4            ),
    .rs2_data                          (read_rs2_data             ),
    .imm                               (imm_32                    ),
    .ex_rs2_data                       (ex_rs2_data               ),

    .jump_next_pc                      (ex_jump_next_pc           ),
    .ex_valid                          (ex_valid                  ),
    .ex_ready                          (ex_ready                  ),
    .write_csr_en                      (write_csr_en              ),
    .csr_rd_data                       (csr_rd_data               ),
    .csr_rd_addr(csr_rd_addr)
);



// output declaration of module LSU
wire                                    ls_write_reg               ;
wire                   [   4:0]         ls_rd_addr                 ;
wire                   [  31:0]         ls_rd_data                 ;
wire                   [   1:0]         ls_write_mem               ;
wire                   [   2:0]         ls_read_mem                ;
wire                                    ls_write_mem_en            ;
wire                                    ls_arvalid                 ;
wire                   [  31:0]         ls_mem_addr                ;


wire                                    ls_valid                   ;
wire                   [  31:0]         out_rd                     ;
wire                   [  31:0]         out_mem_addr               ;
wire                                    ls_rd_aluout_mem           ;
wire                   [  31:0]         ls_imm                     ;
wire                   [   1:0]         ls_jump                    ;
wire                   [  31:0]         ls_jump_next_pc            ;
wire                   [  31:0]         ls_read_mem_addr           ;
wire                   [  31:0]         ls_write_mem_addr          ;
wire                                    ls_rready                  ;


LSU u_LSU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),
    
    .jump                              (ex_jump                   ),//     input [1:0] jump,
    .ls_jump                           (ls_jump                   ),
    .jump_next_pc                      (ex_jump_next_pc           ),
    .ls_jump_next_pc                   (ls_jump_next_pc           ),// output reg [31:0] jump_next_pc,
    .rs2_data                          (ex_rs2_data               ),

    .write_mem_en                      (ex_write_mem_en           ),
    .read_mem_en                       (ex_read_mem_en            ),
    .write_mem                         (write_mem                 ),
    .read_mem                          (read_mem                  ),
    .write_reg                         (write_reg                 ),
    .rd_addr                           (rd_addr                   ),

    .rd_aluout_mem                     (ex_rd_aluout_mem          ),
    .rd_data                           (out_rd                    ),
    .mem_addr                          (out_mem_addr              ),

    .ls_write_reg                      (ls_write_reg              ),//rd_en
    .ls_rd_addr                        (ls_rd_addr                ),//rd_addr
    .ls_rd_data                        (ls_rd_data                ),//rd_data
    .ls_write_mem                      (ls_write_mem              ),
    .ls_read_mem                       (ls_read_mem               ),
    .ls_rd_aluout_mem                  (ls_rd_aluout_mem          ),

    
    //mem_bus

    .ls_read_mem_addr                  (lsu_araddr          ),
    .arvalid                           (lsu_arvalid               ),
    .arready                           (lsu_arready               ),

    .rdata                             (lsu_rdata                 ),
    //lsu_rresp (未加入)
    .rvalid                            (lsu_rvalid                ),
    .rready                            (lsu_rready                ),

    .ls_write_mem_addr                 (io_master_awaddr                    ),
    .awvalid                           (io_master_awvalid                   ),
    .awready                           (io_master_awready                   ),

    .ls_mem_data                       (io_master_wdata                     ),
    .wmask                             (io_master_wstrb                     ),
    .wvalid                            (io_master_wvalid                    ),
    .wready                            (io_master_wready                    ),

    .bresp                             (io_master_bresp                     ),//未添加
    .bvalid                            (io_master_bvalid                    ),//未添加
    .bready                            (io_master_bready                    ),//未添加

    .ex_valid                          (ex_valid                  ),
    .wb_ready                          (wb_ready                  ),
    .ls_ready                          (ls_ready                  ),
    .ls_valid                          (ls_valid                  ) 
);




// output declaration of module WBU
wire                                    wb_ready                   ;
wire                                    down                       ;
wire                   [  31:0]         data                       ;
wire                   [   4:0]         addr                       ;
wire                                    en                         ;

WBU u_WBU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .jump                              (ls_jump                   ),
    .jump_next_pc                      (ls_jump_next_pc           ),

    .rd_en                             (ls_write_reg              ),// input rd_en,
    .rd_addr                           (ls_rd_addr                ),// input [4:0] rd_addr,
    .rd_data                           (ls_rd_data                ),// input [31:0] rd_data,
    .read_mem                          (ls_read_mem               ),

    .en                                (en                        ),// output reg en,
    .addr                              (addr                      ),// output reg [4:0] addr,
    .data                              (data                      ),// output reg [31:0] data,


    .ls_valid                          (ls_valid                  ),
    .pc                                (latter_pc                 ),
    .next_pc                           (next_pc                   ),
    .wb_ready                          (wb_ready                  ),
    .down                              (down                      ) 
);



endmodule