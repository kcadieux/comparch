-- This file implements an unpipelined CPU
-- for the MIPS ISA.
--
-- entity name: unpipelined_cpu
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:   1.0 
-- Author:    Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:      February 16, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;
use work.op_codes.all;
use work.alu_codes.all;

ENTITY unpipelined_cpu IS
   
   GENERIC (
      File_Address_Read    : STRING    := "Init.dat";
      File_Address_Write   : STRING    := "MemCon.dat";
      Mem_Size_in_Word     : INTEGER   := 256;
      Read_Delay           : INTEGER   := 0; 
      Write_Delay          : INTEGER   := 0
   );
   PORT (
      clk:      	      IN    STD_LOGIC;
      reset:            IN    STD_LOGIC := '0';
      
      --Debugging signals
      finished_instr:   OUT   STD_LOGIC;
      finished_prog:    OUT   STD_LOGIC;
      assertion:        OUT   STD_LOGIC;
      assertion_pc:     OUT   NATURAL;
      
      live_mode:        IN    STD_LOGIC := '0';
      live_instr:       IN    STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0) := (others => '0');
      mem_dump:         IN    STD_LOGIC := '0'
   );
   
END unpipelined_cpu;

ARCHITECTURE rtl OF unpipelined_cpu IS
   
   TYPE STATE IS (INITIAL, FETCH, EXEC, MEM, MEM_WB, HALT, ASSRT);
   
   SIGNAL current_state    : STATE     := INITIAL;
   SIGNAL pc               : NATURAL   := 0;
   
   SIGNAL curr_instr       : STD_LOGIC_VECTOR(8 * NB_INSTR_BYTES - 1 DOWNTO 0) := (others => '0');
   SIGNAL load_buffer      : STD_LOGIC_VECTOR(REG_DATA_WIDTH - 1 DOWNTO 0) := (others => '0');
   
   --Main memory signals
   SIGNAL mem_address      : NATURAL                                       := 0;
   SIGNAL mem_word_byte    : std_logic                                     := '0';
   SIGNAL mem_we           : STD_LOGIC                                     := '0';
   SIGNAL mem_wr_done      : STD_LOGIC                                     := '0';
   SIGNAL mem_re           : STD_LOGIC                                     := '0';
   SIGNAL mem_rd_ready     : STD_LOGIC                                     := '0';
   SIGNAL mem_data         : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0)   := (others => 'Z');
   SIGNAL mem_initialize   : STD_LOGIC                                     := '0';
   
   --Instruction decoder signals
   SIGNAL id_instr         : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0)      := (others => '0');
   
   SIGNAL id_opcode        : STD_LOGIC_VECTOR(5 DOWNTO 0)                  := (others => '0');
   
   SIGNAL id_rs            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL id_rt            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL id_rd            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   
   SIGNAL id_shamt         : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL id_funct         : STD_LOGIC_VECTOR(5 DOWNTO 0)                  := (others => '0');
   
   SIGNAL id_imm           : STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0)  := (others => '0');
   SIGNAL id_imm_sign_ext  : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL id_imm_zero_ext  : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   
   SIGNAL id_branch_addr   : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL id_jump_addr     : STD_LOGIC_VECTOR(MEM_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
   
   --ALU signals
   SIGNAL alu_a            : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL alu_b            : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL alu_funct        : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0)  := (others => '0');
   SIGNAL alu_shamt        : STD_LOGIC_VECTOR(ALU_SHAMT_WIDTH-1 DOWNTO 0)  := (others => '0');
      
   SIGNAL alu_result       : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   
   --Register file signals
   SIGNAL reg_read1_addr   : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL reg_read1_data   : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL reg_read2_addr   : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL reg_read2_data   : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL reg_we           : STD_LOGIC                                     := '0';
   SIGNAL reg_write_addr   : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL reg_write_data   : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   
   
   
   
   SIGNAL pipe_if          : PIPELINE_INFO_IF;
   SIGNAL pipe_id          : PIPELINE_INFO_ID;
   SIGNAL pipe_ex          : PIPELINE_INFO_EX;
   SIGNAL pipe_mem         : PIPELINE_INFO_MEM;
   SIGNAL pipe_wb          : PIPELINE_INFO_WB;
   
   
BEGIN
   
   main_memory : ENTITY work.Main_Memory
      GENERIC MAP (
         File_Address_Read   => File_Address_Read,
         File_Address_Write  => File_Address_Write,
         Mem_Size_in_Word    => Mem_Size_in_Word,
         Read_Delay          => Read_Delay, 
         Write_Delay         => Write_Delay
      )
      PORT MAP (
         clk         => clk,
         address     => mem_address,
         Word_Byte   => mem_word_byte,
         we          => mem_we,
         wr_done     => mem_wr_done,
         re          => mem_re,
         rd_ready    => mem_rd_ready,
         data        => mem_data,
         initialize  => mem_initialize,
         dump        => mem_dump
      );
   
   instruction_decoder : ENTITY work.instr_decoder
      PORT MAP (
         instr          => curr_instr,
         
         opcode         => id_opcode,
         
         rs             => id_rs,
         rt             => id_rt,
         rd             => id_rd,
         
         shamt          => id_shamt,
         funct          => id_funct,
         
         imm            => id_imm,
         imm_sign_ext   => id_imm_sign_ext,
         imm_zero_ext   => id_imm_zero_ext,
         
         branch_addr    => id_branch_addr,
         jump_addr      => id_jump_addr
      );
      
   alu : ENTITY work.alu
      PORT MAP (
         clk         => clk,
         a           => alu_a,
         b           => alu_b,
         funct       => alu_funct,
         shamt       => alu_shamt,
  
         result      => alu_result
      );
      
   reg_file : ENTITY work.register_file
      PORT MAP (
         clk            => clk,
         reset          => reset,
      
         read1_addr     => reg_read1_addr,
         read1_data     => reg_read1_data,
         read2_addr     => reg_read2_addr,
         read2_data     => reg_read2_data,
         
         we             => reg_we,
         write_addr     => reg_write_addr,
         write_data     => reg_write_data
      );
      
      
   memory_ctrl    : PROCESS (pipe_if, pipe_mem)
   BEGIN
      IF (pipe_mem.mem_lock = '0') THEN
         mem_re         <= '1';
         mem_word_byte  <= '1';
         mem_address    <= pipe_if.mem_address;
     
      ELSE
         mem_re         <= pipe_mem.mem_read;
         mem_we         <= NOT pipe_mem.mem_read;
         mem_word_byte  <= pipe_mem.mem_word_byte;
         mem_address    <= pipe_mem.mem_address;
         mem_data       <= pipe_mem.mem_data;
     
      END IF;
   
   END PROCESS;
      
   pipeline_fetch : PROCESS (clk, mem_rd_ready, mem_data, pipe_if, pipe_id, pipe_mem)
   BEGIN
   
      pipe_if.mem_lock           <= (pipe_if.mem_tx_ongoing AND NOT mem_rd_ready);
      pipe_if.instr_dispatching  <= NOT pipe_id.is_stalled AND ((pipe_if.mem_tx_ongoing AND mem_rd_ready) OR pipe_if.instr_ready);
      pipe_if.instr_start_fetch  <= NOT pipe_mem.mem_lock AND (pipe_if.instr_dispatching OR pipe_if.instr_dispatched);
   
      pipe_if.mem_address        <= pipe_if.pc;
      IF (pipe_if.instr_start_fetch = '1') THEN
         pipe_if.mem_address     <= pipe_if.pc + 4;
      END IF;
   
      IF (clk'event AND clk = '1') THEN
         
         pipe_if.mem_tx_ongoing     <= pipe_if.mem_lock;
         pipe_if.instr_dispatched   <= pipe_if.instr_dispatched OR pipe_if.instr_dispatching;
      
         --If current memory transaction is done...
         IF (pipe_if.mem_tx_ongoing = '1' AND mem_rd_ready = '1') THEN
            IF (pipe_id.is_stalled = '0') THEN
               pipe_id.instr           <= mem_data;
            ELSE
               --Save instruction for when the ID stage will unstall
               pipe_if.instr           <= mem_data;
               pipe_if.instr_ready     <= '1';
            END IF;
         END IF;
         
         IF (pipe_if.instr_ready = '1' AND pipe_id.is_stalled = '0') THEN
            pipe_id.instr              <= pipe_if.instr;
            pipe_if.instr_ready        <= '0';
         END IF;
         
         IF (pipe_if.instr_start_fetch = '1') THEN
            pipe_if.mem_tx_ongoing     <= '1';
            pipe_if.pc                 <= pipe_if.pc + 4;
            pipe_if.instr_dispatched   <= '0';
         END IF;
         
      END IF;
   END PROCESS;
   
   
   
END rtl;