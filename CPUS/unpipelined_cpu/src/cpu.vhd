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
use work.cpu_types.all;

ENTITY cpu IS
   
   GENERIC (
      File_Address_Read    : STRING    := "Init.dat";
      File_Address_Write   : STRING    := "MemCon.dat";
      Mem_Size_in_Word     : INTEGER   := 256;
      Read_Delay           : INTEGER   := 3; 
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
   
   
   
   SIGNAL pipe_if          : PIPELINE_INFO_IF      := DEFAULT_IF;
   SIGNAL pipe_id          : PIPELINE_INFO_ID      := DEFAULT_ID;
   SIGNAL pipe_ex          : PIPELINE_INFO_EX      := DEFAULT_EX;
   SIGNAL pipe_mem         : PIPELINE_INFO_MEM     := DEFAULT_MEM;
   SIGNAL pipe_wb          : PIPELINE_INFO_WB      := DEFAULT_WB;
   
   
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
         instr          => pipe_id.instr,
         next_pc        => pipe_id.next_pc,
         
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
      
   
      
      
   memory_ctrl    : PROCESS (pipe_if, pipe_mem, live_mode)
   BEGIN
      mem_re         <= '0';
      mem_we         <= '0';
      mem_address    <= 0;
      mem_data       <= (others => 'Z');
      mem_word_byte  <= '1';
      mem_initialize <= reset;
   
      IF (pipe_mem.mem_lock = '0' AND live_mode = '0') THEN
         mem_re         <= '1';
         mem_word_byte  <= '1';
         mem_address    <= pipe_if.mem_address;
     
      ELSIF (pipe_mem.mem_lock = '1') THEN
         mem_re         <= pipe_mem.mem_read;
         mem_we         <= NOT pipe_mem.mem_read;
         mem_word_byte  <= pipe_mem.mem_word_byte;
         mem_address    <= pipe_mem.mem_address;
         mem_data       <= pipe_mem.mem_data;
     
      END IF;
   
   END PROCESS;
      
   ---------------------------------------------------------------------------------------------------------------------------
   -- FETCH STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_fetch : PROCESS (clk, mem_rd_ready, mem_data, pipe_if, pipe_id, pipe_mem, live_instr, live_mode)
   BEGIN
   
      finished_instr             <= pipe_if.instr_start_fetch;
      pipe_if.mem_lock           <= pipe_if.mem_tx_ongoing AND NOT mem_rd_ready AND NOT live_mode AND NOT pipe_id.branch_requested;
      pipe_if.instr_dispatching  <= NOT pipe_id.is_stalled AND ((pipe_if.mem_tx_ongoing AND (mem_rd_ready OR live_mode)) OR pipe_if.instr_ready);
      pipe_if.instr_start_fetch  <= NOT pipe_mem.mem_lock AND (pipe_if.instr_dispatching OR pipe_if.instr_dispatched OR pipe_id.branch_requested);
   
      pipe_if.mem_address        <= pipe_if.pc;
      IF (pipe_if.instr_start_fetch = '1') THEN
         pipe_if.mem_address     <= pipe_if.pc + 4;
      ELSIF (pipe_id.branch_requested = '1') THEN
         pipe_if.mem_address     <= pipe_id.branch_addr;
      END IF;
   
      IF (clk'event AND clk = '1') THEN
         
         pipe_if.mem_tx_ongoing     <= pipe_if.mem_lock;
         pipe_if.instr_dispatched   <= pipe_if.instr_dispatched OR pipe_if.instr_dispatching;
         
         pipe_id                    <= DEFAULT_ID;
         pipe_id.pc                 <= pipe_if.pc;
      
         --If current memory transaction is done...
         IF (pipe_if.mem_tx_ongoing = '1' AND ((mem_rd_ready = '1' AND pipe_id.branch_requested = '0') OR live_mode = '1')) THEN
            IF (pipe_id.is_stalled = '0') THEN
               pipe_id.instr           <= mem_data;
               
               IF (live_mode = '1') THEN
                  pipe_id.instr        <= live_instr;
               END IF;
            ELSE
               --Save instruction for when the ID stage will unstall
               pipe_if.instr           <= mem_data;
               pipe_if.instr_ready     <= '1';
               
               IF (live_mode = '1') THEN
                  pipe_if.instr        <= live_instr;
               END IF;
            END IF;
         END IF;
         
         IF (pipe_if.instr_ready = '1' AND pipe_id.is_stalled = '0') THEN
            pipe_id.instr              <= pipe_if.instr;
            pipe_if.instr_ready        <= '0';
         END IF;
         
         IF (pipe_if.instr_start_fetch = '1') THEN
            pipe_if.mem_tx_ongoing     <= '1';
            pipe_if.instr_dispatched   <= '0';
            
            IF (live_mode = '0') THEN
               pipe_if.pc              <= pipe_if.pc + 4;
            ELSIF (pipe_id.branch_requested = '1') THEN
               pipe_if.pc              <= pipe_id.branch_addr + 4;
            END IF;
         END IF;
         
      END IF;
   END PROCESS;
   
   ---------------------------------------------------------------------------------------------------------------------------
   -- DECODE STAGE
   ---------------------------------------------------------------------------------------------------------------------------
   pipeline_decode    : PROCESS (clk, pipe_id, pipe_ex, pipe_mem, id_opcode, id_rs, id_rt, id_rd, id_funct, id_shamt,
                                 id_imm, id_imm_sign_ext, id_imm_zero_ext, id_branch_addr, id_jump_addr,
                                 reg_read1_data, reg_read2_data)
   BEGIN
      
      pipe_id.next_pc                    <= pipe_id.pc;
      pipe_id.is_stalled                 <= pipe_ex.is_stalled;
      
      IF (id_opcode = OP_BEQ OR id_opcode = OP_BNE OR (id_opcode = OP_ALU AND id_funct = FUNCT_JR)) THEN
      
         --Detect stalling data dependence 1 instruction back
         IF ((pipe_ex.opcode = OP_ALU OR pipe_ex.opcode = OP_LB OR pipe_ex.opcode = OP_LW) AND 
             ((pipe_ex.reg_address = id_rs AND id_rs /= ZERO_REG) OR (pipe_ex.reg_address = id_rt AND id_rt /= ZERO_REG))) THEN
            pipe_id.is_stalled   <= '1';
         END IF;
         
         --Detect stalling data dependence 2 instructions back
         IF ((pipe_mem.opcode = OP_LW OR pipe_mem.opcode = OP_LB) AND
             ((pipe_mem.reg_address = id_rs AND id_rs /= ZERO_REG) OR (pipe_mem.reg_address = id_rt AND id_rt /= ZERO_REG))) THEN
            pipe_id.is_stalled   <= '1';
            
         END IF;
      END IF;
      
      pipe_id.branch_requested      <= '0';
      IF (pipe_id.is_stalled = '0' AND (IS_BRANCH_OP(id_opcode) OR IS_JUMP_OP(id_opcode, id_funct))) THEN
         pipe_id.branch_requested   <= '1';
      END IF;
      
      pipe_id.branch_rs_dd_exists   <= '0';
      IF (IS_ALU_OP(pipe_mem.opcode) AND pipe_mem.reg_address = id_rs AND id_rs /= ZERO_REG) THEN
         pipe_id.branch_rs_dd_exists   <= '1';
      END IF;
      
      pipe_id.branch_rt_dd_exists   <= '0';
      IF (IS_ALU_OP(pipe_mem.opcode) AND pipe_mem.reg_address = id_rt AND id_rt /= ZERO_REG) THEN
         pipe_id.branch_rt_dd_exists   <= '1';
      END IF;
      
      pipe_id.branch_addr           <= pipe_id.next_pc;
      IF ((pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '0' AND pipe_id.branch_rt_dd_exists = '0' AND id_opcode = OP_BEQ AND reg_read1_data =  reg_read2_data) OR
          (pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '0' AND pipe_id.branch_rt_dd_exists = '0' AND id_opcode = OP_BNE AND reg_read1_data /= reg_read2_data) OR
          (pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '1' AND pipe_id.branch_rt_dd_exists = '0' AND id_opcode = OP_BEQ AND pipe_mem.reg_data =  reg_read2_data) OR
          (pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '1' AND pipe_id.branch_rt_dd_exists = '0' AND id_opcode = OP_BNE AND pipe_mem.reg_data /= reg_read2_data) OR
          (pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '0' AND pipe_id.branch_rt_dd_exists = '1' AND id_opcode = OP_BEQ AND reg_read1_data =  pipe_mem.reg_data) OR
          (pipe_id.branch_requested = '1' AND pipe_id.branch_rs_dd_exists = '0' AND pipe_id.branch_rt_dd_exists = '1' AND id_opcode = OP_BNE AND reg_read1_data /= pipe_mem.reg_data)) THEN
         pipe_id.branch_addr        <= to_integer(unsigned(id_branch_addr));
      END IF;
      
      IF (pipe_id.branch_requested = '1' AND IS_JUMP_OP(id_opcode, id_funct)) THEN
         pipe_id.branch_addr  <= to_integer(unsigned(id_jump_addr));
         
         IF (id_opcode = OP_ALU AND id_funct = FUNCT_JR AND pipe_id.branch_rs_dd_exists = '1') THEN
            pipe_id.branch_addr  <= to_integer(unsigned(pipe_mem.reg_data));
         ELSIF (id_opcode = OP_ALU AND id_funct = FUNCT_JR) THEN
            pipe_id.branch_addr  <= to_integer(unsigned(reg_read1_data));
         END IF;
      END IF;
      
      reg_read1_addr <= id_rs;
      reg_read2_addr <= id_rt;
      
      IF (clk'event AND clk = '1') THEN
      
         pipe_ex     <= DEFAULT_EX;
         
         IF (pipe_id.is_stalled = '0') THEN
            pipe_ex.opcode          <= id_opcode;
            pipe_ex.rs_val          <= reg_read1_data;
            pipe_ex.rt_val          <= reg_read2_data;
            pipe_ex.imm             <= id_imm;
            pipe_ex.imm_sign_ext    <= id_imm_sign_ext;
            pipe_ex.imm_zero_ext    <= id_imm_zero_ext;
            pipe_ex.alu_shamt       <= id_shamt;
            pipe_ex.alu_funct       <= id_funct;
            pipe_ex.reg_address     <= ZERO_REG;
            
            --TODO: Move to EX stage
            IF (id_opcode = OP_ALU OR IS_JUMP_OP(id_opcode, id_funct)) THEN
               pipe_ex.reg_address  <= id_rd;
            ELSIF (IS_ALU_OP(id_opcode)) THEN
               --We have some sort of immediate instr, so use rt as destination reg
               pipe_ex.reg_address  <= id_rt;
            END IF;
         END IF;
       
      END IF;
   
   END PROCESS;
   
   
END rtl;