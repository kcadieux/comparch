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
use STD.textio.all;

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
      pc:               OUT   NATURAL;
      new_issue:        OUT   STD_LOGIC;
      finished_instr:   OUT   STD_LOGIC;
      finished_prog:    OUT   STD_LOGIC;
      assertion:        OUT   STD_LOGIC;
      assertion_pc:     OUT   NATURAL;
      cycle_count:      OUT   NATURAL;
      branch_count:     OUT   NATURAL;
      branch_mispred:   OUT   NATURAL;
      
      live_mode:        IN    STD_LOGIC := '0';
      live_instr:       IN    STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0) := (others => '0');
      mem_dump:         IN    STD_LOGIC := '0'
   );
   
END cpu;

ARCHITECTURE rtl OF cpu IS
   
   TYPE STATE IS (INITIAL, RUNNING);
   
   SIGNAL current_state    : STATE     := INITIAL;
   
   --Main memory signals
   SIGNAL mm_address       : NATURAL                                       := 0;
   SIGNAL mm_word_byte     : std_logic                                     := '0';
   SIGNAL mm_we            : STD_LOGIC                                     := '0';
   SIGNAL mm_wr_done       : STD_LOGIC                                     := '0';
   SIGNAL mm_re            : STD_LOGIC                                     := '0';
   SIGNAL mm_rd_ready      : STD_LOGIC                                     := '0';
   SIGNAL mm_data          : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0)   := (others => 'Z');
   SIGNAL mm_initialize    : STD_LOGIC                                     := '0';
   
   --Instruction decoder signals
   SIGNAL dec_opcode        : STD_LOGIC_VECTOR(5 DOWNTO 0)                  := (others => '0');
   
   SIGNAL dec_rs            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL dec_rt            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL dec_rd            : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   
   SIGNAL dec_shamt         : STD_LOGIC_VECTOR(4 DOWNTO 0)                  := (others => '0');
   SIGNAL dec_funct         : STD_LOGIC_VECTOR(5 DOWNTO 0)                  := (others => '0');
   
   SIGNAL dec_imm           : STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0)  := (others => '0');
   SIGNAL dec_imm_sign_ext  : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL dec_imm_zero_ext  : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   
   SIGNAL dec_branch_addr   : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)   := (others => '0');
   SIGNAL dec_jump_addr     : STD_LOGIC_VECTOR(MEM_ADDR_WIDTH-1 DOWNTO 0)   := (others => '0');
   
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
   
   --Pipeline registers
   SIGNAL id               : PIPE_REG        := DEFAULT_PIPE_REG;
   SIGNAL ex               : PIPE_REG        := DEFAULT_PIPE_REG;
   SIGNAL mem              : PIPE_REG        := DEFAULT_PIPE_REG;
   SIGNAL wb               : PIPE_REG        := DEFAULT_PIPE_REG;
   
   --Extensions to the pipeline registers for stages that need to exchange extra information
   SIGNAL idx              : ID_EXTRA        := DEFAULT_ID;
   SIGNAL exx              : EX_EXTRA        := DEFAULT_EX;
   SIGNAL memx             : MEM_EXTRA       := DEFAULT_MEM;
   
   --Signals used internally by the different stages (i.e not latched between stages)
   SIGNAL if_i             : IF_INTERNAL     := DEFAULT_IF_INTERNAL;
   SIGNAL id_i             : ID_INTERNAL     := DEFAULT_ID_INTERNAL;
   SIGNAL ex_i             : EX_INTERNAL     := DEFAULT_EX_INTERNAL;
   SIGNAL mem_i            : MEM_INTERNAL    := DEFAULT_MEM_INTERNAL;
   SIGNAL wb_i             : WB_INTERNAL     := DEFAULT_WB_INTERNAL;
   
   SIGNAL global_halt         : STD_LOGIC;
   
   SIGNAL cpu_cycle_count     : NATURAL         := 0;
   SIGNAL cpu_branch_count    : NATURAL         := 0;
   SIGNAL cpu_branch_mispred  : NATURAL         := 0;
   SIGNAL cpu_new_issue       : STD_LOGIC       := '0';
   
BEGIN
   
   global_halt    <= ex_i.assertion OR wb_i.halt;
   
   cycle_count    <= cpu_cycle_count;
   branch_count   <= cpu_branch_count;
   branch_mispred <= cpu_branch_mispred;
   
   pc             <= id.pc;
   new_issue      <= cpu_new_issue;
   
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
         address     => mm_address,
         Word_Byte   => mm_word_byte,
         we          => mm_we,
         wr_done     => mm_wr_done,
         re          => mm_re,
         rd_ready    => mm_rd_ready,
         data        => mm_data,
         initialize  => mm_initialize,
         dump        => mem_dump
      );
   
   instruction_decoder : ENTITY work.instr_decoder
      PORT MAP (
         instr          => idx.instr,
         next_pc        => id_i.next_pc,
         
         opcode         => dec_opcode,
         
         rs             => dec_rs,
         rt             => dec_rt,
         rd             => dec_rd,
         
         shamt          => dec_shamt,
         funct          => dec_funct,
         
         imm            => dec_imm,
         imm_sign_ext   => dec_imm_sign_ext,
         imm_zero_ext   => dec_imm_zero_ext,
         
         branch_addr    => dec_branch_addr,
         jump_addr      => dec_jump_addr
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
      
         --Update cycle count
         cpu_cycle_count <= cpu_cycle_count + 1;
      
         CASE current_state IS
            WHEN INITIAL =>
               current_state <= RUNNING;
               
            WHEN OTHERS =>
         END CASE;
      END IF;
   END PROCESS;
   
   state_ctrl  : PROCESS (current_state, reset)
   BEGIN
      mm_initialize <= reset;
      CASE current_state IS
         WHEN INITIAL =>
            mm_initialize <= '1';
         WHEN OTHERS =>
      END CASE;
   END PROCESS;
   
      
   memory_ctrl    : PROCESS (clk, live_mode, if_i, mem_i)
   BEGIN
      mm_re         <= '0';
      mm_we         <= '0';
      mm_address    <= 0;
      mm_data       <= (others => 'Z');
      mm_word_byte  <= '1';
   
      IF (if_i.mem_lock = '1') THEN
         mm_re         <= '1';
         mm_word_byte  <= '1';
         mm_address    <= if_i.mm_address;
     
      ELSIF (mem_i.mem_lock = '1') THEN
         mm_re         <= mem_i.mm_read;
         mm_we         <= NOT mem_i.mm_read;
         mm_word_byte  <= mem_i.mm_word_byte;
         mm_address    <= mem_i.mm_address;
         mm_data    <= mem_i.mm_data;
      END IF;
   
   END PROCESS;
      
   ---------------------------------------------------------------------------------------------------------------------------
   -- FETCH STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_fetch : PROCESS (clk, mm_rd_ready, mm_data, live_instr, live_mode, if_i, id_i, mem_i)
   BEGIN
      finished_instr          <= if_i.mem_is_free;
   
      --Lock memory if either no request is coming from the MEM stage,
      --or if a current memory transaction is ongoing and we need to finish it.
      if_i.mem_lock           <= if_i.mem_tx_ongoing OR (NOT mem_i.mem_request_lock AND if_i.need_mem);
      if_i.mem_tx_complete    <= if_i.mem_tx_ongoing AND mm_rd_ready;
      if_i.mem_is_free        <= (if_i.mem_tx_complete OR NOT if_i.mem_tx_ongoing) AND NOT mem_i.mem_request_lock;
      if_i.need_mem           <= NOT if_i.instr_buffered OR id_i.branch_requested;
      
      if_i.instr_ready        <= if_i.mem_tx_complete OR if_i.instr_buffered;
      
      if_i.can_issue          <= '0';
      IF (id_i.is_stalled = '0' AND id_i.branch_requested = '0' AND id_i.halt_requested = '0' AND global_halt = '0') THEN
         if_i.can_issue       <= '1';
      END IF;
   
      if_i.mm_address         <= if_i.pc;
      IF    id_i.branch_requested = '1' THEN if_i.mm_address <= id_i.branch_addr;
      ELSIF if_i.mem_is_free = '1' AND if_i.mem_tx_ongoing = '1' THEN if_i.mm_address <= if_i.pc + 4;
      END IF;
      
      --Select the instruction source
      if_i.instr_selection    <= mm_data;
      IF (if_i.instr_buffered = '1') THEN
         if_i.instr_selection <= if_i.instr;
      END IF;
   
      IF (clk'event AND clk = '1') THEN
         
         cpu_new_issue  <= '0';
         IF (id_i.is_stalled = '0') THEN
            idx            <= DEFAULT_ID;
         END IF;
         
         --Instruction issue
         IF (if_i.can_issue = '1') THEN
            IF (if_i.instr_ready = '1') THEN
               id.pc                <= if_i.pc;
               id.pos               <= POS_ID;
               idx.instr            <= if_i.instr_selection;
               cpu_new_issue        <= '1';
               
               if_i.mem_tx_ongoing  <= '0';
               if_i.instr_buffered  <= '0';
               if_i.pc              <= if_i.pc + 4;
            END IF;

         ELSIF (if_i.mem_tx_complete = '1') THEN
            if_i.instr           <= mm_data;
            if_i.mem_tx_ongoing  <= '0';
            if_i.instr_buffered  <= '1';
         END IF;
         
         --Manage branches
         IF (id_i.branch_requested = '1') THEN
            if_i.instr_buffered  <= '0';
            if_i.pc              <= id_i.branch_addr;
            IF (if_i.mem_is_free = '1') THEN
               --if_i.pc           <= id_i.branch_addr + 4;
            END IF;
         END IF;
     
         IF (if_i.mem_is_free = '1' AND if_i.need_mem = '1') THEN
            if_i.mem_tx_ongoing  <= '1';
         END IF;
         
      END IF;
   END PROCESS;
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- DECODE STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_decode    : PROCESS (clk, id, idx, id_i, ex, ex_i, mem, dec_opcode, dec_rs, dec_rt, dec_rd, dec_funct, dec_shamt,
                                 dec_imm, dec_imm_sign_ext, dec_imm_zero_ext, dec_branch_addr, dec_jump_addr,
                                 reg_read1_data, reg_read2_data)
   BEGIN
      
      -- Fill in the common pipe register info for the instruction
      id_i.next_pc            <= id.pc + 4;
      
      id.op                   <= dec_opcode;
      id.funct                <= dec_funct;
      
      id.rs_addr              <= dec_rs;
      id.rt_addr              <= dec_rt;
      id.rd_addr              <= dec_rd;
      
      id.dst_addr              <= GET_DST_ADDR(id);
      
      id_i.is_stalled          <= ex_i.is_stalled;
      id_i.branch_requested    <= '0';
      id_i.forward_rs          <= false;
      id_i.forward_rt          <= false;
      id_i.branch_addr         <= id.pc + 4;
      
      reg_read1_addr <= dec_rs;
      reg_read2_addr <= dec_rt;
      
      --Deal with all stalls during ID
      id_i.is_stalled <= ex_i.is_stalled;
      IF (DD_STALL(id, ex, mem) OR global_halt = '1') THEN
         id_i.is_stalled <= '1';
      END IF;
      
      IF (id.op = OP_HALT) THEN
         id_i.halt_requested <= '1';
      END IF;
      
      --Handle branches and jumps
      IF (id_i.is_stalled = '0' AND (IS_BRANCH_OP(id) OR IS_JUMP_OP(id))) THEN
         id_i.branch_requested <= '1'; 
         id_i.forward_rs       <= HAS_DD_RS(id, mem);
         id_i.forward_rt       <= HAS_DD_RT(id, mem);
         
         IF ((NOT id_i.forward_rs AND NOT id_i.forward_rt AND dec_opcode = OP_BEQ AND reg_read1_data =  reg_read2_data) OR
             (NOT id_i.forward_rs AND NOT id_i.forward_rt AND dec_opcode = OP_BNE AND reg_read1_data /= reg_read2_data) OR
             (    id_i.forward_rs AND NOT id_i.forward_rt AND dec_opcode = OP_BEQ AND mem.result     =  reg_read2_data) OR
             (    id_i.forward_rs AND NOT id_i.forward_rt AND dec_opcode = OP_BNE AND mem.result     /= reg_read2_data) OR
             (NOT id_i.forward_rs AND     id_i.forward_rt AND dec_opcode = OP_BEQ AND reg_read1_data =  mem.result) OR
             (NOT id_i.forward_rs AND     id_i.forward_rt AND dec_opcode = OP_BNE AND reg_read1_data /= mem.result)) THEN
             
            id_i.branch_addr        <= to_integer(unsigned(dec_branch_addr));
         END IF;
         
         IF    (id.op = OP_J OR id.op = OP_JAL)          THEN id_i.branch_addr <= to_integer(unsigned(dec_jump_addr));
         ELSIF (id.op = OP_ALU AND id.funct = FUNCT_JR)  THEN
            IF (id_i.forward_rs)                          THEN id_i.branch_addr <= to_integer(unsigned(mem.result));
            ELSE                                              id_i.branch_addr <= to_integer(unsigned(reg_read1_data));
            END IF;
         END IF;
      END IF;
      
      IF (clk'event AND clk = '1') THEN
      
         --Update branch count if this is a branch
         IF ((IS_BRANCH_OP(id) OR IS_JUMP_OP(id) AND id_i.is_stalled = '0') THEN
            cpu_branch_count    <= cpu_branch_count + 1;
         END IF;
      
         IF (ex_i.is_stalled = '0' AND id_i.is_stalled = '1') THEN
            ex                  <= DEFAULT_PIPE_REG;
            exx                 <= DEFAULT_EX;
         END IF;
         
         IF (id_i.is_stalled = '0') THEN
            
            ex                  <= id;
            ex.pos              <= id.pos + 1;
            
            exx.rs_val          <= reg_read1_data;
            exx.rt_val          <= reg_read2_data;
            
            exx.imm             <= dec_imm;
            exx.imm_sign_ext    <= dec_imm_sign_ext;
            exx.imm_zero_ext    <= dec_imm_zero_ext;
            exx.shamt           <= dec_shamt;
            
         END IF;
       
      END IF;
      
   
   END PROCESS;
   
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- EXECUTE STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_execute : PROCESS (clk, ex, exx, ex_i, mem, mem_i, wb, alu_result)
   BEGIN
   
      ex_i.is_stalled <= mem_i.is_stalled;
      IF (DD_STALL(ex, mem, wb) OR global_halt = '1') THEN
         ex_i.is_stalled <= '1';
      END IF;
      
      --Handle forwarding here
      CASE GET_RS_SRC(ex, mem, wb) IS
         WHEN POS_MEM => ex_i.rs_fwd_val <= mem.result;
         WHEN POS_WB  => ex_i.rs_fwd_val <= wb.result;
         WHEN OTHERS  => ex_i.rs_fwd_val <= exx.rs_val;
      END CASE;
   
      CASE GET_RT_SRC(ex, mem, wb) IS
         WHEN POS_MEM => ex_i.rt_fwd_val <= mem.result;
         WHEN POS_WB  => ex_i.rt_fwd_val <= wb.result;
         WHEN OTHERS  => ex_i.rt_fwd_val <= exx.rt_val;
      END CASE;
      
      alu_shamt <= exx.shamt;
      
      alu_a <= ex_i.rs_fwd_val;
      IF (ex.op = OP_ALU) THEN
         alu_b <= ex_i.rt_fwd_val;
      ELSIF (ex.op = OP_ANDI OR ex.op = OP_ORI OR ex.op = OP_XORI) THEN
         alu_b <= exx.imm_zero_ext;
      ELSE
         alu_b <= exx.imm_sign_ext;
      END IF;
      
      alu_funct <= ex.funct;
      IF    ex.op = OP_ADDI OR IS_MEM_OP(ex)  THEN alu_funct <= FUNCT_ADD;
      ELSIF ex.op = OP_SLTI  THEN alu_funct <= FUNCT_SLT;
      ELSIF ex.op = OP_ANDI  THEN alu_funct <= FUNCT_AND;
      ELSIF ex.op = OP_ORI   THEN alu_funct <= FUNCT_OR;
      ELSIF ex.op = OP_XORI  THEN alu_funct <= FUNCT_XOR;
      END IF;
      
      --Deal with assertions
      ex_i.assertion <= '0';
      assertion      <= '0';
      IF (ex_i.is_stalled = '0' AND clk'event AND clk = '1') THEN  --Allow some time for the inputs to stabilize before evaluating the assertion
         IF ((ex.op = OP_ASRT  AND ex_i.rs_fwd_val /= ex_i.rt_fwd_val) OR
             (ex.op = OP_ASRTI AND ex_i.rt_fwd_val /= exx.imm_sign_ext)) THEN
            ex_i.assertion <= '1';
            assertion      <= '1';
            assertion_pc   <= ex.pc;
         END IF;
      END IF;
   
      IF (clk'event AND clk = '1') THEN
         
         IF (ex_i.is_stalled = '1' AND mem_i.is_stalled = '0') THEN
            mem      <= DEFAULT_PIPE_REG;
         END IF;
         
         IF (mem_i.is_stalled = '0') THEN
            
            IF (ex_i.is_stalled = '1') THEN
               mem      <= DEFAULT_PIPE_REG;
            ELSE
               mem         <= ex;
               mem.pos     <= ex.pos + 1;
               
               --Handle the case when a store depends on the 2nd previous instruction
               --We need to do it here because the 2nd previous instruction is leaving the pipeline at this point
               memx.rt_val     <= exx.rt_val;
               IF (HAS_DD_RT(ex, wb) AND IS_STORE_OP(ex)) THEN
                  memx.rt_val  <= wb.result;
               END IF;
               
               IF (ex.op = OP_LUI) THEN
                  mem.result <= exx.imm & OP_LUI_PAD;
               ELSIF (ex.op = OP_JAL) THEN
                  mem.result <= std_logic_vector(to_unsigned(ex.pc + 4, REG_DATA_WIDTH));
               ELSE
                  mem.result <= alu_result;
               END IF;
            END IF;
         END IF;
      END IF;
   
   END PROCESS;
   
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- MEMORY STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_memory : PROCESS (clk, if_i, mem, memx, mem_i, wb, mm_rd_ready, mm_wr_done)
   BEGIN
   
      mem_i.mem_tx_done <= '0';
      IF    (IS_LOAD_OP(mem) AND mem_i.mem_tx_ongoing = '1' AND mm_rd_ready = '1') THEN mem_i.mem_tx_done <= '1';
      ELSIF (IS_STORE_OP(mem) AND mem_i.mem_tx_ongoing = '1' AND mm_wr_done  = '1') THEN mem_i.mem_tx_done <= '1';
      END IF;
   
      --Issue a request for memory only if we have a memory instruction
      mem_i.mem_request_lock  <= '0';
      IF (IS_MEM_OP(mem)) THEN
         mem_i.mem_request_lock <= '1'; 
      END IF;
      
      mem_i.is_stalled  <= '0';
      IF ((mem_i.mem_request_lock = '1' AND mem_i.mem_tx_done = '0') OR global_halt = '1') THEN
         mem_i.is_stalled  <= '1';
      END IF;
      
      --If memory was requested, lock it as soon as it is available
      mem_i.mem_lock    <= '0';
      IF (mem_i.mem_request_lock = '1' AND if_i.mem_lock = '0' AND global_halt = '0') THEN
         mem_i.mem_lock    <= '1';
      END IF;
      
      mem_i.mm_read <= '0';
      IF (IS_LOAD_OP(mem)) THEN
         mem_i.mm_read <= '1';
      END IF;
      
      mem_i.mm_word_byte <= '0';
      IF (mem.op = OP_LW OR mem.op = OP_SW) THEN
         mem_i.mm_word_byte <= '1';
      END IF;
      
      mem_i.mm_address     <= 0;
      IF (IS_MEM_OP(mem)) THEN
         mem_i.mm_address  <= to_integer(unsigned(mem.result));
      END IF;
      
      mem_i.mm_data <= (others => 'Z');
      IF (IS_STORE_OP(mem)) THEN
         IF  (HAS_DD_RT(mem, wb))    THEN mem_i.mm_data <= wb.result;
         ELSE mem_i.mm_data <= memx.rt_val; 
         END IF;
      END IF;
      
      IF (clk'event AND clk = '1') THEN
 
         mem_i.mem_tx_ongoing <= '0';
         IF (mem_i.mem_lock = '1') THEN
            mem_i.mem_tx_ongoing <= '1';
         END IF;
         
         IF (mem_i.mem_tx_ongoing = '1' AND mem_i.mem_tx_done = '1') THEN
            mem_i.mem_tx_ongoing <= '0';
         END IF;
 
         IF (mem_i.is_stalled = '1' AND mem_i.mem_tx_done = '0') THEN
            --wb    <= DEFAULT_PIPE_REG;
         ELSE
            wb                 <= mem;
            wb.pos             <= mem.pos + 1;
            
            IF    (mem.op = OP_LW AND if_i.mem_lock = '0') THEN
               wb.result       <= mm_data;
            ELSIF (mem.op = OP_LB AND if_i.mem_lock = '0') THEN
               wb.result       <= std_logic_vector(resize(signed(mm_data(7 DOWNTO 0)), REG_DATA_WIDTH));
            END IF;
            
         END IF;
         
      END IF;
   
   END PROCESS;
   
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- WRITE BACK STAGE (thank God it's over!)
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_write_back : PROCESS (clk, wb, wb_i, reg_we, reg_write_addr, reg_write_data)
   BEGIN
      
      reg_we         <= '0';
      IF (global_halt = '0') THEN
         reg_we         <= '1';
      END IF;
      
      reg_write_addr <= wb.dst_addr;
      reg_write_data <= wb.result;
      
      IF (wb.op = OP_HALT) THEN
         wb_i.halt      <= '1';
         finished_prog  <= '1';
      END IF;
   
   END PROCESS;
   
END rtl;