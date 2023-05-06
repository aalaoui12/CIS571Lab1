`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

/* 8-register, n-bit register file with
 * four read ports and two write ports
 * to support two pipes.
 * 
 * If both pipes try to write to the
 * same register, pipe B wins.
 * 
 * Inputs should be bypassed to the outputs
 * as needed so the register file returns
 * data that is written immediately
 * rather than only on the next cycle.
 */
module lc4_regfile_ss #(parameter n = 16)
   (input  wire         clk,
    input  wire         gwe,
    input  wire         rst,

    input  wire [  2:0] i_rs_A,      // pipe A: rs selector
    output wire [n-1:0] o_rs_data_A, // pipe A: rs contents
    input  wire [  2:0] i_rt_A,      // pipe A: rt selector
    output wire [n-1:0] o_rt_data_A, // pipe A: rt contents

    input  wire [  2:0] i_rs_B,      // pipe B: rs selector
    output wire [n-1:0] o_rs_data_B, // pipe B: rs contents
    input  wire [  2:0] i_rt_B,      // pipe B: rt selector
    output wire [n-1:0] o_rt_data_B, // pipe B: rt contents

    input  wire [  2:0]  i_rd_A,     // pipe A: rd selector
    input  wire [n-1:0]  i_wdata_A,  // pipe A: data to write
    input  wire          i_rd_we_A,  // pipe A: write enable

    input  wire [  2:0]  i_rd_B,     // pipe B: rd selector
    input  wire [n-1:0]  i_wdata_B,  // pipe B: data to write
    input  wire          i_rd_we_B   // pipe B: write enable
    );

   /*** TODO: Your Code Here ***/
   wire [n-1:0] output_rs_A, output_rs_B, output_rt_A, output_rt_B;

   wire [n-1:0] r0v, r1v, r2v, r3v, r4v, r5v, r6v, r7v;
   wire [n-1:0] r0_data, r1_data, r2_data, r3_data, r4_data, r5_data, r6_data, r7_data;
   wire we_0, we_1, we_2, we_3, we_4, we_5, we_6, we_7;

   assign r0_data = (i_rd_B == 3'd0 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r1_data = (i_rd_B == 3'd1 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r2_data = (i_rd_B == 3'd2 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r3_data = (i_rd_B == 3'd3 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r4_data = (i_rd_B == 3'd4 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r5_data = (i_rd_B == 3'd5 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r6_data = (i_rd_B == 3'd6 && i_rd_we_B) ? i_wdata_B : i_wdata_A;
   assign r7_data = (i_rd_B == 3'd7 && i_rd_we_B) ? i_wdata_B : i_wdata_A;

   assign we_0 = (i_rd_B == 3'd0 && i_rd_we_B) || (i_rd_A == 3'd0 && i_rd_we_A);
   assign we_1 = (i_rd_B == 3'd1 && i_rd_we_B) || (i_rd_A == 3'd1 && i_rd_we_A);
   assign we_2 = (i_rd_B == 3'd2 && i_rd_we_B) || (i_rd_A == 3'd2 && i_rd_we_A);
   assign we_3 = (i_rd_B == 3'd3 && i_rd_we_B) || (i_rd_A == 3'd3 && i_rd_we_A);
   assign we_4 = (i_rd_B == 3'd4 && i_rd_we_B) || (i_rd_A == 3'd4 && i_rd_we_A);
   assign we_5 = (i_rd_B == 3'd5 && i_rd_we_B) || (i_rd_A == 3'd5 && i_rd_we_A);
   assign we_6 = (i_rd_B == 3'd6 && i_rd_we_B) || (i_rd_A == 3'd6 && i_rd_we_A);
   assign we_7 = (i_rd_B == 3'd7 && i_rd_we_B) || (i_rd_A == 3'd7 && i_rd_we_A);

   Nbit_reg #(n) r0 (.in(r0_data), .out(r0v), .clk(clk), .we(we_0), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r1 (.in(r1_data), .out(r1v), .clk(clk), .we(we_1), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r2 (.in(r2_data), .out(r2v), .clk(clk), .we(we_2), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r3 (.in(r3_data), .out(r3v), .clk(clk), .we(we_3), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r4 (.in(r4_data), .out(r4v), .clk(clk), .we(we_4), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r5 (.in(r5_data), .out(r5v), .clk(clk), .we(we_5), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r6 (.in(r6_data), .out(r6v), .clk(clk), .we(we_6), .gwe(gwe), .rst(rst));
   Nbit_reg #(n) r7 (.in(r7_data), .out(r7v), .clk(clk), .we(we_7), .gwe(gwe), .rst(rst));

   Nbit_mux8to1 #(n) mux1 (.S(i_rs_A), .r0(r0v), .r1(r1v), .r2(r2v), .r3(r3v), .r4(r4v), .r5(r5v), .r6(r6v), .r7(r7v), .Out(output_rs_A));
   Nbit_mux8to1 #(n) mux2 (.S(i_rt_A), .r0(r0v), .r1(r1v), .r2(r2v), .r3(r3v), .r4(r4v), .r5(r5v), .r6(r6v), .r7(r7v), .Out(output_rt_A));
   Nbit_mux8to1 #(n) mux3 (.S(i_rs_B), .r0(r0v), .r1(r1v), .r2(r2v), .r3(r3v), .r4(r4v), .r5(r5v), .r6(r6v), .r7(r7v), .Out(output_rs_B));
   Nbit_mux8to1 #(n) mux4 (.S(i_rt_B), .r0(r0v), .r1(r1v), .r2(r2v), .r3(r3v), .r4(r4v), .r5(r5v), .r6(r6v), .r7(r7v), .Out(output_rt_B));

   assign o_rs_data_A = (i_rs_A == i_rd_B && i_rd_we_B == 1'd1) ? i_wdata_B :
                        (i_rs_A == i_rd_A && i_rd_we_A == 1'd1) ? i_wdata_A : output_rs_A;
   assign o_rt_data_A = (i_rt_A == i_rd_B && i_rd_we_B == 1'd1) ? i_wdata_B :
                        (i_rt_A == i_rd_A && i_rd_we_A == 1'd1) ? i_wdata_A : output_rt_A;
   assign o_rs_data_B = (i_rs_B == i_rd_B && i_rd_we_B == 1'd1) ? i_wdata_B :
                        (i_rs_B == i_rd_A && i_rd_we_A == 1'd1) ? i_wdata_A : output_rs_B;
   assign o_rt_data_B = (i_rt_B == i_rd_B && i_rd_we_B == 1'd1) ? i_wdata_B :
                        (i_rt_B == i_rd_A && i_rd_we_A == 1'd1) ? i_wdata_A : output_rt_B;

endmodule

module Nbit_mux8to1 #(parameter n=16)
    (input wire [2:0] S,
    input wire [n-1:0] r0,
    input wire [n-1:0] r1,
    input wire [n-1:0] r2,
    input wire [n-1:0] r3,
    input wire [n-1:0] r4,
    input wire [n-1:0] r5,
    input wire [n-1:0] r6,
    input wire [n-1:0] r7,
    output wire [n-1:0] Out
    );

    assign Out = (S == 3'b000) ? r0 :
                 (S == 3'b001) ? r1 :
                 (S == 3'b010) ? r2 :
                 (S == 3'b011) ? r3 :
                 (S == 3'b100) ? r4 :
                 (S == 3'b101) ? r5 :
                 (S == 3'b110) ? r6 : r7;
endmodule
