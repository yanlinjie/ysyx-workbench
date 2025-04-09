module WBU(
    input clk,
    input rst,

//jump
    input [1:0] jump,
    input [31:0] jump_next_pc,

    input rd_en,
    input [4:0] rd_addr,
    input [31:0] rd_data,

    input [2:0] read_mem,//由译码模块->EXU-LSU 过来的控制信号 控制读从mem中读到的数据是的字节数

    output reg en,//reg en
    output reg [4:0] addr,//reg addr rd_addr
    output reg [31:0] data,//rd_data

    input ls_valid,//bus
    input [31:0] pc,

    output reg [31:0] next_pc,
    output reg wb_ready,
    output reg down

);


// 状态编码
reg [1:0] state;
reg [1:0] next_state;

localparam IDLE        = 2'b0;//等待上游模块的 valid信号
localparam WAIT_READY = 2'b1;//等待下游模块 ready信号

// 状态寄存器
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

// 状态转移 + 输出逻辑
always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            wb_ready = 1'b1;
            down = 1'b0;
            if (ls_valid)
            begin
                next_state = WAIT_READY;//发送down
                // down = 1'b1;                
            end
        end

        WAIT_READY: begin
            down = 1;
            wb_ready = 1'b0;
                next_state = IDLE;//不过这里应该得等直接执行完 ,也就是说执行完wbu？
        end

        default: next_state = IDLE;
    endcase
end
// next_pc 更新
always @(posedge clk or posedge rst) begin
    if (rst)begin
        next_pc <= 32'h80000000;            
    end
    else if (state == IDLE && ls_valid)
    begin
        if (jump[0]||jump[1]) begin
            next_pc <= jump_next_pc;
        end else next_pc <= pc + 4;//执行完一条指令后指令 + 4

    end    
end

reg  wb_start;

always @(posedge clk) begin
        wb_start = (state == IDLE && ls_valid);
end

always @(*) begin
    if (wb_start) begin
        case (read_mem[1:0])//用两位即可,最高位用于表示 读出的数据 是符号拓展还是0拓展 读到的数据放到wbu中再处理吧
            2'b00:begin
                if(read_mem[2])  data = {24'b0,rd_data[7:0]}; 
                else data = {{24{rd_data[7]}},rd_data[7:0]};
            end    
            2'b01:begin
                if(read_mem[2])  data = {16'b0,rd_data[15:0]}; 
                else data = {{16{rd_data[15]}},rd_data[15:0]};
            
            end  
            2'b10:  data = rd_data;
            default: begin
                    data = rd_data;
            end
        endcase
        // data <= rd_data;
        addr = rd_addr;
        en   = rd_en;
    end
end

endmodule