module top(
    input clk,
    input rst
);



// output declaration of module riscv32
wire [3:0] wmask;
// wire wen;
wire [31:0] waddr;
wire [31:0] wdata;
// wire ren;
wire [31:0] raddr;
wire [31:0] rdata;
wire wready;
riscv32 u_riscv32(
    .clk                               (clk                       ),
    .rst                               (rst                       ),

    .wready                            (wready                    ),
    .wstrb                             (wmask                     ),
    .wvalid                            (wen                       ),
    .awaddr                            (waddr                     ),
    .wdata                             (wdata                     ),


//读事务bus
    .rready                            (rready                    ),//     output                              rready                     ,
    .rvalid                            (rvalid                    ),// input                               rvalid                     ,
    .arvalid                           (arvalid                   ),//arvalid
    .arready                           (arready                   ),//arready
    .raddr                             (raddr                     ),
    .rdata                             (rdata                     ) 
);




// output declaration of module dual_ram_template
wire rready ;
wire arready ;
wire arvalid;
wire rvalid;


wire wen;


wire [31:0] w_addr_i;
wire [31:0] w_data_i;

wire [31:0] r_addr_i;
wire [31:0] r_data_o;

dual_ram_template #(
    .DW                                (32                        ),
    .AW                                (32                        ),
    .MEM_NUM                           (65536                      ) 
    )
u_dual_ram_template(
    .clk                               (clk                       ),
    .rst                               (rst                      ),

//读事务总线
    .arvalid                           (arvalid                       ),
    .arready                           (arready                   ),
    .rready                            (rready                      ),// input 	rready,//master 接收data ready
    .rvalid                            (rvalid                    ),// output reg rvalid,

    .wready(wready),
    .wen                               (wen                       ),
    .w_addr_i                          (waddr                     ),
    .w_data_i                          (wdata                     ),

    .r_addr_i                          (raddr                     ),
    .wmask                             (wmask                     ),
    .r_data_o                          (rdata                     ) 
);



endmodule
