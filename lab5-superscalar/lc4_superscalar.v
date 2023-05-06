`timescale 1ns / 1ps

// Prevent implicit wire declaration
`default_nettype none

module lc4_processor(input wire         clk,             // main clock
                     input wire         rst,             // global reset
                     input wire         gwe,             // global we for single-step clock

                     output wire [15:0] o_cur_pc,        // address to read from instruction memory
                     input wire [15:0]  i_cur_insn_A,    // output of instruction memory (pipe A)
                     input wire [15:0]  i_cur_insn_B,    // output of instruction memory (pipe B)

                     output wire [15:0] o_dmem_addr,     // address to read/write from/to data memory
                     input wire [15:0]  i_cur_dmem_data, // contents of o_dmem_addr
                     output wire        o_dmem_we,       // data memory write enable
                     output wire [15:0] o_dmem_towrite,  // data to write to o_dmem_addr if we is set

                     // testbench signals (always emitted from the WB stage)
                     output wire [ 1:0] test_stall_A,        // is this a stall cycle?  (0: no stall,
                     output wire [ 1:0] test_stall_B,        // 1: pipeline stall, 2: branch stall, 3: load stall)

                     output wire [15:0] test_cur_pc_A,       // program counter
                     output wire [15:0] test_cur_pc_B,
                     output wire [15:0] test_cur_insn_A,     // instruction bits
                     output wire [15:0] test_cur_insn_B,
                     output wire        test_regfile_we_A,   // register file write-enable
                     output wire        test_regfile_we_B,
                     output wire [ 2:0] test_regfile_wsel_A, // which register to write
                     output wire [ 2:0] test_regfile_wsel_B,
                     output wire [15:0] test_regfile_data_A, // data to write to register file
                     output wire [15:0] test_regfile_data_B,
                     output wire        test_nzp_we_A,       // nzp register write enable
                     output wire        test_nzp_we_B,
                     output wire [ 2:0] test_nzp_new_bits_A, // new nzp bits
                     output wire [ 2:0] test_nzp_new_bits_B,
                     output wire        test_dmem_we_A,      // data memory write enable
                     output wire        test_dmem_we_B,
                     output wire [15:0] test_dmem_addr_A,    // address to read/write from/to memory
                     output wire [15:0] test_dmem_addr_B,
                     output wire [15:0] test_dmem_data_A,    // data to read/write from/to memory
                     output wire [15:0] test_dmem_data_B,

                     // zedboard switches/display/leds (ignore if you don't want to control these)
                     input  wire [ 7:0] switch_data,         // read on/off status of zedboard's 8 switches
                     output wire [ 7:0] led_data             // set on/off status of zedboard's 8 leds
                     );

   /***  YOUR CODE HERE ***/

   // FETCH stage
   assign led_data = switch_data;
   wire [15:0] pc, next_pc;
   wire [15:0] f_insn_A, f_insn_B;
   wire [15:0] f_pc_A, f_pc_B, f_pc_B_intermediate;

   wire pc_we = should_stall_A == 3 ? 0 : 1; 
   Nbit_reg #(16, 16'h8200) pc_reg (.in(next_pc), .out(pc), .clk(clk), .we(pc_we), .gwe(gwe), .rst(rst)); // only need one PC reg
   assign o_cur_pc = pc;
   
   assign f_insn_A = i_cur_insn_A;
   assign f_insn_B = (should_stall_B > 0 && should_stall_A == 0) ? i_cur_insn_A : i_cur_insn_B;
   assign f_pc_A = pc;
   cla16 incrementor_B(.a(pc), .b(16'd0), .cin(1'b1), .sum(f_pc_B_intermediate));
   assign f_pc_B = (should_stall_B > 0 && should_stall_A == 0) ? f_pc_A : f_pc_B_intermediate;
   wire [31:0] d_reg_in_A = {f_pc_A, f_insn_A};
   wire [31:0] d_reg_in_B = {f_pc_B, f_insn_B};

   // DECODE wire declarations
   wire [31:0] d_reg_out_A, d_reg_out_B;
   wire [15:0] d_i_cur_insn_A, d_i_cur_insn_B, d_pc_A, d_pc_B, o_rt_data_A, o_rt_data_B, o_rs_data_A, o_rs_data_B;
   wire [2:0] r1sel_A, r2sel_A, d_regfile_wsel_A, r1sel_B, r2sel_B, d_regfile_wsel_B;
   wire [1:0] should_stall_A, should_stall_B;
   wire r1re_A, r2re_A, d_regfile_we_A, d_nzp_we_A, select_pc_plus_one_A, is_load_A, is_store_A, is_branch_A, is_control_insn_A, 
        d_reg_we_A, d_regfile_we_final_A, r1re_B, r2re_B, d_regfile_we_B, d_nzp_we_B, select_pc_plus_one_B, is_load_B, is_store_B,
        is_branch_B, is_control_insn_B, d_reg_we_B, d_regfile_we_final_B;
     
   wire [1:0] d_pc_addone; // this is to keep track of how much to increment PC by

   wire [83:0] x_reg_in_A, x_reg_in_val_A, x_reg_in_B, x_reg_in_val_B;

   // EXECUTE wire declarations
   wire [83:0] x_reg_out_A, x_reg_out_B;
   wire [1:0] x_stall_A, x_stall_B;
   wire [2:0] x_r1sel_A, x_r2sel_A, x_regfile_wsel_A, x_r1sel_B, x_r2sel_B, x_regfile_wsel_B;
   wire x_r1re_A, x_r2re_A, x_nzp_we_A, x_select_pc_plus_one_A, x_is_load_A, x_is_store_A, x_is_branch_A, x_is_control_insn_A, 
        x_regfile_we_A, x_r1re_B, x_r2re_B, x_nzp_we_B, x_select_pc_plus_one_B, x_is_load_B, x_is_store_B, x_is_branch_B, 
        x_is_control_insn_B, x_regfile_we_B;
   wire [15:0] x_pc_A, x_o_rt_data_A, x_o_rs_data_A, x_i_cur_insn_A, x_o_rt_data_final_A, x_o_rs_data_final_A, alu_output_A,
               x_pc_B, x_o_rt_data_B, x_o_rs_data_B, x_i_cur_insn_B, x_o_rt_data_final_B, x_o_rs_data_final_B, alu_output_B;
   wire [99:0] m_reg_in_A, m_reg_in_B;

   wire [1:0] x_pc_addone;

   // MEMORY wire declarations
   wire [99:0] m_reg_out_A, m_reg_out_B;
   wire m_regfile_we_A, m_r1re_A, m_r2re_A, m_nzp_we_A, m_select_pc_plus_one_A, m_is_store_A, m_is_load_A, m_is_branch_A, m_is_control_insn_A,
        m_regfile_we_B, m_r1re_B, m_r2re_B, m_nzp_we_B, m_select_pc_plus_one_B, m_is_store_B, m_is_load_B, m_is_branch_B, m_is_control_insn_B;
   wire [1:0] m_stall_A, m_stall_B;
   wire [2:0] m_regfile_wsel_A, m_r1sel_A, m_r2sel_A, m_regfile_wsel_B, m_r1sel_B, m_r2sel_B;
   wire [15:0] m_pc_A, m_o_rt_data_A, m_o_rs_data_A, m_i_cur_insn_A, m_alu_output_A, m_o_rt_data_final_A,
               m_pc_B, m_o_rt_data_B, m_o_rs_data_B, m_i_cur_insn_B, m_alu_output_B, m_o_rt_data_final_B;
   wire [148:0] w_reg_in_A, w_reg_in_B;

   wire [1:0] m_pc_addone;

   // WRITEBACK wire declarations
   wire [148:0] w_reg_out_A, w_reg_out_B;
   wire w_r1re_A, w_r2re_A, w_nzp_we_A, w_select_pc_plus_one_A, w_is_store_A, w_is_load_A, w_is_branch_A, w_is_control_insn_A,
        w_r1re_B, w_r2re_B, w_nzp_we_B, w_select_pc_plus_one_B, w_is_store_B, w_is_load_B, w_is_branch_B, w_is_control_insn_B;
   wire [2:0] w_r1sel_A, w_r2sel_A, new_nzp_A, w_r1sel_B, w_r2sel_B, new_nzp_B;
   wire [15:0] w_o_rt_data_A, w_i_cur_insn_A, w_alu_output_A, w_pc_A, w_o_rs_data_A, pc_addone_A, w_o_dmem_towrite_A, 
               w_pc_addone_A, w_i_cur_dmem_data_A, w_o_rt_data_B, w_i_cur_insn_B, w_alu_output_B, w_pc_B, w_o_rs_data_B, 
               pc_addone_B, w_o_dmem_towrite_B, w_pc_addone_B, w_i_cur_dmem_data_B;

   wire [1:0] w_pc_addone;

   // Bypasses
   // TO DO: add MM bypass between pipes A and B
   wire wm_bypass_A = ((m_r2sel_A == test_regfile_wsel_A) && m_is_store_A && test_regfile_we_A) ? 1 : 0;
   wire wm_bypass_B = ((m_r2sel_B == test_regfile_wsel_B) && m_is_store_B && test_regfile_we_B) ? 1 : 0;
   wire wx_bypass1_A = ((x_r1sel_A == test_regfile_wsel_A) && x_r1re_A && test_regfile_we_A) ? 1 : 0;
   wire wx_bypass1_B = ((x_r1sel_B == test_regfile_wsel_B) && x_r1re_B && test_regfile_we_B) ? 1 : 0;
   wire wx_bypass2_A = ((x_r2sel_A == test_regfile_wsel_A) && x_r2re_A && test_regfile_we_A) ? 1 : 0;
   wire wx_bypass2_B = ((x_r2sel_B == test_regfile_wsel_B) && x_r2re_B && test_regfile_we_B) ? 1 : 0;
   wire mx_bypass1_A = ((x_r1sel_A == m_regfile_wsel_A) && x_r1re_A && m_regfile_we_A) ? 1 : 0;
   wire mx_bypass1_B = ((x_r1sel_B == m_regfile_wsel_B) && x_r1re_B && m_regfile_we_B) ? 1 : 0;
   wire mx_bypass2_A = ((x_r2sel_A == m_regfile_wsel_A) && x_r2re_A && m_regfile_we_A) ? 1 : 0;
   wire mx_bypass2_B = ((x_r2sel_B == m_regfile_wsel_B) && x_r2re_B && m_regfile_we_B) ? 1 : 0;

   // Stall Logic
   wire [2:0] x_nzp_new_bits_A = (x_i_cur_insn_A[15:12] == 4'b0010) ? (($signed(alu_output_A) > 0) ? 3'b001 : ($signed(alu_output_A) == 0) ? 3'b010 : 3'b100)
   : (($signed(alu_output_A) > 0) ? 3'b001 : ($signed(alu_output_A) == 0) ? 3'b010 : 3'b100);
   wire [2:0] x_new_nzp_A;
   Nbit_reg #(3) x_nzp_reg_A(.in(x_nzp_new_bits_A), .out(x_new_nzp_A), .clk(clk), .we(x_nzp_we_A), .gwe(gwe), .rst(rst));
   wire did_branch_A = x_i_cur_insn_A[15:9] == 7'b0000111 | 
                           (x_i_cur_insn_A[15:9] == 7'b0000001 & x_new_nzp_A == 3'b001) | 
                           (x_i_cur_insn_A[15:9] == 7'b0000010 & x_new_nzp_A == 3'b010) |
                           (x_i_cur_insn_A[15:9] == 7'b0000100 & x_new_nzp_A == 3'b100) | 
                           (x_i_cur_insn_A[15:9] == 7'b0000011 & (x_new_nzp_A == 3'b001 | x_new_nzp_A == 3'b010)) |
                           (x_i_cur_insn_A[15:9] == 7'b0000101 & (x_new_nzp_A == 3'b100 | x_new_nzp_A == 3'b001)) |
                           (x_i_cur_insn_A[15:9] == 7'b0000110 & (x_new_nzp_A == 3'b100 | x_new_nzp_A == 3'b010));

   wire [2:0] x_nzp_new_bits_B = (x_i_cur_insn_B[15:12] == 4'b0010) ? (($signed(alu_output_B) > 0) ? 3'b001 : ($signed(alu_output_B) == 0) ? 3'b010 : 3'b100)
   : (($signed(alu_output_B) > 0) ? 3'b001 : ($signed(alu_output_B) == 0) ? 3'b010 : 3'b100);
   wire [2:0] x_new_nzp_B;
   Nbit_reg #(3) x_nzp_reg_B(.in(x_nzp_new_bits_B), .out(x_new_nzp_B), .clk(clk), .we(x_nzp_we_B), .gwe(gwe), .rst(rst));
   wire did_branch_B = x_i_cur_insn_B[15:9] == 7'b0000111 | 
                           (x_i_cur_insn_B[15:9] == 7'b0000001 & x_new_nzp_B == 3'b001) | 
                           (x_i_cur_insn_B[15:9] == 7'b0000010 & x_new_nzp_B == 3'b010) |
                           (x_i_cur_insn_B[15:9] == 7'b0000100 & x_new_nzp_B == 3'b100) | 
                           (x_i_cur_insn_B[15:9] == 7'b0000011 & (x_new_nzp_B == 3'b001 | x_new_nzp_B == 3'b010)) |
                           (x_i_cur_insn_B[15:9] == 7'b0000101 & (x_new_nzp_B == 3'b100 | x_new_nzp_B == 3'b001)) |
                           (x_i_cur_insn_B[15:9] == 7'b0000110 & (x_new_nzp_B == 3'b100 | x_new_nzp_B == 3'b010));
                           
   // if either pipe is mispredicted, both need to be flushed
   wire should_flush = (x_is_control_insn_A || x_is_control_insn_B ||  (x_is_branch_A && did_branch_A) || (x_is_branch_B && did_branch_B));
   wire [1:0] f_stall = should_flush ? 2 : 0;

   // TO DO: logic for if is_branch_A and x_is_load_B (?)
   // TO DO: implement structural hazards
   // remember: can't have a load and store at same time. watch out for !is_store
   wire is_data_hazard_A = ((is_branch_A && x_is_load_A) || (x_is_load_A && (((r1sel_A == x_regfile_wsel_A) && r1re_A && x_regfile_we_A) || 
                           (((r2sel_A == x_regfile_wsel_A) && r2re_A && x_regfile_we_A) && !is_store_A))) || 
                           (x_is_load_B && (((r1sel_A == x_regfile_wsel_B) && r1re_A && x_regfile_we_B) || 
                           (((r2sel_A == x_regfile_wsel_B) && r2re_A && x_regfile_we_B) && !is_store_A))));
   wire is_data_hazard_B = ((is_branch_B && x_is_load_B) || (x_is_load_B && (((r1sel_B == x_regfile_wsel_B) && r1re_B && x_regfile_we_B) || 
                           (((r2sel_B == x_regfile_wsel_B) && r2re_B && x_regfile_we_B) && !is_store_B))) || 
                           (x_is_load_B && (((r1sel_B == x_regfile_wsel_A) && r1re_B && x_regfile_we_A) || 
                           (((r2sel_B == x_regfile_wsel_A) && r2re_B && x_regfile_we_A) && !is_store_B))));
   
   // a flag if B requires A or both are load/memory
   wire superscalar_stall = (r1sel_B == d_regfile_wsel_A && r1re_B && d_regfile_we_A) || (r2sel_B == d_regfile_wsel_A && r2re_B && d_regfile_we_A) ||
                            ((is_load_A || is_store_A) && (is_load_B || is_store_B));


   // DECODE stage
   assign d_reg_we_A = should_stall_A == 3 ? 0 : 1;
   assign d_reg_we_B = should_stall_B == 3 ? 0 : 1;
   wire [1:0] should_stall_middle;

   Nbit_reg #(32, 32'b0) decoder_reg_A (.in(d_reg_in_A), .out(d_reg_out_A), .clk(clk), .we(d_reg_we_A), .gwe(gwe), .rst(rst));
   Nbit_reg #(32, 32'b0) decoder_reg_B (.in(d_reg_in_B), .out(d_reg_out_B), .clk(clk), .we(d_reg_we_B), .gwe(gwe), .rst(rst));

   Nbit_reg #(2, 2) f_stall_reg (.in(f_stall), .out(should_stall_middle), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default. need for pipe B  
   
   assign should_stall_A = (should_flush) ? 2 : is_data_hazard_A ? 3 : should_stall_middle;
   assign should_stall_B = (should_flush) ? 2 : (is_data_hazard_A || superscalar_stall) ? 1 : is_data_hazard_B ? 3 : should_stall_middle;
   assign d_pc_A = d_reg_out_A[31:16];
   assign d_pc_B = d_reg_out_B[31:16];
   assign d_i_cur_insn_A = d_reg_out_A[15:0];
   assign d_i_cur_insn_B = d_reg_out_B[15:0];

   lc4_decoder decoder_A(.insn(d_i_cur_insn_A), .r1sel(r1sel_A), .r1re(r1re_A), .r2sel(r2sel_A), .r2re(r2re_A),
                         .wsel(d_regfile_wsel_A), .regfile_we(d_regfile_we_A), .nzp_we(d_nzp_we_A),
                         .select_pc_plus_one(select_pc_plus_one_A), .is_load(is_load_A), .is_store(is_store_A),
                         .is_branch(is_branch_A), .is_control_insn(is_control_insn_A));
   lc4_decoder decoder_B(.insn(d_i_cur_insn_B), .r1sel(r1sel_B), .r1re(r1re_B), .r2sel(r2sel_B), .r2re(r2re_B),
                         .wsel(d_regfile_wsel_B), .regfile_we(d_regfile_we_B), .nzp_we(d_nzp_we_B),
                         .select_pc_plus_one(select_pc_plus_one_B), .is_load(is_load_B), .is_store(is_store_B),
                         .is_branch(is_branch_B), .is_control_insn(is_control_insn_B));

   lc4_regfile_ss regfile(.clk(clk), .gwe(gwe), .rst(rst),
                          .i_rs_A(r1sel_A), .o_rs_data_A(o_rs_data_A), .i_rt_A(r2sel_A), .o_rt_data_A(o_rt_data_A),
                          .i_rs_B(r1sel_B), .o_rs_data_B(o_rs_data_B), .i_rt_B(r2sel_B), .o_rt_data_B(o_rt_data_B),
                          .i_rd_A(test_regfile_wsel_A), .i_wdata_A(test_regfile_data_A), .i_rd_we_A(test_regfile_we_A && test_stall_A == 0),
                          .i_rd_B(test_regfile_wsel_B), .i_wdata_B(test_regfile_data_B), .i_rd_we_B(test_regfile_we_B && test_stall_B == 0));

   // no WD bypass above because already implemented in register file
   assign d_regfile_we_final_A = (should_stall_A > 1) ? 0 : d_regfile_we_A;
   assign d_regfile_we_final_B = (should_stall_B > 1) ? 0 : d_regfile_we_B;

   assign d_pc_addone = should_stall_A ? 2'd0 : should_stall_B ? 2'd1 : 2'd2;
   // ASSIGN PC HERE
   /*
   cla16 incrementor_A(.a(pc), .b(16'b0), .cin(1'b1), .sum(pc_addone_A));
   cla16 incrementor2_A(.a(w_pc_A), .b(16'b0), .cin(1'b1), .sum(w_pc_addone_A));

   cla16 incrementor_B(.a(pc), .b(16'b0), .cin(2'd2), .sum(pc_addone_B));
   cla16 incrementor2_B(.a(w_pc_B), .b(16'b0), .cin(2'd2), .sum(w_pc_addone_B));

   assign next_pc = (x_is_control_insn_B || (x_is_branch_B && did_branch_B)) ? alu_output_B : pc_addone_B; // depends on 2nd INSN
   */
   // cla16 incrementor_A_new(.a(d_reg_out_A[31:16]), .b(16'b0), .cin(d_pc_addone_A), .sum(d_pc_A));

   // cla16 incrementor_new_pc(.a(d_reg_out_A[31:16]), .b(16'b0), .cin(d_pc_addone_A), .sum(d_new_pc));

   // assign next_pc = (x_is_control_insn_B || (x_is_branch_B && did_branch_B)) ? alu_output_B : d_new_pc; // depends on 2nd INSN

   // OUTPUT TO EXECUTE
   assign x_reg_in_val_A = {d_pc_addone, r1sel_A, r1re_A, r2sel_A, r2re_A, d_regfile_we_final_A, d_regfile_wsel_A, o_rs_data_A, 
                            o_rt_data_A, d_nzp_we_A, select_pc_plus_one_A, is_load_A, is_store_A, is_branch_A, 
                            is_control_insn_A, d_i_cur_insn_A, d_pc_A};
   assign x_reg_in_A = (should_stall_A > 1) ? 98'b0 : x_reg_in_val_A;
   assign x_reg_in_val_B = {d_pc_addone, r1sel_B, r1re_B, r2sel_B, r2re_B, d_regfile_we_final_B, d_regfile_wsel_B, o_rs_data_B, 
                            o_rt_data_B, d_nzp_we_B, select_pc_plus_one_B, is_load_B, is_store_B, is_branch_B, 
                            is_control_insn_B, d_i_cur_insn_B, d_pc_B};
   assign x_reg_in_B = (should_stall_B > 0) ? 98'b0 : x_reg_in_val_B;


   // EXECUTE Implementation
   Nbit_reg #(84, 84'b0) execute_reg_A (.in(x_reg_in_A), .out(x_reg_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) should_stall_reg_A (.in(should_stall_A), .out(x_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default
   assign x_pc_addone = x_reg_out_A[83:82];
   assign x_r1sel_A = x_reg_out_A[81:79];
   assign x_r1re_A = x_reg_out_A[78];
   assign x_r2sel_A = x_reg_out_A[77:75];
   assign x_r2re_A = x_reg_out_A[74];
   assign x_regfile_we_A = x_reg_out_A[73];
   assign x_regfile_wsel_A = x_reg_out_A[72:70];
   assign x_o_rs_data_A = x_reg_out_A[69:54];
   assign x_o_rt_data_A = x_reg_out_A[53:38];
   assign x_nzp_we_A = x_reg_out_A[37];
   assign x_select_pc_plus_one_A = x_reg_out_A[36];
   assign x_is_load_A = x_reg_out_A[35];
   assign x_is_store_A = x_reg_out_A[34];
   assign x_is_branch_A = x_reg_out_A[33];
   assign x_is_control_insn_A = x_reg_out_A[32];
   assign x_i_cur_insn_A = x_reg_out_A[31:16];
   assign x_pc_A = x_reg_out_A[15:0];
   assign x_o_rs_data_final_A = mx_bypass1_A ? m_alu_output_A : ((wx_bypass1_A) ? test_regfile_data_A : x_o_rs_data_A);
   assign x_o_rt_data_final_A = mx_bypass2_A ? m_alu_output_A : ((wx_bypass2_A) ? test_regfile_data_A : x_o_rt_data_A);
   lc4_alu alu_A (.i_insn(x_i_cur_insn_A), .i_pc(x_pc_A), .i_r1data(x_o_rs_data_final_A), .i_r2data(x_o_rt_data_final_A), .o_result(alu_output_A));
   assign m_reg_in_A = {x_pc_addone, x_r1sel_A, x_r1re_A, x_r2sel_A, x_r2re_A, x_regfile_we_A, x_regfile_wsel_A, x_o_rs_data_final_A, x_o_rt_data_final_A,
                      x_nzp_we_A, x_select_pc_plus_one_A, x_is_load_A, x_is_store_A, x_is_branch_A, x_is_control_insn_A, x_i_cur_insn_A, x_pc_A, alu_output_A};

   Nbit_reg #(82, 82'b0) execute_reg_B (.in(x_reg_in_B), .out(x_reg_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) should_stall_reg_B (.in(should_stall_B), .out(x_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default
   assign x_r1sel_B = x_reg_out_B[81:79];
   assign x_r1re_B = x_reg_out_B[78];
   assign x_r2sel_B = x_reg_out_B[77:75];
   assign x_r2re_B = x_reg_out_B[74];
   assign x_regfile_we_B = x_reg_out_B[73];
   assign x_regfile_wsel_B = x_reg_out_B[72:70];
   assign x_o_rs_data_B = x_reg_out_B[69:54];
   assign x_o_rt_data_B = x_reg_out_B[53:38];
   assign x_nzp_we_B = x_reg_out_B[37];
   assign x_select_pc_plus_one_B = x_reg_out_B[36];
   assign x_is_load_B = x_reg_out_B[35];
   assign x_is_store_B = x_reg_out_B[34];
   assign x_is_branch_B = x_reg_out_B[33];
   assign x_is_control_insn_B = x_reg_out_B[32];
   assign x_i_cur_insn_B = x_reg_out_B[31:16];
   assign x_pc_B = x_reg_out_B[15:0];
   assign x_o_rs_data_final_B = mx_bypass1_B ? m_alu_output_B : ((wx_bypass1_B) ? test_regfile_data_B : x_o_rs_data_B);
   assign x_o_rt_data_final_B = mx_bypass2_B ? m_alu_output_B : ((wx_bypass2_B) ? test_regfile_data_B : x_o_rt_data_B);
   lc4_alu alu_B (.i_insn(x_i_cur_insn_B), .i_pc(x_pc_B), .i_r1data(x_o_rs_data_final_B), .i_r2data(x_o_rt_data_final_B), .o_result(alu_output_B));
   assign m_reg_in_B = {x_pc_addone, x_r1sel_B, x_r1re_B, x_r2sel_B, x_r2re_B, x_regfile_we_B, x_regfile_wsel_B, x_o_rs_data_final_B, x_o_rt_data_final_B,
                      x_nzp_we_B, x_select_pc_plus_one_B, x_is_load_B, x_is_store_B, x_is_branch_B, x_is_control_insn_B, x_i_cur_insn_B, x_pc_B, alu_output_B};
   
   // MEMORY Implementation
   Nbit_reg #(100, 100'b0) memory_reg_A (.in(m_reg_in_A), .out(m_reg_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) m_stall_reg_A (.in(x_stall_A), .out(m_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default
   Nbit_reg #(100, 100'b0) memory_reg_B (.in(m_reg_in_B), .out(m_reg_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) m_stall_reg_B (.in(x_stall_B), .out(m_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default
   
   assign m_pc_addone = m_reg_out_A[99:98];
   assign m_r1sel_A = m_reg_out_A[97:95];
   assign m_r1re_A = m_reg_out_A[94];
   assign m_r2sel_A = m_reg_out_A[93:91];
   assign m_r2re_A = m_reg_out_A[90];
   assign m_regfile_we_A = m_reg_out_A[89];
   assign m_regfile_wsel_A = m_reg_out_A[88:86];
   assign m_o_rs_data_A = m_reg_out_A[85:70];
   assign m_o_rt_data_A = m_reg_out_A[69:54];
   assign m_nzp_we_A = m_reg_out_A[53];
   assign m_select_pc_plus_one_A = m_reg_out_A[52];
   assign m_is_load_A = m_reg_out_A[51];
   assign m_is_store_A = m_reg_out_A[50];
   assign m_is_branch_A = m_reg_out_A[49];
   assign m_is_control_insn_A = m_reg_out_A[48];
   assign m_i_cur_insn_A = m_reg_out_A[47:32];
   assign m_pc_A = m_reg_out_A[31:16];
   assign m_alu_output_A = m_reg_out_A[15:0];

   assign m_r1sel_B = m_reg_out_B[97:95];
   assign m_r1re_B = m_reg_out_B[94];
   assign m_r2sel_B = m_reg_out_B[93:91];
   assign m_r2re_B = m_reg_out_B[90];
   assign m_regfile_we_B = m_reg_out_B[89];
   assign m_regfile_wsel_B = m_reg_out_B[88:86];
   assign m_o_rs_data_B = m_reg_out_B[85:70];
   assign m_o_rt_data_B = m_reg_out_B[69:54];
   assign m_nzp_we_B = m_reg_out_B[53];
   assign m_select_pc_plus_one_B = m_reg_out_B[52];
   assign m_is_load_B = m_reg_out_B[51];
   assign m_is_store_B = m_reg_out_B[50];
   assign m_is_branch_B = m_reg_out_B[49];
   assign m_is_control_insn_B = m_reg_out_B[48];
   assign m_i_cur_insn_B = m_reg_out_B[47:32];
   assign m_pc_B = m_reg_out_B[31:16];
   assign m_alu_output_B = m_reg_out_B[15:0];

   // TO DO: revisit this logic - is key for non-ALU operations. need to have logic for when both pipes loading/storing and LTU dependences
   // all logic until writeback implementation
   assign o_dmem_addr = (m_is_load_A | m_is_store_A | m_is_load_B | m_is_store_B) ? m_alu_output_A : 0;
   assign o_dmem_we = m_is_store_A | m_is_store_B;
   assign o_dmem_towrite = m_is_store_A ? m_o_rt_data_final_A : m_is_store_B ? m_o_rt_data_final_B : 0;
   assign m_o_rt_data_final_A = wm_bypass_A ? test_regfile_data_A : m_o_rt_data_A;
   assign m_o_rt_data_final_B = wm_bypass_B ? test_regfile_data_B : m_o_rt_data_B;

   assign w_reg_in_A = {m_pc_addone, i_cur_dmem_data, o_dmem_addr, o_dmem_we, o_dmem_towrite, m_r1sel_A, m_r1re_A, m_r2sel_A, m_r2re_A, 
                        m_regfile_we_A, m_regfile_wsel_A, m_o_rs_data_A, m_o_rt_data_A, m_nzp_we_A, m_select_pc_plus_one_A, m_is_load_A, 
                        m_is_store_A, m_is_branch_A, m_is_control_insn_A, m_i_cur_insn_A, m_pc_A, m_alu_output_A};

   assign w_reg_in_B = {m_pc_addone, i_cur_dmem_data, o_dmem_addr, o_dmem_we, o_dmem_towrite, m_r1sel_B, m_r1re_B, m_r2sel_B, m_r2re_B, 
                        m_regfile_we_B, m_regfile_wsel_B, m_o_rs_data_B, m_o_rt_data_B, m_nzp_we_B, m_select_pc_plus_one_B, m_is_load_B, 
                        m_is_store_B, m_is_branch_B, m_is_control_insn_B, m_i_cur_insn_B, m_pc_B, m_alu_output_B};

   // WRITEBACK Implementation
   Nbit_reg #(149, 149'b0) writeback_reg_A (.in(w_reg_in_A), .out(w_reg_out_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) test_stall_reg_A (.in(m_stall_A), .out(test_stall_A), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default
   Nbit_reg #(149, 149'b0) writeback_reg_B (.in(w_reg_in_B), .out(w_reg_out_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
   Nbit_reg #(2, 2) test_stall_reg_B (.in(m_stall_B), .out(test_stall_B), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst)); // Set = 2 by default

   assign w_pc_addone = w_reg_out_A[148:147];
   assign w_i_cur_dmem_data_A = w_reg_out_A[146:131];
   assign test_dmem_addr_A = w_reg_out_A[130:115];
   assign test_dmem_we_A = w_reg_out_A[114];
   assign w_o_dmem_towrite_A = w_reg_out_A[113:98];
   assign w_r1sel_A = w_reg_out_A[97:95];
   assign w_r1re_A = w_reg_out_A[94];
   assign w_r2sel_A = w_reg_out_A[93:91];
   assign w_r2re_A = w_reg_out_A[90];
   assign test_regfile_we_A = w_reg_out_A[89];
   assign test_regfile_wsel_A = w_reg_out_A[88:86];
   assign w_o_rs_data_A = w_reg_out_A[85:70];
   assign w_o_rt_data_A = w_reg_out_A[69:54];
   assign test_nzp_we_A = w_reg_out_A[53];
   assign w_select_pc_plus_one_A = w_reg_out_A[52];
   assign w_is_load_A = w_reg_out_A[51];
   assign w_is_store_A = w_reg_out_A[50];
   assign w_is_branch_A = w_reg_out_A[49];
   assign w_is_control_insn_A = w_reg_out_A[48];
   assign w_i_cur_insn_A = w_reg_out_A[47:32];
   assign w_pc_A = w_reg_out_A[31:16];
   assign w_alu_output_A = w_reg_out_A[15:0];

   assign w_i_cur_dmem_data_B = w_reg_out_B[146:131];
   assign test_dmem_addr_B = w_reg_out_B[130:115];
   assign test_dmem_we_B = w_reg_out_B[114];
   assign w_o_dmem_towrite_B = w_reg_out_B[113:98];
   assign w_r1sel_B = w_reg_out_B[97:95];
   assign w_r1re_B = w_reg_out_B[94];
   assign w_r2sel_B = w_reg_out_B[93:91];
   assign w_r2re_B = w_reg_out_B[90];
   assign test_regfile_we_B = w_reg_out_B[89];
   assign test_regfile_wsel_B = w_reg_out_B[88:86];
   assign w_o_rs_data_B = w_reg_out_B[85:70];
   assign w_o_rt_data_B = w_reg_out_B[69:54];
   assign test_nzp_we_B = w_reg_out_B[53];
   assign w_select_pc_plus_one_B = w_reg_out_B[52];
   assign w_is_load_B = w_reg_out_B[51];
   assign w_is_store_B = w_reg_out_B[50];
   assign w_is_branch_B = w_reg_out_B[49];
   assign w_is_control_insn_B = w_reg_out_B[48];
   assign w_i_cur_insn_B = w_reg_out_B[47:32];
   assign w_pc_B = w_reg_out_B[31:16];
   assign w_alu_output_B = w_reg_out_B[15:0];

   assign test_dmem_data_A = w_is_store_A ? w_o_dmem_towrite_A : (w_is_load_A ? w_i_cur_dmem_data_A : 0);
   assign test_dmem_data_B = w_is_store_B ? w_o_dmem_towrite_B : (w_is_load_B ? w_i_cur_dmem_data_B : 0);
   assign test_cur_pc_A = w_pc_A;
   assign test_cur_pc_B = w_pc_B;
   assign test_cur_insn_A = w_i_cur_insn_A;
   assign test_cur_insn_B = w_i_cur_insn_B;

   cla16 incrementor_A(.a(pc), .b(w_pc_addone), .cin(1'b0), .sum(pc_addone_A));
   cla16 incrementor2_A(.a(w_pc_A), .b(w_pc_addone), .cin(1'b0), .sum(w_pc_addone_A));
   assign test_regfile_data_A = test_regfile_we_A ? (w_is_load_A ? w_i_cur_dmem_data_A : (w_select_pc_plus_one_A ? w_pc_addone_A : w_alu_output_A)) : 0;

   cla16 incrementor2_B(.a(w_pc_B), .b(16'b0), .cin(1'b0), .sum(w_pc_addone_B));
   assign test_regfile_data_B = test_regfile_we_B ? (w_is_load_B ? w_i_cur_dmem_data_B : (w_select_pc_plus_one_B ? w_pc_addone_B : w_alu_output_B)) : 0;

   assign test_nzp_new_bits_A = (w_i_cur_insn_A[15:12] == 4'b0010) ? (($signed(w_alu_output_A) > 0) ? 3'b001 : ($signed(w_alu_output_A) == 0) ? 3'b010 : 3'b100) : (($signed(test_regfile_data_A) > 0) ? 3'b001 : ($signed(test_regfile_data_A) == 0) ? 3'b010 : 3'b100);
   Nbit_reg #(3) nzp_reg_A(.in(test_nzp_new_bits_A), .out(new_nzp_A), .clk(clk), .we(test_nzp_we_A && test_stall_A != 2), .gwe(gwe), .rst(rst));

   assign test_nzp_new_bits_B = (w_i_cur_insn_B[15:12] == 4'b0010) ? (($signed(w_alu_output_B) > 0) ? 3'b001 : ($signed(w_alu_output_B) == 0) ? 3'b010 : 3'b100) : (($signed(test_regfile_data_B) > 0) ? 3'b001 : ($signed(test_regfile_data_B) == 0) ? 3'b010 : 3'b100);
   Nbit_reg #(3) nzp_reg_B(.in(test_nzp_new_bits_B), .out(new_nzp_B), .clk(clk), .we(test_nzp_we_B && test_stall_B != 2), .gwe(gwe), .rst(rst));

   assign next_pc = (x_is_control_insn_B || (x_is_branch_B && did_branch_B)) ? alu_output_B : pc_addone_A; // depends on 2nd INSN

   /* Add $display(...) calls in the always block below to
    * print out debug information at the end of every cycle.
    *
    * You may also use if statements inside the always block
    * to conditionally print out information.
    */
   always @(posedge gwe) begin
     
     $display("Pipe A");
     $display("Time: %d start PC: %h PC at F: %h PC at D: %h PC at X: %h PC at M: %h PC at W: %h Stall: %h", $time, pc, f_pc_A, d_pc_A, x_pc_A, m_pc_A, w_pc_A, test_stall_A);
     $display("Instruction F: %h D: %h X: %h M: %h W: %h", f_insn_A, d_i_cur_insn_A, x_i_cur_insn_A, m_i_cur_insn_A, test_cur_insn_A);

     $display("Pipe B");
     $display("Time: %d start PC: %h PC at F: %h PC at D: %h PC at X: %h PC at M: %h PC at W: %h Stall: %h", $time, pc, f_pc_B, d_pc_B, x_pc_B, m_pc_B, w_pc_B, test_stall_B);
     $display("Instruction F: %h D: %h X: %h M: %h W: %h", f_insn_B, d_i_cur_insn_B, x_i_cur_insn_B, m_i_cur_insn_B, test_cur_insn_B);
     // $display("Instruction is store? %h", is_store_A);
     
      // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
      // if (o_dmem_we)
      //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

      // Start each $display() format string with a %d argument for time
      // it will make the output easier to read.  Use %b, %h, and %d
      // for binary, hex, and decimal output of additional variables.
      // You do not need to add a \n at the end of your format string.
      // $display("%d ...", $time);

      // Try adding a $display() call that prints out the PCs of
      // each pipeline stage in hex.  Then you can easily look up the
      // instructions in the .asm files in test_data.

      // basic if syntax:
      // if (cond) begin
      //    ...;
      //    ...;
      // end

      // Set a breakpoint on the empty $display() below
      // to step through your pipeline cycle-by-cycle.
      // You'll need to rewind the simulation to start
      // stepping from the beginning.

      // You can also simulate for XXX ns, then set the
      // breakpoint to start stepping midway through the
      // testbench.  Use the $time printouts you added above (!)
      // to figure out when your problem instruction first
      // enters the fetch stage.  Rewind your simulation,
      // run it for that many nanoseconds, then set
      // the breakpoint.

      // In the objects view, you can change the values to
      // hexadecimal by selecting all signals (Ctrl-A),
      // then right-click, and select Radix->Hexadecimal.

      // To see the values of wires within a module, select
      // the module in the hierarchy in the "Scopes" pane.
      // The Objects pane will update to display the wires
      // in that module.

      $display();
   end
endmodule
