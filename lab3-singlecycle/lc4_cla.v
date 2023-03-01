/* TODO: INSERT NAME AND PENNKEY HERE */

`timescale 1ns / 1ps
`default_nettype none

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(input wire a, b,
           output wire g, p);
  assign g = a & b;
  assign p = a | b;
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals 
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits collectively generate a carry (ignoring cin)
 * @param pout whether these 4 bits collectively would propagate an incoming carry (ignoring cin)
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(input wire [3:0] gin, pin,
           input wire cin,
           output wire gout, pout,
           output wire [2:0] cout);

  assign cout[0] = (cin & pin[0]) | gin[0];
  assign cout[1] = (cout[0] & pin[1]) | gin[1];
  assign cout[2] = (cout[1] & pin[2]) | gin[2];
  assign pout = pin[0] & pin[1] & pin[2] & pin[3];
  assign gout = gin[3] | (gin[2] & pin[3]) | (gin[1] & pin[2] & pin[3]) | (gin[0] & pin[1] & pin[2] & pin[3]);
endmodule

/**
 * 16-bit Carry-Lookahead Adder
 * @param a first input
 * @param b second input
 * @param cin carry in
 * @param sum sum of a + b + carry-in
 */
module cla16
  (input wire [15:0]  a, b,
   input wire         cin,
   output wire [15:0] sum);

  wire [15:0] gin, pin;
  wire gout1, gout2, gout3, gout4, pout1, pout2, pout3, pout4;
  wire [15:0] carry;

  genvar i;
  for (i = 0; i < 16; i = i+1) begin
    gp1 gbit(.a(a[i]), .b(b[i]), .g(gin[i]), .p(pin[i]));
  end

  assign carry[0] = cin;
  gpn one(.gin(gin[3:0]), .pin(pin[3:0]), .cin(cin), .gout(gout1), .pout(pout1), .cout(carry[3:1]));
  assign carry[4] = gout1 | pout1 & cin;
  gpn two(.gin(gin[7:4]), .pin(pin[7:4]), .cin(carry[4]), .gout(gout2), .pout(pout2), .cout(carry[7:5]));
  assign carry[8] = gout2 | pout2 & carry[4];
  gpn three(.gin(gin[11:8]), .pin(pin[11:8]), .cin(carry[8]), .gout(gout3), .pout(pout3), .cout(carry[11:9]));
  assign carry[12] = gout3 | pout3 & carry[8];
  gpn four(.gin(gin[15:12]), .pin(pin[15:12]), .cin(carry[12]), .gout(gout4), .pout(pout4), .cout(carry[15:13]));

  assign sum = a^ b ^ carry;
endmodule


/** Lab 2 Extra Credit, see details at
  https://github.com/upenn-acg/cis501/blob/master/lab2-alu/lab2-cla.md#extra-credit
 If you are not doing the extra credit, you should leave this module empty.
 */
module gpn
  #(parameter N = 4)
  (input wire [N-1:0] gin, pin,
   input wire  cin,
   output wire gout, pout,
   output wire [N-2:0] cout);
  
  assign cout[0] = (cin & pin[0]) | gin[0];
  genvar i;
  for (i = 1; i < N-1; i = i+1) begin
    assign cout[i] = (cout[i-1] & pin[i]) | gin[i];
  end

  genvar j;
  wire [N-1:0] pout_agg;
  assign pout_agg[0] = pin[0];
  for (j = 1; j < N; j = j+1) begin
    assign pout_agg[j] = pout_agg[j-1] & pin[j];
  end
  assign pout = pout_agg[N-1];

  wire [2*N-2:0] pin_padded;
  genvar k;
  for (k = 0; k < 2*N-1; k = k+1) begin
    assign pin_padded[k] = (k < N) ? pin[k] : 1;
  end

  genvar m;
  genvar pin_i;
  wire [N-1:0] gout_agg;
  for (m = 0; m < N; m = m + 1) begin
    wire [N-1:0] agg_pin;
    assign agg_pin[0] = 1;
    for (pin_i = 1; pin_i < N; pin_i = pin_i + 1) begin
      assign agg_pin[pin_i] = agg_pin[pin_i-1] & pin_padded[pin_i+m];
    end
    assign gout_agg[m] = (m == 0) ? 0 | (gin[m] & agg_pin[N-1]) : gout_agg[m-1] | (gin[m] & agg_pin[N-1]);
  end
  assign gout = gout_agg[N-1];
endmodule
