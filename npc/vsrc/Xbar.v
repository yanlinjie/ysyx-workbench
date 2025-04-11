// A minimal AXI4-Lite crossbar (Xbar) module supporting 3 slaves: UART, CLINT, SRAM
// and supporting 2 masters (IFU and LSU) with a simple round-robin arbiter.

module Xbar #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  input  wire clk,
  input  wire reset,

  // IFU interface
  input  wire [ADDR_WIDTH-1:0] ifu_awaddr,
  input  wire                  ifu_awvalid,
  input  wire [DATA_WIDTH-1:0] ifu_wdata,
  input  wire [3:0]            ifu_wstrb,
  input  wire                  ifu_wvalid,
  input  wire [ADDR_WIDTH-1:0] ifu_araddr,
  input  wire                  ifu_arvalid,
  output reg                  ifu_awready,
  output reg                  ifu_wready,

  output reg  [1:0]            ifu_bresp,
  output reg                   ifu_bvalid,
  input  wire                  ifu_bready,

  output reg                  ifu_arready,
  output reg  [DATA_WIDTH-1:0] ifu_rdata,
  output reg  [1:0]            ifu_rresp,
  output reg                   ifu_rvalid,
  input  wire                  ifu_rready,

  // LSU interface
  input  wire [ADDR_WIDTH-1:0] lsu_awaddr,
  input  wire                  lsu_awvalid,
  input  wire [DATA_WIDTH-1:0] lsu_wdata,
  input  wire [3:0]            lsu_wstrb,
  input  wire                  lsu_wvalid,
  input  wire [ADDR_WIDTH-1:0] lsu_araddr,
  input  wire                  lsu_arvalid,
  output reg                  lsu_awready,
  output reg                  lsu_wready,
  output reg  [1:0]            lsu_bresp,
  output reg                   lsu_bvalid,
  input  wire                  lsu_bready,
  output reg                  lsu_arready,
  output reg  [DATA_WIDTH-1:0] lsu_rdata,
  output reg  [1:0]            lsu_rresp,
  output reg                   lsu_rvalid,
  input  wire                  lsu_rready,

  // Slave 0: UART
    output reg        [ADDR_WIDTH-1:0] s0_awaddr                  ,
    output reg                         s0_awvalid                 ,
    input  wire                         s0_awready                 ,
    output reg        [DATA_WIDTH-1:0] s0_wdata                   ,
    output reg        [   3:0]         s0_wstrb                   ,
    output reg                         s0_wvalid                  ,
    input  wire                         s0_wready                  ,
    input  wire        [   1:0]         s0_bresp                   ,
    input  wire                         s0_bvalid                  ,
    output reg                         s0_bready                  ,
    output reg        [ADDR_WIDTH-1:0] s0_araddr                  ,
    output reg                         s0_arvalid                 ,
    input  wire                         s0_arready                 ,
    input  wire        [DATA_WIDTH-1:0] s0_rdata                   ,
    input  wire        [   1:0]         s0_rresp                   ,
    input  wire                         s0_rvalid                  ,
    output reg                         s0_rready                  ,

  // Slave 1: CLINT
  output reg [ADDR_WIDTH-1:0] s1_awaddr,
  output reg                  s1_awvalid,
  input  wire                  s1_awready,
  output reg [DATA_WIDTH-1:0] s1_wdata,
  output reg [3:0]            s1_wstrb,
  output reg                  s1_wvalid,
  input  wire                  s1_wready,
  input  wire [1:0]            s1_bresp,
  input  wire                  s1_bvalid,
  output reg                  s1_bready,
  output reg [ADDR_WIDTH-1:0] s1_araddr,
  output reg                  s1_arvalid,
  input  wire                  s1_arready,
  input  wire [DATA_WIDTH-1:0] s1_rdata,
  input  wire [1:0]            s1_rresp,
  input  wire                  s1_rvalid,
  output reg                  s1_rready,

  // Slave 2: SRAM
  output reg [ADDR_WIDTH-1:0] s2_awaddr,
  output reg                  s2_awvalid,
  input  wire                  s2_awready,
  output reg [DATA_WIDTH-1:0] s2_wdata,
  output reg [3:0]            s2_wstrb,
  output reg                  s2_wvalid,
  input  wire                  s2_wready,
  input  wire [1:0]            s2_bresp,
  input  wire                  s2_bvalid,
  output reg                  s2_bready,
  output reg [ADDR_WIDTH-1:0] s2_araddr,
  output reg                  s2_arvalid,
  input  wire                  s2_arready,
  input  wire [DATA_WIDTH-1:0] s2_rdata,
  input  wire [1:0]            s2_rresp,
  input  wire                  s2_rvalid,
  output reg                  s2_rready
);
//UART 0x1000_0000, 0x1000_0fff
//SRAM 0x8000_0000, 0x80ff_ffff
  localparam UART_BASE  = 32'ha0000000;
  localparam UART_MASK  = 32'hfffff000;
  localparam CLINT_BASE = 32'h20000000;
  localparam CLINT_MASK = 32'hfffff000;
  localparam SRAM_BASE  = 32'h80000000;
  localparam SRAM_MASK  = 32'hff000000;

reg [1:0] selected_slave;


wire                   [ADDR_WIDTH-1:0] m_awaddr                   ;
wire                                    m_awvalid                  ;
wire                   [DATA_WIDTH-1:0] m_wdata                    ;
wire                   [   3:0]         m_wstrb                    ;
wire                                    m_wvalid                   ;
reg                   [ADDR_WIDTH-1:0] m_araddr                   ;
wire                                    m_arvalid                  ;
wire                                    m_bready                   ;
wire                                    m_rready                   ;

reg                    [   1:0]         sresp                      ;
reg                    [DATA_WIDTH-1:0] sdata                      ;
reg                                     svalid                     ;
reg        use_ifu;
reg [1:0]  m_bresp;
reg        m_bvalid;
reg [DATA_WIDTH-1:0] m_rdata;
reg [1:0]  m_rresp;
reg        m_rvalid;

always @(*) begin
  if (reset)
    use_ifu = 1'b1;
  else if (ifu_arvalid )//取值没有写地址
  begin
        use_ifu = 1'b1;
    m_araddr = ifu_araddr;
  end
  else if ((lsu_arvalid || lsu_awvalid) )
    use_ifu = 1'b0;
end



always @(*) begin
  if ((m_arvalid && ((m_araddr & UART_MASK) == UART_BASE)) || (m_awvalid && ((m_awaddr & UART_MASK) == UART_BASE))) selected_slave = 2'd0;
  else if ((m_arvalid && ((m_araddr & CLINT_MASK) == CLINT_BASE)) || (m_awvalid && ((m_awaddr & CLINT_MASK) == CLINT_BASE))) selected_slave = 2'd1;
  else if ((m_arvalid && ((m_araddr & SRAM_MASK) == SRAM_BASE)) || (m_awvalid && ((m_awaddr & SRAM_MASK) == SRAM_BASE))) selected_slave = 2'd2;
  else selected_slave = 2'd3;
end

  always @(*) begin
    case (selected_slave)
      2'd0: begin
        if (use_ifu) begin
            s0_awaddr = ifu_awaddr ;
            s0_awvalid=ifu_awvalid;
            s0_wdata  =ifu_wdata  ;
            s0_wstrb  =ifu_wstrb  ;
            s0_wvalid =ifu_wvalid ;
            s0_bready =ifu_bready ;
            s0_araddr =ifu_araddr ;
            s0_arvalid=ifu_arvalid;
            s0_rready =ifu_rready ;

            ifu_awready= s0_awready;
            ifu_wready = s0_wready ;
            ifu_bresp  = s0_bresp  ;
            ifu_bvalid = s0_bvalid ;
            ifu_arready= s0_arready;
            ifu_rdata  = s0_rdata  ;
            ifu_rresp  = s0_rresp  ;
            ifu_rvalid = s0_rvalid ;
        end else begin
            s0_awaddr =lsu_awaddr ;
            s0_awvalid=lsu_awvalid;
            s0_wdata  =lsu_wdata  ;
            s0_wstrb  =lsu_wstrb  ;
            s0_wvalid =lsu_wvalid ;
            s0_bready =lsu_bready ;
            s0_araddr =lsu_araddr ;
            s0_arvalid=lsu_arvalid;
            s0_rready =lsu_rready ;

            lsu_awready= s0_awready;
            lsu_wready = s0_wready ;
            lsu_bresp  = s0_bresp  ;
            lsu_bvalid = s0_bvalid ;
            lsu_arready= s0_arready;
            lsu_rdata  = s0_rdata  ;
            lsu_rresp  = s0_rresp  ;
            lsu_rvalid = s0_rvalid ;
        end

      end
      2'd1: begin
        if (use_ifu) begin
            s1_awaddr =ifu_awaddr ;
            s1_awvalid=ifu_awvalid;
            s1_wdata  =ifu_wdata  ;
            s1_wstrb  =ifu_wstrb  ;
            s1_wvalid =ifu_wvalid ;
            s1_bready =ifu_bready ;
            s1_araddr =ifu_araddr ;
            s1_arvalid=ifu_arvalid;
            s1_rready =ifu_rready ;

            ifu_awready= s1_awready;
            ifu_wready = s1_wready ;
            ifu_bresp  = s1_bresp  ;
            ifu_bvalid = s1_bvalid ;
            ifu_arready= s1_arready;
            ifu_rdata  = s1_rdata  ;
            ifu_rresp  = s1_rresp  ;
            ifu_rvalid = s1_rvalid ;
        end else begin
            s1_awaddr =lsu_awaddr ;
            s1_awvalid=lsu_awvalid;
            s1_wdata  =lsu_wdata  ;
            s1_wstrb  =lsu_wstrb  ;
            s1_wvalid =lsu_wvalid ;
            s1_bready =lsu_bready ;
            s1_araddr =lsu_araddr ;
            s1_arvalid=lsu_arvalid;
            s1_rready =lsu_rready ;

            lsu_awready= s1_awready;
            lsu_wready = s1_wready ;
            lsu_bresp  = s1_bresp  ;
            lsu_bvalid = s1_bvalid ;
            lsu_arready= s1_arready;
            lsu_rdata  = s1_rdata  ;
            lsu_rresp  = s1_rresp  ;
            lsu_rvalid = s1_rvalid ;
        end
      end
      2'd2: begin
        if (use_ifu) begin
            s1_awaddr = ifu_awaddr ;
            s1_awvalid=ifu_awvalid;
            s1_wdata  =ifu_wdata  ;
            s1_wstrb  =ifu_wstrb  ;
            s1_wvalid =ifu_wvalid ;
            s1_bready =ifu_bready ;
            s1_araddr =ifu_araddr ;
            s1_arvalid=ifu_arvalid;
            s1_rready =ifu_rready ;

            ifu_awready= s1_awready;
            ifu_wready = s1_wready ;
            ifu_bresp  = s1_bresp  ;
            ifu_bvalid = s1_bvalid ;
            ifu_arready= s1_arready;
            ifu_rdata  = s1_rdata  ;
            ifu_rresp  = s1_rresp  ;
            ifu_rvalid = s1_rvalid ;
        end else begin
            s2_awaddr = (lsu_awaddr - SRAM_BASE)>> 2  ;
            s2_awvalid=lsu_awvalid;
            s2_wdata  =lsu_wdata  ;
            s2_wstrb  =lsu_wstrb  ;
            s2_wvalid =lsu_wvalid ;
            s2_bready =lsu_bready ;
            s2_araddr =(lsu_araddr - SRAM_BASE) >> 2 ;
            s2_arvalid=lsu_arvalid;
            s2_rready =lsu_rready ;

            lsu_awready= s2_awready;
            lsu_wready = s2_wready ;
            lsu_bresp  = s2_bresp  ;
            lsu_bvalid = s2_bvalid ;
            lsu_arready= s2_arready;
            lsu_rdata  = s2_rdata  ;
            lsu_rresp  = s2_rresp  ;
            lsu_rvalid = s2_rvalid ;
        end
      end
      default: begin
        sresp = 2'b11; 
        sdata = 32'hdeadbeef; 
        svalid = 1'b1;
        m_bresp = 2'b11; 
        m_bvalid = 1'b1;
      end
    endcase
    // m_rresp = sresp;
    // m_rdata = sdata;
    // m_rvalid = svalid;
  end

// assign m_awaddr  = use_ifu ? ifu_awaddr  : lsu_awaddr;
// assign m_awvalid = use_ifu ? ifu_awvalid : lsu_awvalid;
// assign m_wdata   = use_ifu ? ifu_wdata   : lsu_wdata;
// assign m_wstrb   = use_ifu ? ifu_wstrb   : lsu_wstrb;
// assign m_wvalid  = use_ifu ? ifu_wvalid  : lsu_wvalid;
// assign m_araddr  = use_ifu ? ifu_araddr  : lsu_araddr;
// assign m_arvalid = use_ifu ? ifu_arvalid : lsu_arvalid;
// assign m_bready  = use_ifu ? ifu_bready  : lsu_bready;
// assign m_rready  = use_ifu ? ifu_rready  : lsu_rready;

// assign s0_awaddr  = m_awaddr;
// assign s0_awvalid = m_awvalid;
// assign s0_wdata   = m_wdata;
// assign s0_wstrb   = m_wstrb;
// assign s0_wvalid  = m_wvalid;
// assign s0_bready  = m_bready;
// assign s0_araddr  = m_araddr;
// assign s0_arvalid = m_arvalid;
// assign s0_rready  = m_rready;

// assign s1_awaddr  = m_awaddr;
// assign s1_awvalid = m_awvalid;
// assign s1_wdata   = m_wdata;
// assign s1_wstrb   = m_wstrb;
// assign s1_wvalid  = m_wvalid;
// assign s1_bready  = m_bready;
// assign s1_araddr  = m_araddr;
// assign s1_arvalid = m_arvalid;
// assign s1_rready  = m_rready;

// assign s2_awaddr  =  (m_awaddr - SRAM_BASE)>> 2;// write 字节对齐
// assign s2_awvalid = m_awvalid;
// assign s2_wdata   = m_wdata;
// assign s2_wstrb   = m_wstrb;
// assign s2_wvalid  = m_wvalid;
// assign s2_bready  = m_bready;
// assign s2_araddr  = (m_araddr - SRAM_BASE) >> 2;//read
// assign s2_arvalid = m_arvalid;
// assign s2_rready  = m_rready;

// assign ifu_awready = use_ifu ? ((selected_slave == 2'd0) ? s0_awready : (selected_slave == 2'd1) ? s1_awready : s2_awready) : 1'b0;
// assign ifu_wready  = use_ifu ? ((selected_slave == 2'd0) ? s0_wready  : (selected_slave == 2'd1) ? s1_wready  : s2_wready ) : 1'b0;
// assign ifu_arready = use_ifu ? ((selected_slave == 2'd0) ? s0_arready : (selected_slave == 2'd1) ? s1_arready : s2_arready) : 1'b0;
// assign lsu_awready = !use_ifu ? ((selected_slave == 2'd0) ? s0_awready : (selected_slave == 2'd1) ? s1_awready : s2_awready) : 1'b0;
// assign lsu_wready  = !use_ifu ? ((selected_slave == 2'd0) ? s0_wready  : (selected_slave == 2'd1) ? s1_wready  : s2_wready ) : 1'b0;
// assign lsu_arready = !use_ifu ? ((selected_slave == 2'd0) ? s0_arready : (selected_slave == 2'd1) ? s1_arready : s2_arready) : 1'b0;

//   always @(*) begin
//     case (selected_slave)
//       2'd0: begin
//         sresp = s0_rresp; 
//         sdata = s0_rdata; 
//         svalid = s0_rvalid;
//         m_bresp = s0_bresp; 
//         m_bvalid = s0_bvalid;
//       end
//       2'd1: begin
//         sresp = s1_rresp; 
//         sdata = s1_rdata; 
//         svalid = s1_rvalid;
//         m_bresp = s1_bresp; 
//         m_bvalid = s1_bvalid;
//       end
//       2'd2: begin
//         sresp = s2_rresp;
//         sdata = s2_rdata; 
//         svalid = s2_rvalid;
//         m_bresp = s2_bresp; 
//         m_bvalid = s2_bvalid;
//       end
//       default: begin
//         sresp = 2'b11; 
//         sdata = 32'hdeadbeef; 
//         svalid = 1'b1;
//         m_bresp = 2'b11; 
//         m_bvalid = 1'b1;
//       end
//     endcase
//     m_rresp = sresp;
//     m_rdata = sdata;
//     m_rvalid = svalid;
//   end



//   always @(*) begin
//     if (use_ifu) begin
//       ifu_bresp  = m_bresp;
//       ifu_bvalid = m_bvalid;
//       ifu_rdata  = m_rdata;
//       ifu_rresp  = m_rresp;
//       ifu_rvalid = m_rvalid;
//       lsu_bresp  = 0;
//       lsu_bvalid = 0;
//       lsu_rdata  = 0;
//       lsu_rresp  = 0;
//       lsu_rvalid = 0;
//     end else begin
//       lsu_bresp  = m_bresp;
//       lsu_bvalid = m_bvalid;
//       lsu_rdata  = m_rdata;
//       lsu_rresp  = m_rresp;
//       lsu_rvalid = m_rvalid;
//       ifu_bresp  = 0;
//       ifu_bvalid = 0;
//       ifu_rdata  = 0;
//       ifu_rresp  = 0;
//       ifu_rvalid = 0;
//     end
//   end



endmodule
