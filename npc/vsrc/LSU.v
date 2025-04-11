//目前mem 和cpu之间还没使用握手 读内存还会延迟一个时钟周期！ LSU的这个时钟周期用于读mem 下一个时钟周期数据就会出来
module LSU(
    input                               clk                        ,
    input                               rst                        ,

    input              [   1:0]         jump                       ,
    input              [  31:0]         jump_next_pc               ,
    output reg         [   1:0]         ls_jump                    ,
    output reg         [  31:0]         ls_jump_next_pc            ,

        //from ex

    input              [  31:0]         rs2_data                   ,//用于存储
    input                               write_mem_en               ,
    input                               read_mem_en                ,
    input              [   1:0]         write_mem                  ,
    input              [   2:0]         read_mem                   ,//用于判读读字节的数，以及数据是0拓展还是符号拓展
    input                               write_reg                  ,//rd en
    input              [   4:0]         rd_addr                    ,//from ex , id
    input              [  31:0]         rd_data                    ,//from alu_out
    input              [  31:0]         mem_addr                   ,//访存地址 from alu_out
    input                               rd_aluout_mem              ,
        //to wb
    output reg                          ls_write_reg               ,
    output reg         [   4:0]         ls_rd_addr                 ,
    output wire        [  31:0]         ls_rd_data                 ,
    output reg         [   1:0]         ls_write_mem               ,
    output reg         [   2:0]         ls_read_mem                ,
    output reg                          ls_rd_aluout_mem           ,



// mem_read_bus
    input                               arready                    ,//mem addr ready
    output reg                          arvalid                    ,//arvalid
    output reg         [  31:0]         ls_read_mem_addr           ,
    output reg                          rready                     ,
    input                               rvalid                     ,
    input              [  31:0]         rdata                      ,


    output reg                          read_mem_falg              ,

//mem_write_bus
    output reg         [  31:0]         ls_mem_data                ,
    output reg         [   3:0]         wmask                      ,//4 bit 可以展开表示 32位 用于掩码 1111
    input                               wready                     ,
    output reg                          wvalid                     ,

    output reg         [  31:0]         ls_write_mem_addr          ,
    output reg                          awvalid                    ,
    input                               awready                    ,


//internal bus
    input                               ex_valid                   ,
    input                               wb_ready                   ,

    output reg                          ls_ready                   ,
    output reg                          ls_valid                    


);

// 状态定义
localparam IDLE        = 3'd0;//等待上游模块的 valid信号
localparam WAIT_READY = 3'd1;//等待下游模块 ready信号
localparam WAIT_MEM_READY   = 3'd2;
localparam WAIT_MEM_WRITE_READY   = 3'd3;
localparam WAIT_MEM_DATA_VALID = 3'd4;
reg [2:0] state, next_state;
reg [31:0] mem_addr_index;
reg [31:0] mem_data_index;
wire  [7:0] one_byte;
wire [15:0] half_word;
reg [15:0] one_word;
reg [31:0] ls_rdata;
// 状态转移
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end


// 状态机逻辑
always @(*) begin
    // if (rst) read_mem_falg= 1'b0;

    case (state)
        IDLE: begin
            wvalid = 1'b0;//write addr valid
            awvalid = 1'b0;//write data valid
            rready = 1'b0;
            arvalid = 1'b0;
            ls_ready = 1'b1;
            ls_valid = 1'b0;
            if (ex_valid ) begin
                if (read_mem_en) begin  
                    if ( ~ arready ) begin
                         next_state = WAIT_MEM_READY;
                    end else begin
                        next_state = WAIT_MEM_DATA_VALID;//执行模块ready后，跳转至wait_input状态
                        arvalid = 1'b1;//en
                        ls_read_mem_addr = mem_addr;
                    end 
                end else if (write_mem_en) begin
                    if ( (~ wready) || (~ awready)) begin //wready 和awready在外部我会同时拉高 目前也基本上不会存在两者一高一低
                        next_state = WAIT_MEM_WRITE_READY;    
                    end else begin
                        wvalid = 1'b1;
                        awvalid = 1'b1;
                        ls_write_mem_addr = mem_addr; //先不除去低两位，字节对齐,外部模块再进行字节对齐
                        ls_mem_data = mem_data_index;//数据索引 处理后的数据
                        next_state = WAIT_READY;
                        // monitor_mem_write(mem_addr, mem_data_index, 0);  // 1 = word
                    end
                end 
                    else next_state = WAIT_READY; //当既没有 read 也没有 write 的时候，则直接跳到WAIT_READY状态
            end else next_state = IDLE ;
        end
        WAIT_READY: begin //读写过程中不会跳到这个状态  只有没有读写才会直接进入这个状态
            rready = 1'b0;
            wvalid = 1'b0;
            awvalid = 1'b0;
            arvalid = 1'b0;
            ls_ready = 1'b0;
            ls_valid = 1'b1;
            if (wb_ready) next_state = IDLE;                    
            else next_state = WAIT_READY; 
        end

        WAIT_MEM_READY: begin//read addr 等待两者握手
            if (arready) begin
                rready = 1'b1;//，该状态握手成功后 拉高数据接收准备信号 
                arvalid = 1'b1;//en
                ls_read_mem_addr = mem_addr;//输出的字节对齐放到外部模块处理
                next_state = WAIT_MEM_DATA_VALID;//握手成功后，跳到下一状态，在下一状态等待read数据有效信号，并且拉低arvalid 信号
            end else next_state = WAIT_MEM_READY;
        end

        WAIT_MEM_DATA_VALID: begin//read data
            if (rvalid) begin
                arvalid = 1'b0;//拉低地址有效信号
                ls_valid = rvalid;//
                ls_rdata = rdata;
                if (wb_ready) next_state = IDLE;                    
                else next_state = WAIT_MEM_DATA_VALID; 
            end else next_state = WAIT_MEM_DATA_VALID;
        end

        WAIT_MEM_WRITE_READY: begin//write
            if (wready && awready) begin
                wvalid = 1'b1;
                awvalid = 1'b1;
                ls_write_mem_addr = mem_addr; //先不除去低两位，字节对齐
                ls_mem_data = mem_data_index;//数据索引 处理后的数据
                next_state = IDLE;
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
always @(*) begin
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
end


//read 这里做了读数据字节对齐
reg [31:0] wb_rddata_1;
reg [7:0] read_one_byte;
reg [15:0] read_half_word;
wire [1:0] read_index;
assign  read_index= ls_read_mem_addr[1:0];
always @(*) begin
    case (ls_read_mem[1:0])
        2'b00: begin //one_byte lb
                case(read_index)
                     2'b00: read_one_byte = ls_rdata[7:0];
                     2'b01: read_one_byte = ls_rdata[15:8];
                     2'b10: read_one_byte = ls_rdata[23:16];
                     2'b11: read_one_byte = ls_rdata[31:24];
                    default: read_one_byte = 8'b0;
            endcase
                    wb_rddata_1 ={ 24'd0 ,read_one_byte};//lb读取一字节后，再给wbu处理，写的有点冗余。
        end
        2'b01: begin //one_byte lh
                case(read_index)
                     2'b00: read_half_word = ls_rdata[15:0];
                     2'b10: read_half_word = ls_rdata[31:16];
                    default: read_half_word = 16'b0;
            endcase
                    wb_rddata_1 ={ 16'd0 ,read_half_word};//lb读取一字节后，再给wbu处理，写的有点冗余。
        end
        2'b10: wb_rddata_1 = ls_rdata; 
        default: begin
            wb_rddata_1 = ls_rdata;
        end
    endcase
end


assign ls_rd_data = rd_aluout_mem ? wb_rddata_1 : rd_data;


always @(*) begin
    if (ls_start) begin 
        ls_write_reg = write_reg;
        ls_write_mem = write_mem;//写字节 
        ls_read_mem = read_mem;//读字节
        ls_rd_aluout_mem = rd_aluout_mem;
        // ls_rd_data = rd_data;
        ls_rd_addr = rd_addr;
        ls_jump_next_pc = jump_next_pc;
        ls_jump = jump;
    end 
end





endmodule