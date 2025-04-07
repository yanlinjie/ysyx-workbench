import "DPI-C" function void monitor_mem_read(input int address, input int data);
import "DPI-C" function void monitor_mem_write(input int address, input int data, input int wtype);
import "DPI-C" function int pmem_read(input int raddr);

module data_mem(
    input clk, rst, 
    input [1: 0] write_mem, //写方式
    input [2: 0] read_mem,  //读方式

    input [31: 0] address, write_data,//读/写地址，读数据

    output reg [31: 0] out_mem
);

reg [7: 0] data [163840000-1: 0];//128个 1字节的寄存器

always @(*) begin
    case (read_mem[1: 0])
        2'b00:begin
            out_mem = 32'b0;
        end
        2'b01:begin
            out_mem = {data[address + 3], data[address + 2], data[address + 1], data[address]};
            monitor_mem_read(address, out_mem);
        end
        2'b10:begin
            if(read_mem[2]) out_mem = {{16{data[address + 1][7]}}, data[address + 1], data[address]};
            else out_mem = {16'b0, data[address + 1], data[address]};
            monitor_mem_read(address, out_mem);
        end
        2'b11:begin
            if(read_mem[2]) out_mem = {{24{data[address][7]}}, data[address]};
            else out_mem = {24'b0, data[address]};
            monitor_mem_read(address, out_mem);
        end 
        default:begin
            out_mem = 32'b0;
        end
    endcase
    if (address == 32'ha0000048) out_mem = pmem_read (address);
    else if (address == 32'ha0000048 + 32'h4) out_mem = pmem_read (address);
    // out_mem = pmem_read
end

always @(posedge clk) begin//大端模式
    case (write_mem)
        2'b01:begin
            data[address + 3] = write_data[31: 24];
            data[address + 2] = write_data[23: 16];
            data[address + 1] = write_data[15: 8];
            data[address] = write_data[7: 0];
            monitor_mem_write(address, write_data, 1);  // 1 = word
        end
        2'b10:begin
            data[address + 1] = write_data[15: 8];
            data[address] = write_data[7: 0];
            monitor_mem_write(address, write_data, 2);  // 1 = word
        end
        2'b11:begin
            data[address] = write_data[7: 0];
            monitor_mem_write(address, write_data, 3);  // 1 = word
        end 
        default: begin
            
        end
    endcase
end
endmodule