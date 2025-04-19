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
    output reg         [  31:0]         pc                         ,//取指令pc
    output reg         [  31:0]         latter_pc                  ,//取指令后的pc 延迟一个时钟周期  这个输出pc 和 inst 一起输出

    output reg         [  31:0]         inst                        
);


localparam IDLE             = 3'd0;
localparam WAIT_READY       = 3'd1;
localparam BOOT             = 3'd2;//初始复位状态
localparam WAIT_MEM_READY   = 3'd3;
localparam RST   = 3'd4;



reg                    [   2:0]         state                      ;
reg                    [   2:0]         next_state                 ;

    // 状态更新逻辑
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= RST;
    else
        state <= next_state;
end

    // 状态转移判断
always @(*) begin
    case (state)
        RST:begin
            pc = next_pc;       //addr
            inst_valid = 1'b0;   //
            read_en = 1'b0;     //valid 
            next_state = BOOT;
            
        end
        BOOT: begin
            inst_valid = 1'b0;   //
            rready = 1'b1;       //master read ready
            read_en = 1'b1;     //valid 
            pc = next_pc;       //addr
            next_state = WAIT_READY;
            if(~arready) //如果slave 没有准备好 则等待slave准备
                next_state = WAIT_MEM_READY;
        end
        IDLE : begin
                rready = 1'b0;
                inst_valid = 1'b0;          
            if (down) begin  //由于wbu 过来的down只有一个时钟周期，所以设置了一个WAIT_MEM_READY状态
                pc = next_pc;//mem's addr   
                read_en = 1'b1;//同时拉高valid 和接收ready
                rready = 1'b1;
                if(~arready) //如果slave 没有准备好 则等待slave准备
                    next_state = WAIT_MEM_READY;
                    else  next_state = WAIT_READY;              
            end else if(jump_flag) begin
                    read_en = 1'b1;
                    rready = 1'b1;
                    pc = jump_pc;
                    if(~arready) //如果slave 没有准备好 则等待slave准备
                        next_state = WAIT_MEM_READY;
                    else next_state = WAIT_READY;
            end else next_state = IDLE;
        end
        WAIT_READY:begin
                    rready = 1'b1;
                    read_en = 1'b0;
                    inst_valid = rvalid;//直接把ram的valid传过来
                if(rvalid)begin
                    inst = next_inst;
                    latter_pc = pc ; //inst 和 pc同步
                    if (id_ready) begin next_state = IDLE ; //握手成功后在下一状态拉低
                    end else next_state = WAIT_READY;
                end else begin 
                    next_state = WAIT_READY;
                end 
        end
        WAIT_MEM_READY:begin //地址握手，先valid 再检测slave 的ready 
            if (~arready) begin
                next_state = WAIT_MEM_READY;
            end else  begin
                    rready = 1'b1;
                    // read_en = 1'b0;
                    next_state = WAIT_READY;
                    // inst_valid = rvalid;//直接把ram的valid传过来
                    // latter_pc = pc ;
                // if(rvalid)begin
                //     inst = next_inst;
                //     if (id_ready) begin next_state = IDLE ; //握手成功后在下一状态拉低
                //     end else next_state = WAIT_READY;
                // end else begin 
                //     next_state = WAIT_READY;
                // end 
            end  

        end
        default:
            next_state = IDLE ;
    endcase
end




endmodule
