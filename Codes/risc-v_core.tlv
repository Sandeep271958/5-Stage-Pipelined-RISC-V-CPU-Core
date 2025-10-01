\m4_TLV_version 1d: tl-x.org
\SV
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   
   m4_test_prog()
                   
   //---------------------------------------------------------------------------------



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   
   
   //-------------------PC Logic---------------------------------------------
   
   $next_pc[31:0] = $reset ? 0 :
                    $is_jalr ? $jalr_tgt_pc :
                    ($taken_br || $is_jal) ? $br_tgt_pc :
                      ( 4 + $pc[31:0]); //Default usual value
   

   
   $pc[31:0] = >>1$next_pc[31:0];
   

   
   //------------------Instruction Memory----------------------------------- 
   
   `READONLY_MEM($pc, $$instr[31:0]);
   
   //--------------------Decode Logic---------------------------------------
   
   //Instruction Type
   //R-Type Instr
   $is_r_instr = $instr[6:2] == 5'b011x0 || $instr[6:2] == 5'b10100 || $instr[6:2] == 5'b01011;
   //I-Type Instr
   $is_i_instr = $instr[6:2] == 5'b0000x || $instr[6:2] == 5'b001x0 || $instr[6:2] == 5'b11001;
   //I-Type Load Instr
   $is_load    = $instr[6:0] == 7'b0000011;
   //S-Type Instr
   $is_s_instr = $instr[6:2] == 5'b0100x;
   //B-Type Instr
   $is_b_instr = $instr[6:2] == 5'b11000;
   //U-Type Instr
   $is_u_instr = $instr[6:2] == 5'b00101 || $instr[6:2] == 5'b01101;
   //J-Type Instr
   $is_j_instr = $instr[6:2] == 5'b11011;
   
   //Instruction Field
   $opcode[6:0] = $instr[6:0];
   $rd[4:0]     = $instr[11:7];
   $funct3[2:0] = $instr[14:12];
   $rs1[4:0]    = $instr[19:15];
   $rs2[4:0]    = $instr[24:20];
   
   $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $rs1_valid     = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr ;
   $rs2_valid     = $is_r_instr || $is_s_instr || $is_b_instr; 

   $imm_valid    = $is_i_instr || $is_s_instr || $is_b_instr || $is_u_instr || $is_j_instr;


   //IMM
   $imm[31:0] =
    $is_i_instr ? { {20{$instr[31]}}, $instr[31:20] } :
    $is_s_instr ? { {20{$instr[31]}}, $instr[31:25], $instr[11:7] } :
    $is_b_instr ? { {19{$instr[31]}}, $instr[31], $instr[7], $instr[30:25], $instr[11:8], 1'b0 } :
    $is_u_instr ? { $instr[31:12], 12'b0 } :
    $is_j_instr ? { {11{$instr[31]}}, $instr[31], $instr[19:12], $instr[20], $instr[30:21], 1'b0 } :
                  32'b0; // Default (for R-type or invalid instructions)
   
   
   //instr logic decode
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode};
   
   
   //R-Type
   $is_add   = $dec_bits == 11'b0_000_0110011;
   $is_sub   = $dec_bits == 11'b1_000_0110011;
   $is_sll   = $dec_bits == 11'b0_001_0110011;
   $is_slt   = $dec_bits == 11'b0_010_0110011;
   $is_sltu  = $dec_bits == 11'b0_011_0110011;
   $is_xor   = $dec_bits == 11'b0_100_0110011;
   $is_srl   = $dec_bits == 11'b0_101_0110011;
   $is_sra   = $dec_bits == 11'b1_101_0110011;
   $is_or    = $dec_bits == 11'b0_110_0110011;
   $is_and   = $dec_bits == 11'b0_111_0110011;
   
   
   //I-Type
   $is_addi   = $dec_bits ==? 11'bx_000_0010011;
   $is_slti   = $dec_bits ==? 11'bx_010_0010011;
   $is_sltiu  = $dec_bits ==? 11'bx_011_0010011;
   $is_xori   = $dec_bits ==? 11'bx_100_0010011;
   $is_ori    = $dec_bits ==? 11'bx_110_0010011;
   $is_andi   = $dec_bits ==? 11'bx_111_0010011;
   $is_slli   = $dec_bits ==  11'b0_001_0010011;
   $is_srli   = $dec_bits ==  11'b0_101_0010011;
   $is_srai   = $dec_bits ==  11'b1_101_0010011;
   
   //I-Type Load
   $is_lb   = $dec_bits ==? 11'bx_000_0000011;
   $is_lh   = $dec_bits ==? 11'bx_001_0000011;
   $is_lw   = $dec_bits ==? 11'bx_010_0000011;
   $is_lbu  = $dec_bits ==? 11'bx_100_0000011;
   $is_lhu  = $dec_bits ==? 11'bx_101_0000011;
   
   
   //S-Type
   $is_sb  = $dec_bits ==? 11'bx_000_0100011;
   $is_sh  = $dec_bits ==? 11'bx_001_0100011;
   $is_sw  = $dec_bits ==? 11'bx_010_0100011;

   
   //B-Type
   $is_beq  = $dec_bits ==? 11'bx_000_1100011;
   $is_bne  = $dec_bits ==? 11'bx_001_1100011;
   $is_blt  = $dec_bits ==? 11'bx_100_1100011;
   $is_bge  = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu = $dec_bits ==? 11'bx_111_1100011;

   
   //J-Type
   $is_jal   = $dec_bits ==? 11'bx_xxx_1101111;
   $is_jalr  = $dec_bits ==? 11'bx_000_1100111;
   
   
   //U-Type
   $is_lui    = $dec_bits ==? 11'bx_xxx_0110111;
   $is_auipc  = $dec_bits ==? 11'bx_xxx_0010111;
   
   //------------------Arithmetic Logic Unit-----------------------------------
   
   // SLTU and SLTIU (set if less than, unsigned) results:
   $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};

   // SRA and SRAI (shift right, arithmetic) results:
   // To perform an arithmetic shift, we first sign-extend the source to 64 bits,
   // then shift, which correctly propagates the sign bit.
   $sext_src1[63:0] = { {32{$src1_value[31]}}, $src1_value };
   // 64-bit sign-extended results, which will be truncated
   $sra_rslt[63:0]  = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];

   
   
   //ALU Result Multiplexer
   
   $result[31:0] =
       // R-Type Instructions
       $is_add  ? ($src1_value + $src2_value) :
       $is_sub  ? ($src1_value - $src2_value) :
       $is_sll  ? ($src1_value << $src2_value[4:0]) :
       $is_slt  ? ( ($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0, $src1_value[31]} ) :
       $is_sltu ? $sltu_rslt :
       $is_xor  ? ($src1_value ^ $src2_value) :
       $is_srl  ? ($src1_value >> $src2_value[4:0]) :
       $is_sra  ? $sra_rslt[31:0] :
       $is_or   ? ($src1_value | $src2_value) :
       $is_and  ? ($src1_value & $src2_value) :
       // I-Type Instructions
       $is_addi  ? ($src1_value + $imm) :
       $is_slti  ? ( ($src1_value[31] == $imm[31]) ? $sltiu_rslt : {31'b0, $src1_value[31]} ) :
       $is_sltiu ? $sltiu_rslt :
       $is_xori  ? ($src1_value ^ $imm) :
       $is_ori   ? ($src1_value | $imm) :
       $is_andi  ? ($src1_value & $imm) :
       $is_slli  ? ($src1_value << $imm[4:0]) :
       $is_srli  ? ($src1_value >> $imm[4:0]) :
       $is_srai  ? $srai_rslt[31:0] :
       // U-Type Instructions
       $is_lui   ? { $imm[31:12], 12'b0 } :
       $is_auipc ? ($pc + $imm) :
       // J-Type Instructions
       $is_jal   ? ($pc + 32'd4) :
       $is_jalr  ? ($pc + 32'd4) :
       // Load / Store Instructions
       ($is_load || $is_s_instr) ? ($src1_value + $imm) :
                 32'b0; // Default for branches, loads, stores, etc.
   
   
   
   
   
   //Branching feedback
   $beq = $src1_value == $src2_value;
   $bne = $src1_value != $src2_value;
   $blt = signed'($src1_value) < signed'($src2_value);
   $bge = signed'($src1_value) >= signed'($src2_value);
   $bltu = $src1_value < $src2_value;
   $bgeu = $src1_value >= $src2_value;
   
   //Taken Branch
   $taken_br = 
     $is_beq ? $beq :
     $is_bne ? $bne :
     $is_blt ? $blt :
     $is_bge ? $bge :
     $is_bltu ? $bltu :
     $is_bgeu ? $bgeu :
               1'b0; // Default expression if none is matching
   
   //Target Branch
   $br_tgt_pc[31:0] = $pc + $imm;
   //Updated PC, check above PC Logic
   //$next_pc[31:0] = $taken_br ? $br_tgt_pc : ( 4 + $pc[31:0]);

   $jalr_tgt_pc[31:0] = $src1_value + $imm;
   //$next_pc[31:0] = $is_jalr ? $jalr_tgt_pc : ( 4 + $pc[31:0]);
   
   // Assert these to end simulation (before Makerchip cycle limit).
   //*passed = 1'b0;
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;

   //-----------------------Register File Read & Write---------------------------------------------------
   m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $wb_data[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value) // Final Result after including the MUX ld_data
   //m4+rf(32, 32, $reset, $rd_valid, $rd[4:0], $result[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value) // Initial
   //m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd_en1, $rd_index1[4:0], $rd_data1, $rd_en2, $rd_index2[4:0], $rd_data2)   
   //-----------------------Data Memory--------------------------------------------------------------------
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value, $is_load, $ld_data)   
   //m4+dmem(32, 32, $reset, $addr[4:0], $wr_en, $wr_data[31:0], $rd_en, $rd_data)
   
   // Mux to select the data to be written back to the register file.
   $wb_data[31:0] = $is_load ? $ld_data : $result;
   //-----------------------CPU Visualisation--------------------------------------------------------------
   m4+cpu_viz()
   //------------------------------------------------------------------------------------------------------
\SV
   endmodule