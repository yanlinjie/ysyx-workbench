module IFU( 
    input clk,
    input rst,

    input  arready,//arready
    output reg        read_en,//arvalid
    output reg rready,

    input [31:0] next_inst,
    input rvalid,
    input [31:0] next_pc,
    input        id_ready,
    input        down,             
    input jump_flag,
    input [31:0] jump_pc,
    input [31:0] imm,

    output reg        inst_valid,
    output reg [31:0] pc,

    output reg [31:0] inst
);

    // 状态定义（使用 localparam）
    localparam IDLE             = 3'b000;
    localparam WAIT_READY       = 3'b001;
    localparam BOOT             = 3'b010;//初始复位状态
    localparam WAIT_MEM_READY   = 3'b011;
    // localparam WAIT_MEM_VALID   = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

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
                // read_en <= 1'b1;
                inst_valid = 1'b0;
                rready = 1'b1;
                pc = next_pc;
                read_en = 1'b1;
                
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
                    // read_en = 1'b1;
                end else next_state = WAIT_MEM_READY;
            end
            // WAIT_MEM_VALID:begin
                
            // end

            default:
                next_state = IDLE ;
        endcase
    end

// reg  if_start;
// // 这里和 IDU 有点不一样, 可能三选一结构延迟比较小？
// always @(posedge clk) begin
//         if_start = (state == IDLE);
// end



// reg condition_branch_d1; // 上一个周期的值
// wire condition_branch_rising;

// always @(posedge clk or posedge rst) begin
//     if (rst)
//         condition_branch_d1 <= 1'b0;
//     else
//         condition_branch_d1 <= condition_branch;
// end

// assign condition_branch_rising = (condition_branch == 1'b1) && (condition_branch_d1 == 1'b0);



endmodule
