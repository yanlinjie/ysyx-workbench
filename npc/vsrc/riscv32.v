module riscv32(
    input                               clk                        ,
    input                               rst                        ,
    //读事务涉及IFU和LSU
    //AR master读地址
    output reg         [  31:0]         raddr                      ,//  IFU(pc) or LSU
    output reg                          arvalid                    ,//  IFU or LSU
    input                               arready                    ,

    //R master 读数据
    input              [  31:0]         rdata                      ,// to IFU(inst) or WBU(rd_data)
    // input              [   1:0]         rresp                      ,//未添加
    input                               rvalid                     ,
    output reg                          rready                     ,

    //AW master 写地址 未完善
    output             [  31:0]         awaddr                     ,
    // output                              awvalid                    ,
    // input                               awready                    ,

    //W master 写数据  未完善
    output             [  31:0]         wdata                      ,// LSU
    output             [   3:0]         wstrb                      ,
    output                              wvalid                     ,//  LSU
    input                               wready                     
    
    // // B 写回复
    // input              [   1:0]         bresp                      ,
    // input                               bvalid                     ,
    // output                              bready                      

);
//握手总线信号
wire                                    inst_valid                 ;
wire                                    id_ready                   ;
wire                                    id_valid                   ;

wire                   [  31:0]         pc                         ;
wire                                    read_en                    ;
wire                   [  31:0]         next_inst                  ;



always @(*) begin
    arvalid   = 1'b0;
    if (read_mem_falg) begin
        raddr = (ls_read_mem_addr >>2);
        arvalid   = ls_arvalid;
        rready = ls_rready;
    end else   begin
        raddr = (pc>>2);
        arvalid   = read_en;
        rready = if_rready;
    end
end
reg [31:0] wb_rddata_1;
always @(*) begin
    case(ls_read_mem_addr[1:0])
        2'b00:wb_rddata_1 = rdata;
        2'b01:wb_rddata_1 = {24'b0, rdata[15:8] } ;
        2'b10:wb_rddata_1 = {24'b0, rdata[23:16]} ;   
        2'b11:wb_rddata_1 = {24'b0, rdata[31:24]} ;
        // 2'b10:wb_rddata_1 = rdata[23:16];
        // 2'b11:wb_rddata_1 = rdata[31:24];

    endcase
end

wire [31:0]  wb_rddata;//to wbu
assign next_inst = rvalid? rdata : inst;//
assign wb_rddata = rvalid? wb_rddata_1 : wb_rddata;//忘了进行对读数据拓展！！！我是sb




wire                   [  31:0]         next_pc                    ;
wire                   [  31:0]         inst                       ;


wire if_rready;

// output declaration of module IFU

IFU u_IFU(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .arready                           (arready                   ),
    .read_en                           (read_en                   ),
    .rready(if_rready),
    .rvalid(rvalid),
    .pc                                (pc                        ),
    .next_inst                         (next_inst                 ),


    .next_pc                           (next_pc                   ),
    .id_ready                          (id_ready                  ),
    .down                              (down                      ),
    .jump_pc                           (jump_pc                   ),
    .jump_flag                         (jump_flag                 ),// input jump_flag,
    .imm                               (ex_imm                    ),// input [31:0] imm,
    .inst_valid                        (inst_valid                ),


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

reg_file u_reg_file(
    .rst                               (rst                       ),
    .clk                               (clk                       ),
    .write_reg                         (en                        ),
    .rs1                               (rs1_addr                  ),
    .rs2                               (rs2_addr                  ),
    .target_reg                        (addr                      ),
    .write_rd_data                     (data                      ),

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
    .ex_ready                          (ex_ready                  ) 
);


// output declaration of module LSU
// wire ls_ready;
// wire ls_valid;


// output declaration of module LSU
wire                                    ls_write_reg               ;
wire                   [   4:0]         ls_rd_addr                 ;
wire                   [  31:0]         ls_rd_data                 ;
wire                   [   1:0]         ls_write_mem               ;
wire                   [   2:0]         ls_read_mem                ;
wire                                    ls_write_mem_en            ;
wire                                    ls_arvalid             ;
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

    
    //mem_bus
    .arready                           (arready                   ),
    .rvalid                            (rvalid                    ),
    .rready                            (ls_rready                 ),
    .arvalid                           (ls_arvalid                ),
    .ls_read_mem_addr                  (ls_read_mem_addr          ),

    .read_mem_falg                     (read_mem_falg             ),

    .wready                            (wready                    ),
    .wvalid                            (wvalid                    ),
    .ls_write_mem_addr                 (awaddr                    ),

    .ls_mem_data                       (wdata                     ),
    .wmask                             (wstrb                     ),

    .ex_valid                          (ex_valid                  ),
    .wb_ready                          (wb_ready                  ),
    .ls_ready                          (ls_ready                  ),
    .ls_valid                          (ls_valid                  ) 
);

//rd_data from wb_rddata(from mem)  or alu_out

wire [31:0] rd_reg_data;
reg ls_rd_aluout_mem_1;
//数据打拍
always @(posedge clk ) begin
        ls_rd_aluout_mem_1<=ls_rd_aluout_mem;
end
assign rd_reg_data = ls_rd_aluout_mem_1 ? wb_rddata : ls_rd_data;//判断rd reg data是来自于alu计算结果 还是 from mem 




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
    .rd_data                           (rd_reg_data               ),// input [31:0] rd_data,
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