//目前mem 和cpu之间还没使用握手 读内存还会延迟一个时钟周期！ LSU的这个时钟周期用于读mem 下一个时钟周期数据就会出来
module LSU(
        input clk,
        input rst,

        input [1:0] jump,
        input [31:0]jump_next_pc,
        output reg [1:0] ls_jump,
        output reg [31:0] ls_jump_next_pc,

        //from ex
        // input  write_csr_en ,
        // input  [31:0] csr_rd_data ,
        input [31:0] rs2_data,//用于存储
        input write_mem_en,
        input read_mem_en,
        input [1:0] write_mem,
        input [2:0] read_mem,//用于判读读字节的数，以及数据是0拓展还是符号拓展
        input write_reg,//rd en
        input [4:0] rd_addr,//from ex , id
        input [31:0] rd_data,//from alu_out
        input [31:0] mem_addr,//访存地址 from alu_out
        input rd_aluout_mem,
        //to wb
        output reg ls_write_reg,
        output reg [4:0]  ls_rd_addr,
        output reg [31:0]  ls_rd_data,
        output reg [1:0] ls_write_mem,
        output reg [2:0] ls_read_mem,
        output reg ls_rd_aluout_mem,
        // output reg [31:0] ls_imm,

        //to mem
        // mem_read_bus
        input arready,//mem addr ready
        output reg arvalid,//arvalid
        output reg rready,
        input rvalid,

        output reg read_mem_falg,

        //mem_write_bus
        input wready,
        output reg wvalid,



        output reg [31:0] ls_mem_data,
        output reg [31:0] ls_read_mem_addr,
        output reg [31:0] ls_write_mem_addr,
        output reg [3:0] wmask,//4 bit 可以展开表示 32位 用于掩码 1111

        //bus
        input ex_valid,
        input wb_ready,

        output reg ls_ready,
        output reg ls_valid

        // output reg ls_write_csr_en ,
        // output reg [31:0] ls_csr_rd_data 
);

// 状态定义
localparam IDLE        = 2'b00;//等待上游模块的 valid信号
localparam WAIT_READY = 2'b01;//等待下游模块 ready信号
localparam WAIT_MEM_READY   = 2'b10;
localparam WAIT_MEM_WRITE_READY   = 2'b11;
reg [1:0] state, next_state;
reg [31:0] mem_addr_index;
reg [31:0] mem_data_index;
wire  [7:0] one_byte;
wire [15:0] half_word;
reg [15:0] one_word;

// 状态转移
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end


// 状态机逻辑
always @(*) begin
    if (rst) read_mem_falg= 1'b0;

    case (state)
        IDLE: begin
            rready = 1'b1;
            arvalid = 1'b0;
            // read_mem_falg= 1'b0;
            ls_ready = 1'b1;
            ls_valid = 1'b0;
            if (ex_valid ) begin
                if (read_mem_en) begin  //如果不需要读数据，也不需要写数据 下一状态直接跳转至WAIT_MEM_READY
                    read_mem_falg = 1'b1;//如果有读使能，说明该执行的指令是读内存指令！
                    if ( ~ arready ) begin
                         next_state = WAIT_MEM_READY;
                    end else begin
                        next_state = WAIT_READY;//执行模块ready后，跳转至wait_input状态
                        arvalid = 1'b1;//en
                        ls_read_mem_addr = mem_addr;
                    end 
                end else if (write_mem_en) begin
                    if ( ~ wready) begin
                        next_state = WAIT_MEM_WRITE_READY;    
                    end else begin
                        wvalid = 1'b1;
                        ls_write_mem_addr = mem_addr>>2; //除去低两位，字节对齐
                        ls_mem_data = mem_data_index;//数据索引 处理后的数据
                        next_state = WAIT_READY;
                        // monitor_mem_write(mem_addr, mem_data_index, 0);  // 1 = word
                    end
                end 
                    else next_state = WAIT_READY;

            end else next_state = IDLE ;
        end
        WAIT_READY: begin
            rready = 1'b0;
            wvalid = 1'b0;
            arvalid = 1'b0;
            ls_ready = 1'b0;
            if (read_mem_falg ) begin
                if (rvalid) begin
                    ls_valid = rvalid;//
                    next_state = IDLE;//如果读内存的话，rvalid 无效则继续等待，类似于IFU
                    read_mem_falg = 1'b0;//标志位置0 读事务已经完成 该标志位还用于选择pc or LSU
                end else next_state = WAIT_READY;
            end else  begin
                ls_valid = 1'b1;//如果不需要读内存的话，则直接跳过！
                if (wb_ready) next_state = IDLE;                    
                else next_state = WAIT_READY; 
            end 


        end
        WAIT_MEM_READY: begin
            if (arready) begin
                next_state = WAIT_READY;//执行模块ready后，跳转至wait_input状态
                arvalid = 1'b1;//en
                ls_read_mem_addr = mem_addr;
            end else next_state = WAIT_MEM_READY;
        end
        WAIT_MEM_WRITE_READY: begin
            if (wready) begin
                wvalid = 1'b1;
                ls_write_mem_addr = mem_addr>>2; //除去低两位，字节对齐
                ls_mem_data = mem_data_index;//数据索引 处理后的数据
                next_state = WAIT_READY;
            end else next_state = WAIT_MEM_WRITE_READY;
        end

        default: next_state = IDLE;
    endcase
end


reg  ls_start;
always @(posedge clk) begin
        ls_start = (state == IDLE && ex_valid);
end


assign one_byte = rs2_data[7:0];//sb
assign half_word = rs2_data[15:0];//sh
wire [1:0] addr_index;
assign addr_index = mem_addr[1:0];
//后续可以优化直接在ID模块种译码出mask信号
always @(*) begin
    // if (read_mem_en) begin
        
    case (write_mem)//用两位即可,最高位用于表示 读出的数据 是符号拓展还是0拓展 读到的数据放到wbu中再处理吧
        2'b00: begin
            
            case (addr_index)
                2'b00:begin
                    mem_data_index = {24'd0 , one_byte};
                    wmask = 4'b0001;
                end 
                2'b01:begin
                    mem_data_index = {16'd0, one_byte, 8'd0 } ;
                    wmask = 4'b0010;
                end 
                2'b10:begin
                    mem_data_index = {8'd0, one_byte, 16'd0 } ; 
                    wmask = 4'b0100;
                end 
                2'b11:begin
                    mem_data_index = {one_byte,24'd0 } ;
                    wmask = 4'b1000;
                end 
                default:begin
                    mem_data_index = 32'd0;
                end
            endcase
        end

        2'b01: begin //sh 满足 addr%2=0;
            case (mem_addr[1:0])
                2'b00:begin
                    mem_data_index = {16'b0 , half_word};
                    wmask = 4'b0011;
                end 
                2'b10:begin
                    mem_data_index = { half_word,16'b0 } ;
                    wmask = 4'b1100;
                end 
                default:begin
                    mem_data_index = 32'b0;
                end
            endcase
        end
        //sw指令自带字节对齐  addr%4 =0;    
        2'b10: begin
            mem_data_index = rs2_data; //4byte
            wmask = 4'b1111;
        end
        default: begin
            wmask = 4'b1111;
        end
    endcase

    // case (mem_addr[1:0])
    //     2'b00:mem_data_index = rs2_data;
    //     2'b01:mem_data_index = {24'b0, rs2_data[15:8] } ;
    //     2'b10:mem_data_index = {24'b0, rs2_data[23:16]} ;   
    //     2'b11:mem_data_index = {24'b0, rs2_data[31:24]} ;
    //     default:begin
    //         mem_data_index = rs2_data;
    //     end
    // endcase
    // end

end





//wmask输出给存储器 write_mem输出给WBU 
always @(*) begin
    if (ls_start) begin //读写是不是可以共用这个？ 感觉可以，待会儿试试
        // ls_write_csr_en = write_csr_en;
        // ls_csr_rd_data = csr_rd_data;
        ls_write_reg = write_reg;
        ls_write_mem = write_mem;//写字节 
        ls_read_mem = read_mem;//读字节
        ls_rd_aluout_mem = rd_aluout_mem;
        ls_rd_data = rd_data;
        ls_rd_addr = rd_addr;
        ls_jump_next_pc = jump_next_pc;
        ls_jump = jump;
    end 
end


// always @(*)begin

    
// end


endmodule