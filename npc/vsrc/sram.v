import "DPI-C" function int pmem_read(input int raddr);
import "DPI-C" function void pmem_write(
  input int waddr, input int wdata, input byte wmask);

module ysyx_24110006_SRAM(
  input i_clock,
  input i_reset,

  input [31:0] i_axi_araddr,
  input i_axi_arvalid,
  output o_axi_arready,

  output [31:0] o_axi_rdata,
  output o_axi_rvalid,
  output [1:0] o_axi_rresp,
  input i_axi_rready,

  input [31:0] i_axi_awaddr,
  input i_axi_awvalid,
  output o_axi_awready,

  input [31:0] i_axi_wdata,
  input [7:0] i_axi_wstrb,
  input i_axi_wvalid,
  output o_axi_wready,

  output [1:0] o_axi_bresp,
  output o_axi_bvalid,
  input i_axi_bready
);

reg [31:0] araddr;
wire arready = 1;
reg [31:0] rdata;
reg rvalid;
reg [1:0] rresp;
reg [31:0] awaddr;
wire awready = 1;
reg [31:0] wdata;
wire wready = 1;
reg [7:0] wstrb;
reg bvalid;
reg [1:0] bresp;

// Read address channel
wire arvalid = i_axi_arvalid;
assign o_axi_arready = arready;
// Read data channel
assign o_axi_rdata = rdata;
assign o_axi_rvalid = rvalid;
assign o_axi_rresp = rresp;
wire rready = i_axi_rready;
// Write address channel
wire awvalid = i_axi_awvalid;
assign o_axi_awready = awready;
// Write data channel
wire wvalid = i_axi_wvalid;
assign o_axi_wready = wready;
// Write response channel
assign o_axi_bresp = bresp;
assign o_axi_bvalid = bvalid;
wire bready = i_axi_bready;

always@(posedge i_clock)begin
  if(i_reset) araddr <= 0;
  else if(arvalid && arready)begin
    araddr <= i_axi_araddr;
  end
end

always@(posedge i_clock)begin
  if(i_reset) rdata <= 0;
  else if(arvalid && arready)begin
    rdata <= pmem_read(i_axi_araddr);
  end
end

always@(posedge i_clock)begin
  if(i_reset) rvalid <= 0;
  else if(arvalid && arready && !rvalid)begin
    rvalid <= 1;
  end
  else if(rvalid && rready) begin
    rvalid <= 0;
  end
end

always@(posedge i_clock)begin
  if(i_reset) awaddr <= 0;
  else if(awvalid && awready)begin
    awaddr <= i_axi_awaddr;
  end
end

always@(posedge i_clock)begin
  if(i_reset) wdata <= 0;
  else if(wvalid && wready)begin
    wdata <= i_axi_wdata;
  end
end

always@(posedge i_clock)begin
  if(i_reset) wstrb <= 0;
  else if(wvalid && wready)begin
    wstrb <= i_axi_wstrb;
  end
end

always@(posedge i_clock)begin
  if(awvalid && awready && wvalid && wready && !bvalid)begin
    pmem_write(i_axi_awaddr, i_axi_wdata, i_axi_wstrb);
  end
end

always@(posedge i_clock)begin
  if(i_reset) bvalid <= 0;
  else if(awvalid && awready && wvalid && wready && !bvalid)begin
    bvalid <= 1;
  end
  else if(bvalid && bready) begin
    bvalid <= 0;
  end
end

endmodule