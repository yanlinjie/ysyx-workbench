module IFU( 
    input                               clk                        ,
    input                               rst                        ,

    input                               arready                    ,//arready
    output reg                          read_en                    ,//arvalid
    output reg                          rready                     ,

    input              [  31:0]         next_inst                  ,
    input                               rvalid                     ,
    input              [  31:0]         next_pc                    ,
    input                               id_ready                   ,
    input                               down                       ,
    input                               jump_flag                  ,
    input              [  31:0]         jump_pc                    ,
    input              [  31:0]         imm                        ,

    output reg                          inst_valid                 ,
    output reg         [  31:0]         pc                         ,

    output reg         [  31:0]         inst                        
);


localparam IDLE             = 3'd0;
localparam WAIT_READY       = 3'd1;
localparam BOOT             = 3'd2;//初始复位状态
localparam WAIT_MEM_READY   = 3'd3;


reg                    [   2:0]         state                      ;
reg                    [   2:0]         next_state                 ;

    // 状态更新逻辑
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= BOOT;
    else
        state <= next_state;
end

    // 状态转移判断
always @(*) begin
    case (state)
        BOOT: begin
            inst_valid = 1'b0;   //
            rready = 1'b1;       //master read ready
            read_en = 1'b1;     //valid 
            pc = next_pc;       //addr
            if ( ~arready ) begin
                next_state = WAIT_MEM_READY;
            end else  begin
                next_state = WAIT_READY;
            end 
        end
        IDLE : begin
                rready = 1'b1;
                read_en = 1'b0;  
                inst_valid = 1'b0;          
            if (down) begin  //由于wbu 过来的down只有一个时钟周期，所以设置了一个WAIT_MEM_READY状态
                pc = next_pc;//mem's addr
                if ( ~arready ) begin
                    next_state = WAIT_MEM_READY;
                end else  begin
                    read_en = 1'b1;
                    next_state = WAIT_READY;
                end 
            end else if(jump_flag) begin
                    read_en = 1'b1;
                    pc = jump_pc;
                    next_state = WAIT_READY;
            end else next_state = IDLE;
        end
        WAIT_READY:begin
            rready = 1'b0;
            read_en = 1'b0;//目前读一个时钟周期就够了
            inst_valid = rvalid;//直接把ram的valid传过来
            inst = next_inst;
            if ( ~rvalid) begin //这里就WAIT_MEM_VALID不设置状态了，不知道会不会有隐藏bug 这里通过if语句的优先级来执行
                next_state = WAIT_READY;
            end else if (id_ready) begin next_state = IDLE ;
            end else next_state = WAIT_READY;
        end
        WAIT_MEM_READY:begin
            if (arready) begin//先等mem arready 再arvalid
                next_state = WAIT_READY;
                read_en = 1'b1;
            end else next_state = WAIT_MEM_READY;
        end
        default:
            next_state = IDLE ;
    endcase
end




endmodule
