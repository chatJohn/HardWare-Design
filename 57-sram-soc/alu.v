`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
	input wire[31:0] a,
	input wire[31:0] b,
	input wire[4:0] sa, // 移位指令的sa
	input wire[7:0] alucontrol,
	output reg[31:0] y,
	output reg overflow,
	input wire[63:0] hilo_in,
	output reg [63:0] hilo_out,
	input wire [15:0] offset // 存取指令的offset 
    );

	always @(*) begin
		y = 32'h00000000;
		overflow = 0;
		hilo_out = 0;
		case (alucontrol)
			`EXE_AND_OP: begin
				y = a & b;
				overflow = 0;
			end
			`EXE_OR_OP: begin
				y = a | b;
				overflow = 0;
			end
			`EXE_XOR_OP: begin
				y = a ^ b;
				overflow = 0;
			end
			`EXE_NOR_OP: begin
				y = ~(a | b);
				overflow = 0;
			end
			`EXE_ANDI_OP: begin
				y = a & b;
				overflow = 0;
			end
			`EXE_ORI_OP: begin
				y = a | b;
				overflow = 0;
			end
			`EXE_XORI_OP: begin
				y = a ^ b;
				overflow = 0;
			end
			`EXE_LUI_OP: begin // 将rt的高16位为立即数，后16位为0
				y = {b[15:0], 16'b0};
				overflow = 0;
			end

			// shift instrucion 
			`EXE_SLL_OP: begin
				y = b << sa;
				overflow = 0;
			end
			`EXE_SRL_OP: begin
				y = b >> sa;
				overflow = 0;
			end
			`EXE_SRA_OP: begin
				y = ({32{b[31]}} << (6'd32 -{1'b0,sa})) | b >> sa; 
				overflow = 0;
			end
			`EXE_SLLV_OP: begin
				y = b << a[4:0];
				overflow = 0;
			end
			`EXE_SRLV_OP: begin
				y = b >> a[4:0];
				overflow = 0;
			end
			`EXE_SRAV_OP: begin
				y = ({32{b[31]}} << (6'd32 -{1'b0,a[4:0]})) | b >> a[4:0];
				overflow = 0; 
			end
			
			// move instruction
			`EXE_MFHI_OP: begin
				y = hilo_in[63:32];
				overflow = 0;
			end
			`EXE_MFLO_OP: begin
				y = hilo_in[31:0];
				overflow = 0;
			end
			`EXE_MTHI_OP: begin
				hilo_out = {a, hilo_in[31:0]};
				overflow = 0;
			end
			`EXE_MTLO_OP: begin
				hilo_out = {hilo_in[31:0], a};
				overflow = 0;
			end

			`EXE_ADD_OP: begin
				y = a + b;
				overflow = (~y[31] & a[31] & b[31]) | (y[31] & ~a[31] & ~b[31]);
			end
			`EXE_ADDU_OP: begin
				y = a + b;
				overflow = 0;
			end
			`EXE_SUB_OP: begin
				y = a - b;
				overflow = (~y[31] & a[31] & ~b[31]) | (y[31] & ~a[31] & b[31]);
			end
			`EXE_SUBU_OP: begin
				y = a - b;
				overflow = 0;
			end
			`EXE_SLT_OP: begin
				y = ($signed(a) < $signed(b)) ? 1 : 0;
				overflow = 0;
			end
			`EXE_SLTU_OP: begin
				y = a < b ? 1 : 0;
				overflow = 0;
			end
			`EXE_EQUAL_OP: begin
				y = (a == b) ? 1 : 0;
				overflow = 0;
			end
		/////////// 将除法指令移除alu计算 //////
		//////// `EXE_DIV_OP: begin		//////
		//////							//////
		//////// end					//////
		//////// `EXE_DIVU_OP: begin	//////
		//////							//////
		////// end						//////
		////////// 将除法指令移除alu中计算//////
			`EXE_MULT_OP: begin
				hilo_out = $signed(a) * $signed(b);
				overflow = 0;
			end
			`EXE_MULTU_OP: begin
				hilo_out = {32'b0, a} * {32'b0, b};
				overflow = 0;
			end
			`EXE_ADDI_OP: begin
				y = a + b;
				overflow = (~y[31] & a[31] & b[31]) | (y[31] & ~a[31] & ~b[31]);
			end
			`EXE_ADDIU_OP: begin
				y = a + b;
				overflow = 0;
			end
			`EXE_SLTI_OP: begin
				y = $signed(a) < $signed(b) ? 1 : 0;
				overflow = 0;
			end
			`EXE_SLTIU_OP:	begin
				y = a < b ? 1 : 0;
				overflow = 0;
			end

			// StoreAndLoad instruction: 全部都是符号扩展
			`EXE_LB_OP, 
			`EXE_LBU_OP,
			`EXE_LH_OP,
			`EXE_LHU_OP,
			`EXE_LW_OP,
			`EXE_SB_OP,
			`EXE_SH_OP,
			`EXE_SW_OP: begin
				y = a + {{16{offset[15]}}, offset}; // 结果为虚地址
				overflow = 0;
			end
			default: begin
				y = 32'b0;
				overflow = 0;
				hilo_out = 0;
			end

		endcase

	end
endmodule
