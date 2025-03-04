module ysyx_24110006_EXU(
  input i_clock,
  input i_reset,
  input [6:0] i_op,
  input [2:0] i_func,
  input [31:0] i_alu_a,
  input [31:0] i_alu_b,
  input [3:0] i_alu_t,
  input i_alu_sign,
  input i_alu_sub,  
  input i_alu_sra,
  input [31:0] i_reg_src1,
  input [31:0] i_csr_src,  
  input [31:0] i_imm,
  input [31:0] i_pc,
  input [31:0] i_csr_upc,  
  output [31:0] o_result,
  output [31:0] o_upc,
  output o_result_t,  
  output [3:0] o_alu_t,
  output o_cmp,
  output o_zero,  
  output o_reg_wen,
  output o_csr_wen,  
  output o_jump,
  output o_trap,  
  output o_mem_ren,
  output o_mem_wen,
  output [3:0] o_mem_wmask,
  output [2:0] o_mem_read_t,
  output [31:0] o_mem_addr,  
  output o_fencei,
  
  input i_valid,
  output reg o_valid
);

reg [6:0] op;
reg [2:0] func;
reg [31:0] reg_src1;
reg [31:0] csr_src;
reg [31:0] imm;
reg [31:0] pc;

/* reg valid; */
/**/
/* always@(posedge i_clock)begin */
/*   if(i_reset) valid <= 0; */
/*   else if(i_valid && !valid) valid <= 1; */
/*   else if(valid && !o_valid) valid <= 0; */
/* end */

always@(posedge i_clock)begin
  if(i_reset) o_valid <= 0;
  else if(!o_valid && i_valid) begin
    o_valid <= 1;
  end
  else if(o_valid)begin
    o_valid <= 0;
  end
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    op <= i_op;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    func <= i_func;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    reg_src1 <= i_reg_src1;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    csr_src <= i_csr_src;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    imm <= i_imm;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid)
    pc <= i_pc;
end
always@(posedge i_clock)begin
  if(!i_reset && i_valid && !o_valid)
    upc <= i_op == 7'b1110011 ? i_csr_upc : (i_op == 7'b1100111 ? i_reg_src1 : i_pc);
end

always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid) alu_a <= i_alu_a;
  end
  always@(posedge i_clock)begin
    if(!i_reset && !o_valid && i_valid) alu_b <= i_alu_b;
  end
  always@(posedge i_clock)begin
    if(!i_reset && !o_valid && i_valid) alu_sub <= i_alu_sub;
  end
  always@(posedge i_clock)begin
    if(!i_reset && !o_valid && i_valid) alu_sign <= i_alu_sign;
  end
  always@(posedge i_clock)begin
    if(!i_reset && !o_valid && i_valid) alu_sra <= i_alu_sra;
end
always@(posedge i_clock)begin
  if(!i_reset && !o_valid && i_valid) alu_t <= i_alu_t;
end

`ifndef CONFIG_YOSYS
always@(posedge i_clock)begin
  if(o_valid && !(I||R||L||S||JAL||JALR||AUIPC||LUI||B||CSR||FENCE)) begin
    $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh` in pc `%xh` \n", i_op, i_pc);
    quit();
  end
end
`endif

wire I = op == 7'b0010011;
wire R = op == 7'b0110011;
wire L = op == 7'b0000011;
wire S = op == 7'b0100011;
wire JAL = op == 7'b1101111;
wire JALR = op == 7'b1100111;
wire AUIPC = op == 7'b0010111;
wire LUI = op == 7'b0110111;
wire B = op == 7'b1100011;
wire CSR = op == 7'b1110011;
wire FENCE = op == 7'b0001111;

wire f000 = func == 3'b000;
wire f001 = func == 3'b001;
wire f010 = func == 3'b010;
wire f011 = func == 3'b011;
wire f100 = func == 3'b100;
wire f101 = func == 3'b101;
wire f110 = func == 3'b110;
wire f111 = func == 3'b111;

assign o_result_t = L;
assign o_mem_wen = S;
assign o_mem_ren = L;
assign o_mem_wmask = S ? (f000 ? 4'b0001 : f001 ? 4'b0011 : 4'b1111) : 0;
assign o_mem_read_t = L ? func : 0;
assign o_fencei = FENCE && f001;

reg [31:0] alu_a, alu_b;
reg alu_sub;
reg alu_sign;
reg alu_sra;
reg [3:0] alu_t;

/* assign alu_a = JAL || JALR || AUIPC ? pc : LUI ? 0 : reg_src1; */
/* assign alu_b = I || L || AUIPC || S  || LUI ? imm : JAL || JALR ? 32'b100 : CSR && f001 ? 32'b0 : CSR && f010 ? csr_src : reg_src2; */
/* assign alu_t = I||R ? {1'b0, func} : B ? {1'b1, func} : CSR && f010 ? 4'b0110 : 0; */
/* assign alu_sign = R && f010 || B && (f100 || f101); */
/* assign alu_sub = (I || R) && (f011 || f010) || B || R && f000 && imm[5]; */
/* assign alu_sra = R && imm[5] || I && imm[10]; */

/* reg [31:0] r_alu_a, r_alu_b; */
/* reg r_alu_sub; */
/* reg r_alu_sign; */
/* reg r_alu_sra; */
/* reg [3:0] r_alu_t; */
/**/
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_a <= alu_a; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_b <= alu_b; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sub <= alu_sub; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sign <= alu_sign; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_sra <= alu_sra; */
/* end */
/* always@(posedge i_clock)begin */
/*   if(valid) r_alu_t <= alu_t; */
/* end */


ysyx_24110006_ALU malu(
  .i_a(alu_a),
  .i_b(alu_b),
  .i_sub(alu_sub),
  .i_sign(alu_sign),
  .i_alu_t(alu_t),
  .i_alu_sra(alu_sra),
  .o_r(o_result),
  .o_cmp(o_cmp),
  .o_zero(o_zero),
  .o_add_r(o_mem_addr)
);

reg [31:0] upc;

assign o_upc = upc + imm;
assign o_jump = JAL || JALR;
assign o_trap = CSR && f000;
assign o_reg_wen = !(S || B);
assign o_csr_wen = CSR;
assign o_alu_t = alu_t;
endmodule