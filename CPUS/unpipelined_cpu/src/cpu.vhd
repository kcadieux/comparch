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
use work.cpu_lib.all;

ENTITY cpu IS
   
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
   
END cpu;

ARCHITECTURE rtl OF cpu IS
   
   TYPE STATE IS (INITIAL, RUNNING, HALT, ASSRT);
   
   SIGNAL current_state    : STATE     := INITIAL;
   
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
   
   
   SIGNAL id               : PIPE_REG              := DEFAULT_PIPE_REG;
   SIGNAL ex               : PIPE_REG              := DEFAULT_PIPE_REG;
   SIGNAL mem              : PIPE_REG              := DEFAULT_PIPE_REG;
   SIGNAL wb               : PIPE_REG              := DEFAULT_PIPE_REG;
   
   SIGNAL ifx              : PIPELINE_INFO_IF      := DEFAULT_IF;
   SIGNAL idx              : PIPELINE_INFO_ID      := DEFAULT_ID;
   SIGNAL exx              : PIPELINE_INFO_EX      := DEFAULT_EX;
   SIGNAL memx             : PIPELINE_INFO_MEM     := DEFAULT_MEM;
   SIGNAL wbx              : PIPELINE_INFO_WB      := DEFAULT_WB;
   
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
         instr          => idx.instr,
         next_pc        => idx.next_pc,
         
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
      
   
   fsm : PROCESS (clk, current_state)
   BEGIN
      IF (clk'event AND clk = '1') THEN
         CASE current_state IS
            WHEN INITIAL =>
               current_state <= RUNNING;
            WHEN OTHERS =>
         END CASE;
      END IF;
   END PROCESS;
   
   state_ctrl  : PROCESS (current_state)
   BEGIN
      mem_initialize <= reset;
      CASE current_state IS
         WHEN INITIAL =>
            mem_initialize <= '1';
         WHEN OTHERS =>
      END CASE;
   END PROCESS;
   
      
   memory_ctrl    : PROCESS (ifx, memx, live_mode)
   BEGIN
      mem_re         <= '0';
      mem_we         <= '0';
      mem_address    <= 0;
      mem_data       <= (others => 'Z');
      mem_word_byte  <= '1';
   
      IF (memx.mem_lock = '0' AND live_mode = '0' AND 
          (ifx.instr_start_fetch = '1' OR ifx.mem_tx_ongoing = '1')) THEN
         mem_re         <= '1';
         mem_word_byte  <= '1';
         mem_address    <= ifx.mem_address;
     
      ELSIF (memx.mem_lock = '1') THEN
         mem_re         <= memx.mem_read;
         mem_we         <= NOT memx.mem_read;
         mem_word_byte  <= memx.mem_word_byte;
         mem_address    <= memx.mem_address;
         mem_data       <= memx.mem_data;
     
      END IF;
   
   END PROCESS;
      
   ---------------------------------------------------------------------------------------------------------------------------
   -- FETCH STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_fetch : PROCESS (clk, mem_rd_ready, mem_data, ifx, id, idx, mem, memx, live_instr, live_mode)
   BEGIN
   
      finished_instr         <= ifx.instr_start_fetch;
      ifx.mem_lock           <= ifx.mem_tx_ongoing AND NOT mem_rd_ready AND NOT live_mode AND NOT idx.branch_requested;
      ifx.instr_dispatching  <= NOT idx.is_stalled AND ((ifx.mem_tx_ongoing AND (mem_rd_ready OR live_mode)) OR ifx.instr_ready);
      ifx.instr_start_fetch  <= NOT memx.mem_lock AND (ifx.instr_dispatching OR ifx.instr_dispatched OR idx.branch_requested);
   
      ifx.mem_address        <= ifx.pc;
      IF (idx.branch_requested = '1') THEN
         ifx.mem_address     <= idx.branch_addr;
      ELSIF (ifx.instr_start_fetch = '1') THEN
         ifx.mem_address     <= ifx.pc + 4;
      END IF; 
   
      IF (clk'event AND clk = '1') THEN
         
         ifx.mem_tx_ongoing     <= ifx.mem_lock;
         ifx.instr_dispatched   <= ifx.instr_dispatched OR ifx.instr_dispatching;
         
         IF (idx.is_stalled = '0') THEN
            id.pc               <= ifx.pc;
            id.pos              <= POS_ID;
            idx.instr           <= (others => '0');
         END IF;
      
         --If current memory transaction is done...
         IF (ifx.mem_tx_ongoing = '1' AND ((mem_rd_ready = '1' AND idx.branch_requested = '0') OR live_mode = '1')) THEN
            IF (idx.is_stalled = '0') THEN
               idx.instr           <= mem_data;
               
               IF (live_mode = '1') THEN
                  idx.instr        <= live_instr;
               END IF;
            ELSE
               --Save instruction for when the ID stage will unstall
               ifx.instr           <= mem_data;
               ifx.instr_ready     <= '1';
               
               IF (live_mode = '1') THEN
                  ifx.instr        <= live_instr;
               END IF;
            END IF;
         END IF;
         
         IF (ifx.instr_ready = '1' AND idx.is_stalled = '0' AND idx.branch_requested = '0') THEN
            idx.instr              <= ifx.instr;
         END IF;
         
         IF (ifx.instr_start_fetch = '1') THEN
            ifx.mem_tx_ongoing     <= '1';
            ifx.instr_dispatched   <= '0';
            ifx.instr_ready        <= '0';
            
            IF (idx.branch_requested = '1') THEN
               ifx.pc              <= idx.branch_addr;
            ELSIF (live_mode = '0') THEN
               ifx.pc              <= ifx.pc + 4;
            END IF;
         END IF;
         
      END IF;
   END PROCESS;
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- DECODE STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_decode    : PROCESS (clk, id, idx, ex, exx, mem, memx, id_opcode, id_rs, id_rt, id_rd, id_funct, id_shamt,
                                 id_imm, id_imm_sign_ext, id_imm_zero_ext, id_branch_addr, id_jump_addr, id_instr,
                                 reg_read1_data, reg_read2_data)
   BEGIN
      
      -- Fill in the common pipe register info for the instruction
      idx.next_pc             <= id.pc + 4;
      
      id.op                   <= id_opcode;
      id.funct                <= id_funct;
      
      id.rs_addr              <= id_rs;
      id.rt_addr              <= id_rt;
      id.rd_addr              <= id_rd;
      
      id.dst_addr             <= GET_DST_ADDR(id);
      
      idx.is_stalled          <= exx.is_stalled;
      idx.branch_requested    <= '0';
      idx.forward_rs          <= false;
      idx.forward_rt          <= false;
      
      reg_read1_addr <= id_rs;
      reg_read2_addr <= id_rt;
      
      IF (READS_DURING_ID(id)) THEN  --Implies that this is a branch or jump instr if true
         
         IF    (DD_STALL(id, ex))  THEN idx.is_stalled <= '1';
         ELSIF (DD_STALL(id, mem)) THEN idx.is_stalled <= '1';
         END IF;
         
         IF (idx.is_stalled = '0') THEN 
            idx.branch_requested <= '1'; 
            idx.forward_rs       <= HAS_DD_RS(id, mem);
            idx.forward_rt       <= HAS_DD_RT(id, mem);
            
            IF ((NOT idx.forward_rs AND NOT idx.forward_rt AND id_opcode = OP_BEQ AND reg_read1_data =  reg_read2_data) OR
                (NOT idx.forward_rs AND NOT idx.forward_rt AND id_opcode = OP_BNE AND reg_read1_data /= reg_read2_data) OR
                (    idx.forward_rs AND NOT idx.forward_rt AND id_opcode = OP_BEQ AND mem.result     =  reg_read2_data) OR
                (    idx.forward_rs AND NOT idx.forward_rt AND id_opcode = OP_BNE AND mem.result     /= reg_read2_data) OR
                (NOT idx.forward_rs AND     idx.forward_rt AND id_opcode = OP_BEQ AND reg_read1_data =  mem.result) OR
                (NOT idx.forward_rs AND     idx.forward_rt AND id_opcode = OP_BNE AND reg_read1_data /= mem.result)) THEN
                
               idx.branch_addr        <= to_integer(unsigned(id_branch_addr));
            END IF;
            
            IF    (id.op = OP_J OR id.op = OP_JAL)          THEN idx.branch_addr <= to_integer(unsigned(id_jump_addr));
            ELSIF (id.op = OP_ALU AND id.funct = FUNCT_JR)  THEN
               IF (idx.forward_rs)                          THEN idx.branch_addr <= to_integer(unsigned(mem.result));
               ELSE                                              idx.branch_addr <= to_integer(unsigned(reg_read1_data));
               END IF;
            END IF;
         END IF;

      END IF;
      
      IF (clk'event AND clk = '1') THEN
      
         IF (exx.is_stalled = '0' AND idx.is_stalled = '1') THEN
            ex     <= DEFAULT_PIPE_REG;
            exx    <= DEFAULT_EX;
         END IF;
         
         IF (idx.is_stalled = '0') THEN
            
            ex                  <= id;
            ex.pos              <= id.pos + 1;
            
            exx.rs_val          <= reg_read1_data;
            exx.rt_val          <= reg_read2_data;
            
            exx.imm             <= id_imm;
            exx.imm_sign_ext    <= id_imm_sign_ext;
            exx.imm_zero_ext    <= id_imm_zero_ext;
            exx.alu_shamt       <= id_shamt;
            exx.alu_funct       <= id_funct;
            
         END IF;
       
      END IF;
      
   
   END PROCESS;
   
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- EXECUTION STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_execute : PROCESS (clk, ex, exx, mem, memx, wb, wbx)
   BEGIN
   
      
      
      
      
   
      IF (clk'event AND clk = '1') THEN
         
      END IF;
   
   END PROCESS;
   
   
END rtl;