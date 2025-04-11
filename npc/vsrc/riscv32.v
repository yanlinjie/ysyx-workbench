module riscv32(
    input                               clk                        ,
    input                               rst                        ,
    //读事务涉及IFU和LSU
//IFU接口
    //AR master读地址
    output wire        [  31:0]         M0_raddr                   ,//  
    output reg                          M0_arvalid                 ,// 
    input                               M0_arready                 ,
    //R master 读数据
    input              [  31:0]         M0_rdata                   ,// to IFU(inst) or WBU(rd_data)
    input              [   1:0]         M0_rresp                   ,//暂时不管读数据
    input                               M0_rvalid                  ,
    output reg                          M0_rready                  ,
    //AW master 写地址 未完善
    output             [  31:0]         M0_awaddr                  ,//给0
    output                              M0_awvalid                 ,//给0
    input                               M0_awready                 ,//
    //W master 写数据  未完善
    output             [  31:0]         M0_wdata                   ,//给0
    output             [   3:0]         M0_wstrb                   ,
    output                              M0_wvalid                  ,//给0
    input                               M0_wready                  ,//
    // // B 写回复
    input              [   1:0]         M0_bresp                   ,//先不管
    input                               M0_bvalid                  ,//先不管
    output                              M0_bready                  ,//先不管

//LSU接口
    //AR master读地址
    output reg         [  31:0]         M1_raddr                   ,//  IFU(pc) or LSU
    output reg                          M1_arvalid                 ,//  IFU or LSU
    input                               M1_arready                 ,
    //R master 读数据
    input              [  31:0]         M1_rdata                   ,// to IFU(inst) or WBU(rd_data)
    input              [   1:0]         M1_rresp                   ,//暂时不管读数据
    input                               M1_rvalid                  ,
    output reg                          M1_rready                  ,
    //AW master 写地址 未完善
    output             [  31:0]         M1_awaddr                  ,
    output                              M1_awvalid                 ,
    input                               M1_awready                 ,
    //W master 写数据  未完善
    output             [  31:0]         M1_wdata                   ,// LSU
    output             [   3:0]         M1_wstrb                   ,
    output                              M1_wvalid                  ,//  LSU
    input                               M1_wready                  ,
    // // B 写回复
    input              [   1:0]         M1_bresp                   ,//先不管
    input                               M1_bvalid                  ,//先不管
    output                              M1_bready                   //先不管
);
//握手总线信号
wire                                    inst_valid                 ;
wire                                    id_ready                   ;
wire                                    id_valid                   ;

wire                   [  31:0]         pc                         ;
wire                                    read_en                    ;
wire                   [  31:0]         next_inst                  ;

wire [4:0] csr_rd_addr;
localparam SRAM_addr_offset = 32'h8000_0000;
//简易仲裁器 后续还需要update 参考讲义总线部分
// always @(*) begin
//     M0_arvalid   = 1'b0;
//     M1_arvalid   = 1'b0;

//     if (read_mem_falg) begin
//         M1_raddr = (ls_read_mem_addr >>2);//读数据 (32'h8000_0000 - 32'h80ff_ffff)
//         M1_arvalid   = ls_arvalid;
//         M1_rready = ls_rready;
//     end else   begin
//         M0_raddr = ((pc - SRAM_addr_offset )>>2);
//         M0_arvalid   = read_en;
//         M0_rready = if_rready;
//     end
// end

// //read 这里做了读数据字节对齐
// reg [31:0] wb_rddata_1;
// reg [7:0] read_one_byte;
// reg [15:0] read_half_word;
// wire [1:0] read_index;
// assign  read_index= ls_read_mem_addr[1:0];
// always @(*) begin
//     case (ls_read_mem[1:0])
//         2'b00: begin //one_byte lb
//                 case(read_index)
//                      2'b00: read_one_byte = rdata[7:0];
//                      2'b01: read_one_byte = rdata[15:8];
//                      2'b10: read_one_byte = rdata[23:16];
//                      2'b11: read_one_byte = rdata[31:24];
//                     default: read_one_byte = 8'b0;
//             endcase
//                     wb_rddata_1 ={ 24'd0 ,read_one_byte};//lb读取一字节后，再给wbu处理，写的有点冗余。
//         end
//         2'b01: begin //one_byte lh
//                 case(read_index)
//                      2'b00: read_half_word = rdata[15:0];
//                      2'b10: read_half_word = rdata[31:16];
//                     default: read_half_word = 16'b0;
//             endcase
//                     wb_rddata_1 ={ 16'd0 ,read_half_word};//lb读取一字节后，再给wbu处理，写的有点冗余。
//         end
//         2'b10: wb_rddata_1 = rdata; 
//         default: begin
//             wb_rddata_1 = rdata;
//         end
//     endcase

// end


// wire [31:0]  wb_rddata;//to wbu
// assign next_inst = rvalid? rdata : inst;//
// assign wb_rddata = rvalid? wb_rddata_1 : wb_rddata;//忘了进行对读数据拓展！！！我是sb




wire                   [  31:0]         next_pc                    ;
wire                   [  31:0]         inst                       ;


wire if_rready;

// output declaration of module IFU
//指令接口 ,只需要read接口即可
IFU u_IFU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .arready                           (M0_arready                ),
    .read_en                           (M0_arvalid                ),
    .rready                            (M0_rready                 ),
    .rvalid                            (M0_rvalid                 ),
    .pc                                (pc                        ),
    .next_inst                         (M0_rdata                  ),


    .next_pc                           (next_pc                   ),
    .id_ready                          (id_ready                  ),
    .down                              (down                      ),
    .jump_pc                           (jump_pc                   ),
    .jump_flag                         (jump_flag                 ),// input jump_flag,
    .imm                               (ex_imm                    ),// input [31:0] imm,
    .inst_valid                        (inst_valid                ),


    .inst                              (inst                      ) 
);

assign M0_raddr = pc;
// assign next_inst = M0_rdata;/



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
    .pc                                (pc                        ),
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
    .reg_csr_rd_addr                   (csr_rd_addr               ),
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
wire ecall_pending;

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
    .pc                                (pc                        ),
    .muxb_ctr                          (alub_rs2_imm_4            ),
    .rs2_data                          (read_rs2_data             ),
    .imm                               (imm_32                    ),
    .ex_rs2_data                       (ex_rs2_data               ),

    .jump_next_pc                      (ex_jump_next_pc           ),
    .ex_valid                          (ex_valid                  ),
    .ex_ready                          (ex_ready                  ),
    .ecall_pending                     (ecall_pending             ),//未使用
    .write_csr_en                      (write_csr_en              ),
    .csr_rd_data                       (csr_rd_data               ),
    .csr_rd_addr                       (csr_rd_addr               ) 
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
wire                                    read_mem_falg              ;

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

    
    //read 接口
    .ls_read_mem_addr                  (M1_raddr                  ),
    .arvalid                           (M1_arvalid                ),
    .arready                           (M1_arready                ),

    .rdata                             (M1_rdata                  ),
    .rvalid                            (M1_rvalid                 ),
    .rready                            (M1_rready                 ),
    
//
    .read_mem_falg                     (read_mem_falg             ),
//write 接口
    .ls_mem_data                       (M1_wdata                  ),
    .wmask                             (M1_wstrb                  ),
    .wready                            (M1_wready                 ),
    .wvalid                            (M1_wvalid                 ),

    .ls_write_mem_addr                 (M1_awaddr                 ),
    .awvalid                           (M1_awvalid                ),
    .awready                           (M1_awready                ),


    .ex_valid                          (ex_valid                  ),
    .wb_ready                          (wb_ready                  ),
    .ls_ready                          (ls_ready                  ),
    .ls_valid                          (ls_valid                  ) 
);

//rd_data from wb_rddata(from mem)  or alu_out

// wire [31:0] rd_reg_data;
// reg ls_rd_aluout_mem_1;
//数据打拍 //放到LSU模块当中
// always @(posedge clk ) begin
//         ls_rd_aluout_mem_1<=ls_rd_aluout_mem;
// end
// assign rd_reg_data = ls_rd_aluout_mem_1 ? wb_rddata : ls_rd_data;//判断rd reg data是来自于alu计算结果 还是 from mem 




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
    .pc                                (pc                        ),
    .next_pc                           (next_pc                   ),
    .wb_ready                          (wb_ready                  ),
    .down                              (down                      ) 
);



endmodule