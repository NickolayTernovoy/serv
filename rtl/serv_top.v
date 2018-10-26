`default_nettype none
module serv_top
  (
   input         clk,
   output [31:0] o_i_ca_adr, 
   output        o_i_ca_vld,
   input         i_i_ca_rdy,
   input [31:0]  i_i_rd_dat,
   input         i_i_rd_vld,
   output        o_i_rd_rdy,
   output        o_d_ca_cmd,
   output [31:0] o_d_ca_adr,
   output        o_d_ca_vld,
   input         i_d_ca_rdy,
   output [31:0] o_d_dm_dat,
   output [3:0]  o_d_dm_msk,
   output        o_d_dm_vld,
   input         i_d_dm_rdy,
   input [31:0]  i_d_rd_dat,
   input         i_d_rd_vld,
   output        o_d_rd_rdy);

`include "serv_params.vh"

   wire [4:0]    rd_addr;
   wire [4:0]    rs1_addr;
   wire [4:0]    rs2_addr;
   
   wire [1:0]    rd_source;
   wire          ctrl_rd;
   wire          alu_rd;
   wire          mem_rd;
   wire          rd;

   wire          ctrl_en;
   wire          jump;
   wire          offset;
   wire          offset_source;
   wire          imm;

   wire [2:0]    funct3;
   
   wire          rs1;
   wire          rs2;
   wire          rs_en;
   wire          rd_en;

   wire          op_b_source;
   wire          op_b;

   wire          mem_en;
   
   wire          mem_cmd = 1'b0 /*FIXME*/;
   wire          mem_dat_valid;
   
   wire          mem_init;
   wire          mem_busy;
   
   parameter RESET_PC = 32'd8;

   serv_decode decode
     (
      .clk (clk),
      .i_i_rd_dat     (i_i_rd_dat),
      .i_i_rd_vld     (i_i_rd_vld),
      .o_i_rd_rdy     (o_i_rd_rdy),
      .o_ctrl_en      (ctrl_en),
      .o_ctrl_jump    (jump),
      .o_funct3       (funct3),
      .o_rf_rd_en     (rd_en),
      .o_rf_rd_addr   (rd_addr),
      .o_rf_rs_en     (rs_en),
      .o_rf_rs1_addr  (rs1_addr),
      .o_rf_rs2_addr  (rs2_addr),
      .o_mem_en       (mem_en),
      .o_mem_init     (mem_init),
      .o_mem_dat_valid (mem_dat_valid),
      .i_mem_busy     (mem_busy),
      .o_imm          (imm),
      .o_offset_source (offset_source),
      .o_op_b_source  (op_b_source),
      .o_rd_source    (rd_source));

   serv_ctrl
     #(.RESET_PC (RESET_PC))
   ctrl
     (
      .clk        (clk),
      .i_en       (ctrl_en),
      .i_jump     (jump),
      .i_offset   (offset),
      .o_rd       (ctrl_rd),
      .o_i_ca_adr (o_i_ca_adr),
      .o_i_ca_vld (o_i_ca_vld),
      .i_i_ca_rdy (i_i_ca_rdy));

   assign offset = (offset_source == OFFSET_SOURCE_IMM) ? imm : rs1;

   assign rd = (rd_source == RD_SOURCE_CTRL) ? ctrl_rd :
               (rd_source == RD_SOURCE_ALU)  ? alu_rd :
               (rd_source == RD_SOURCE_IMM)  ? imm :
               (rd_source == RD_SOURCE_MEM)  ? mem_rd : 1'b0;
   

   assign op_b = (op_b_source == OP_B_SOURCE_IMM) ? imm :
                 1'b0;
   
   serv_alu alu
     (
      .clk (clk),
      .i_en (ctrl_en), /*FIXME: Is this true?*/
      .i_funct3 (funct3),
      .i_rs1 (rs1),
      .i_op_b (op_b),
      .o_rd (alu_rd));

   serv_regfile regfile
     (
      .i_clk      (clk),
      .i_rd_en    (rd_en),
      .i_rd_addr  (rd_addr),
      .i_rd       (rd),
      .i_rs1_addr (rs1_addr),
      .i_rs2_addr (rs2_addr),
      .i_rs_en    (rs_en),
      .o_rs1      (rs1),
      .o_rs2      (rs2));
   
   serv_mem_if mem_if
     (
      .i_clk (clk),
      .i_en  (mem_en),
      .i_init (mem_init),
      .i_dat_valid (mem_dat_valid),
      .i_cmd (mem_cmd),
      .i_funct3 (funct3),
      .i_rs1    (rs1),
      .i_rs2    (rs2),
      .i_imm    (imm),
      .o_rd     (mem_rd),
      .o_busy   (mem_busy),
   //External interface
      .o_d_ca_cmd (o_d_ca_cmd),
      .o_d_ca_adr (o_d_ca_adr),
      .o_d_ca_vld (o_d_ca_vld),
      .i_d_ca_rdy (i_d_ca_rdy),
      .o_d_dm_dat (o_d_dm_dat),
      .o_d_dm_msk (o_d_dm_msk),
      .o_d_dm_vld (o_d_dm_vld),
      .i_d_dm_rdy (i_d_dm_rdy),
      .i_d_rd_dat (i_d_rd_dat),
      .i_d_rd_vld (i_d_rd_vld),
      .o_d_rd_rdy (o_d_rd_rdy));

endmodule