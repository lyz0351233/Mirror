/* import "DPI-C" function int inst_fetch(input int addr); */

module ysyx_24110006_IFU(
  input i_clock,
  input i_reset,
  input [31:0] i_pc,
  output reg [31:0] o_inst,
  input i_fencei,

  input i_valid,
  output reg o_valid,
  
  output [31:0] o_axi_araddr,
  output o_axi_arvalid,
  output [3:0] o_axi_arid,
  output [7:0] o_axi_arlen,
  output [2:0] o_axi_arsize,
  output [1:0] o_axi_arburst,  
  input i_axi_arready,
  input [31:0] i_axi_rdata,
  input i_axi_rvalid,
  output o_axi_rready,
  input [1:0] i_axi_rresp,
  input [3:0] i_axi_rid,
  input i_axi_rlast
);


`ifdef CONFIG_ICACHE

ysyx_24110006_ICACHE micache(
  .i_clock(i_clock),
  .i_reset(i_reset),
  .i_pc(i_pc),
  .o_inst(o_inst),
  .i_fencei(i_fencei),
  .i_valid(i_valid),
  .o_valid(o_valid),
  .o_axi_araddr(o_axi_araddr),
  .o_axi_arvalid(o_axi_arvalid),
  .i_axi_arready(i_axi_arready),
  .o_axi_arid(o_axi_arid),
  .o_axi_arlen(o_axi_arlen),
  .o_axi_arsize(o_axi_arsize),
  .o_axi_arburst(o_axi_arburst),
  .i_axi_rdata(i_axi_rdata),
  .i_axi_rvalid(i_axi_rvalid),
  .o_axi_rready(o_axi_rready),
  .i_axi_rresp(i_axi_rresp),
  .i_axi_rlast(i_axi_rlast),
  .i_axi_rid(i_axi_rid)
);

`else
reg [31:0] pc;
reg [31:0] inst;

assign o_inst = inst;

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(rvalid && !o_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(i_reset) inst <= 0;
  else if(rvalid && !o_valid) inst <= i_axi_rdata;
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    pc <= i_pc;
end
/* always@(posedge i_clock)begin */
/*   if(!i_reset && !o_valid && i_valid) */
/*     o_inst <= inst_fetch(i_pc); */
/* end */

reg arvalid;
wire arready;

wire rvalid;
wire rready = 1;
wire [1:0] rresp;

assign o_axi_araddr = pc;
assign o_axi_arvalid = arvalid;
assign arready = i_axi_arready;
assign o_axi_arid = 0;
assign o_axi_arlen = 0;
assign o_axi_arsize = 3'b010;
assign o_axi_arburst = 0;

assign rvalid = i_axi_rvalid;
assign rresp = i_axi_rresp;
assign o_axi_rready = rready;

always@(posedge i_clock) begin
  if(i_reset) arvalid <= 0;
  else if(i_valid && !arvalid) arvalid <= 1;
  else if(arvalid && arready) arvalid <= 0;
end
`endif
endmodule