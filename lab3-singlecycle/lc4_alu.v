/* INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

module four_bit_selector(input wire [15:0] a0, input wire [15:0] a1, input wire [15:0] a2, input wire [15:0] a3,
                input wire [15:0] a4, input wire [15:0] a5, input wire [15:0] a6, input wire [15:0] a7,
                input wire [15:0] a8, input wire [15:0] a9, input wire [15:0] a10, input wire [15:0] a11,
                input wire [15:0] a12, input wire [15:0] a13, input wire [15:0] a14, input wire [15:0] a15,
                input wire [3:0] sel,
                output wire [15:0] y);
  wire [15:0] inputs[15:0];
  assign inputs[0] = a0;
  assign inputs[1] = a1;
  assign inputs[2] = a2;
  assign inputs[3] = a3;
  assign inputs[4] = a4;
  assign inputs[5] = a5;
  assign inputs[6] = a6;
  assign inputs[7] = a7;
  assign inputs[8] = a8;
  assign inputs[9] = a9;
  assign inputs[10] = a10;
  assign inputs[11] = a11;
  assign inputs[12] = a12;
  assign inputs[13] = a13;
  assign inputs[14] = a14;
  assign inputs[15] = a15;
  assign y = inputs[sel];
endmodule

module three_bit_selector(input wire [15:0] a0, input wire [15:0] a1, input wire [15:0] a2, input wire [15:0] a3,
                input wire [15:0] a4, input wire [15:0] a5, input wire [15:0] a6, input wire [15:0] a7,
                input wire [2:0] sel,
                output wire [15:0] y);
  wire [15:0] inputs[7:0];
  assign inputs[0] = a0;
  assign inputs[1] = a1;
  assign inputs[2] = a2;
  assign inputs[3] = a3;
  assign inputs[4] = a4;
  assign inputs[5] = a5;
  assign inputs[6] = a6;
  assign inputs[7] = a7;
  assign y = inputs[sel];
endmodule

module two_bit_selector(input wire [15:0] a0, input wire [15:0] a1, input wire [15:0] a2, input wire [15:0] a3, input wire [1:0] sel, output wire [15:0] y);
  wire [15:0] inputs[3:0];
  assign inputs[0] = a0;
  assign inputs[1] = a1;
  assign inputs[2] = a2;
  assign inputs[3] = a3;
  assign y = inputs[sel];
endmodule

module one_bit_selector(input wire [15:0] a0, input wire [15:0] a1, input wire sel, output wire [15:0] y);
  wire [15:0] inputs[1:0];
  assign inputs[0] = a0;
  assign inputs[1] = a1;
  assign y = inputs[sel];
endmodule

module lc4_alu(input  wire [15:0] i_insn,
               input wire [15:0]  i_pc,
               input wire [15:0]  i_r1data,
               input wire [15:0]  i_r2data,
               output wire [15:0] o_result);

  /*********************************************************************************************************
  CLA (0) / no CLA (1) Selector
  **********************************************************************************************************/
  wire final_selector = ((i_insn[15:12] == 4'b0000) | (i_insn[15:12] == 4'b0110) | (i_insn[15:12] == 4'b0111) | 
                         ((i_insn[15:12] == 4'b0001) & (i_insn[5:3] == 3'b000 | i_insn[5:3] == 3'b010 | i_insn[5] == 1'b1)) | 
                         (i_insn[15:12] == 4'b1100 & i_insn[11] == 1'b1)) ? 0 : 1;

  /*********************************************************************************************************
  Operators that need CLA
  **********************************************************************************************************/
  // Math Operators (12:15 0001): ADD (3:5 000), SUB (3:5 010), ADDI (3:5 1xx)
  wire [15:0] math_first_operator;
  wire [15:0] math_second_operator;
  wire [15:0] math_carry_in;
  three_bit_selector cla_math_first_op_out(.a0(i_r1data), .a1(16'h0), .a2(i_r1data), .a3(16'h0),
                                           .a4(i_r1data), .a5(i_r1data), .a6(i_r1data), .a7(i_r1data),
                                           .sel(i_insn[5:3]), .y(math_first_operator));
  three_bit_selector cla_math_second_op_out(.a0(i_r2data), .a1(16'h0), .a2(-i_r2data), .a3(16'h0),
                                            .a4({{11{i_insn[4]}}, i_insn[4:0]}), .a5({{11{i_insn[4]}}, i_insn[4:0]}),
                                            .a6({{11{i_insn[4]}}, i_insn[4:0]}), .a7({{11{i_insn[4]}}, i_insn[4:0]}),
                                            .sel(i_insn[5:3]), .y(math_second_operator));
  three_bit_selector cla_math_carry_in_out(.a0(16'h0), .a1(16'h0), .a2(16'h0), .a3(16'h0),
                                           .a4(16'h0), .a5(16'h0), .a6(16'h0), .a7(16'h0),
                                           .sel(i_insn[5:3]), .y(math_carry_in));

  // NOP, BRp, BRz, BRzp, BRn, BRnp, BRnz, BRnzp (12:15 0000)
  wire [15:0] BR_first_op_OUT;
  three_bit_selector br_first_op_out(.a0(i_pc), .a1(i_pc), .a2(i_pc), .a3(i_pc), .a4(i_pc), .a5(i_pc), .a6(i_pc), .a7(i_pc),
                                     .sel(i_insn[11:9]), .y(BR_first_op_OUT));
  wire [15:0] BR_second_op_OUT;
  three_bit_selector br_second_op_out(.a0($signed({{7{i_insn[8]}}, {i_insn[8:0]}})), .a1($signed({{7{i_insn[8]}}, {i_insn[8:0]}})),
                                      .a2($signed({{7{i_insn[8]}}, {i_insn[8:0]}})), .a3($signed({{7{i_insn[8]}}, {i_insn[8:0]}})),
                                      .a4($signed({{7{i_insn[8]}}, {i_insn[8:0]}})), .a5($signed({{7{i_insn[8]}}, {i_insn[8:0]}})),
                                      .a6($signed({{7{i_insn[8]}}, {i_insn[8:0]}})), .a7($signed({{7{i_insn[8]}}, {i_insn[8:0]}})),
                                      .sel(i_insn[11:9]), .y(BR_second_op_OUT));
  wire [15:0] BR_carry_in_OUT;
  three_bit_selector br_carry_in_out(.a0(16'b0000000000000001), .a1(16'b0000000000000001), .a2(16'b0000000000000001), .a3(16'b0000000000000001),
                                     .a4(16'b0000000000000001), .a5(16'b0000000000000001), .a6(16'b0000000000000001), .a7(16'b0000000000000001),
                                     .sel(i_insn[11:9]), .y(BR_carry_in_OUT));
  
  // LDR 0110
  wire [15:0] LDR_first_op_OUT = i_r1data;
  wire [15:0] LDR_second_op_OUT = $signed({{10{i_insn[5]}}, {i_insn[5:0]}});
  wire [15:0] LDR_carry_in_OUT = 16'h0;

  // STR 0111
  wire [15:0] STR_first_op_OUT = i_r1data;
  wire [15:0] STR_second_op_OUT = $signed({{10{i_insn[5]}}, {i_insn[5:0]}});
  wire [15:0] STR_carry_in_OUT = 16'h0;

  // JMP (12:15 1100, [11] 1)
  wire [15:0] JMP_first_op_OUT = i_pc;
  wire [15:0] JMP_second_op_OUT = $signed({{5{i_insn[10]}}, {i_insn[10:0]}});
  wire [15:0] JMP_carry_in_OUT = 16'b0000000000000001;

  // FINAL CLA OUTPUT SELECTION
  wire [15:0] final_result_first_op_cla;
  four_bit_selector final_first_op_out(.a0(BR_first_op_OUT), .a1(math_first_operator), .a2(16'h0), .a3(16'h0), .a4(16'h0), .a5(16'h0), .a6(LDR_first_op_OUT), .a7(STR_first_op_OUT), 
                              .a8(16'h0), .a9(16'h0), .a10(16'h0), .a11(16'h0), .a12(JMP_first_op_OUT), .a13(16'h0), .a14(16'h0), .a15(16'h0),
                              .sel(i_insn[15:12]), .y(final_result_first_op_cla));
  wire [15:0] final_result_second_op_cla;
  four_bit_selector final_second_op_out(.a0(BR_second_op_OUT), .a1(math_second_operator), .a2(16'h0), .a3(16'h0), .a4(16'h0), .a5(16'h0), .a6(LDR_second_op_OUT), .a7(STR_second_op_OUT), 
                              .a8(16'h0), .a9(16'h0), .a10(16'h0), .a11(16'h0), .a12(JMP_second_op_OUT), .a13(16'h0), .a14(16'h0), .a15(16'h0),
                              .sel(i_insn[15:12]), .y(final_result_second_op_cla));
  wire [15:0] final_result_carry_in_cla_temp;
  four_bit_selector final_carry_in_out(.a0(BR_carry_in_OUT), .a1(math_carry_in), .a2(16'h0), .a3(16'h0), .a4(16'h0), .a5(16'h0), .a6(LDR_carry_in_OUT), .a7(STR_carry_in_OUT), 
                              .a8(16'h0), .a9(16'h0), .a10(16'h0), .a11(16'h0), .a12(JMP_carry_in_OUT), .a13(16'h0), .a14(16'h0), .a15(16'h0),
                              .sel(i_insn[15:12]), .y(final_result_carry_in_cla_temp));
  wire final_result_carry_in_cla = final_result_carry_in_cla_temp[0];

  wire [15:0] CLA_result;
  cla16 add(.a(final_result_first_op_cla), .b(final_result_second_op_cla), .cin(final_result_carry_in_cla), .sum(CLA_result));
  
  /*********************************************************************************************************
  Operators that don't need CLA
  **********************************************************************************************************/
  // Math Operators (12:15 0001): MUL (3:5 001), DIV (3:5 011)
  wire [15:0] MUL = i_r1data * i_r2data;
  wire [15:0] DIV; // see mod line to see div being used

  wire [15:0] MATH_OUT;
  three_bit_selector math_out(.a0(16'h0), .a1(MUL), .a2(16'h0), .a3(DIV), .a4(16'h0),
                              .a5(16'h0), .a6(16'h0), .a7(16'h0), .sel(i_insn[5:3]), .y(MATH_OUT));
  
  // Comps (12:15 0010): CMP (7:8 00), CMPU (7:8 01), CMPI (7:8 10), CMPIU  (7:8 11)
  wire [15:0] CMP = ($signed(i_r1data) > $signed(i_r2data)) ? 16'b1:
                    ($signed(i_r1data) == $signed(i_r2data)) ? 16'b0:
                    -16'h01;

  wire [15:0] CMPU = (i_r1data > i_r2data) ? 16'b1:
                     (i_r1data == i_r2data) ? 16'b0:
                     -16'h01;

  wire [15:0] CMPI = ($signed(i_r1data) > $signed({{9{i_insn[6]}}, i_insn[6:0]})) ? 16'b1:
                     ($signed(i_r1data) == $signed({{9{i_insn[6]}}, i_insn[6:0]})) ? 16'b0 :
                     -16'h01;

  wire [15:0] CMPIU = (i_r1data > {{9{1'b0}}, i_insn[6:0]}) ? 16'b1 :
                      (i_r1data == {{9{1'b0}}, i_insn[6:0]}) ? 16'b0 :
                      -16'h01;

  wire [15:0] CMP_OUT;
  two_bit_selector comp_out(.a0(CMP), .a1(CMPU), .a2(CMPI), .a3(CMPIU), .sel(i_insn[8:7]), .y(CMP_OUT));

  // Logical Operators (12:15 0101): AND (3:5 000), NOT (3:5 001), OR (3:5 010), XOR (3:5 011), ANDI (3:5 1xx)
  wire [15:0] AND = i_r1data & i_r2data;
  wire [15:0] NOT = ~i_r1data;
  wire [15:0] OR = i_r1data | i_r2data;
  wire [15:0] XOR = i_r1data ^ i_r2data;
  wire [15:0] ANDI = i_r1data & {{11{i_insn[4]}}, i_insn[4:0]};

  wire [15:0] LOG_OUT;
  three_bit_selector log_out(.a0(AND), .a1(NOT), .a2(OR), .a3(XOR), .a4(ANDI), .a5(ANDI), .a6(ANDI), .a7(ANDI), .sel(i_insn[5:3]), .y(LOG_OUT));

  // CONST (12:15 1001)
  wire [15:0] CONST = $signed({{7{i_insn[8]}}, {i_insn[8:0]}});

  // Shift and Mod (12:15 1010): SLL (4:5 00), SRA (4:5 01), SRL (4:5 10), MOD (4:5 11)
  wire [15:0] SLL = i_r1data << i_insn[3:0];
  wire [15:0] SRA = $signed(i_r1data) >>> i_insn[3:0];
  wire [15:0] SRL = i_r1data >> i_insn[3:0];
  wire [15:0] MOD;
  lc4_divider divy(.i_dividend(i_r1data), .i_divisor(i_r2data), .o_remainder(MOD), .o_quotient(DIV));


  wire [15:0] MISC_OUT;
  two_bit_selector misc_out(.a0(SLL), .a1(SRA), .a2(SRL), .a3(MOD), .sel(i_insn[5:4]), .y(MISC_OUT));
  
  // HICONST (12:15 1101)
  wire [15:0] HICONST = (i_r1data & 16'h00FF) | (i_insn[7:0] << 8);

  // JSRR and JSR (12:15 0100)
  wire [15:0] JSRR = i_r1data;
  wire [15:0] JSR = (i_pc & 16'b1000000000000000) | (i_insn[10:0] << 4);

  wire [15:0] JSR_OUT;
  one_bit_selector jsr_out(.a0(JSRR), .a1(JSR), .sel(i_insn[11]), .y(JSR_OUT));

  // JMPR (12:15 1100, [11] 0)
  wire [15:0] JMPR = i_r1data;

  // RTI 1000
  wire [15:0] RTI = i_r1data;

  // TRAP 1111
  wire [15:0] TRAP = 16'h8000 | i_insn[7:0];

  // FINAL NO CLA OUTPUT SELECTION
  wire [15:0] final_result_no_cla;
  four_bit_selector final_no_cla_out(.a0(16'h0), .a1(MATH_OUT), .a2(CMP_OUT), .a3(16'h0), .a4(JSR_OUT), .a5(LOG_OUT), .a6(16'h0), .a7(16'h0), 
                              .a8(RTI), .a9(CONST), .a10(MISC_OUT), .a11(16'h0), .a12(JMPR), .a13(HICONST), .a14(16'h0), .a15(TRAP),
                              .sel(i_insn[15:12]), .y(final_result_no_cla));

one_bit_selector final_out(.a0(CLA_result), .a1(final_result_no_cla), .sel(final_selector), .y(o_result));

endmodule
