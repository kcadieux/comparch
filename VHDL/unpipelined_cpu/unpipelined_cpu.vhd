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
      Mem_Size             : INTEGER   := 256;
      Read_Delay           : INTEGER   := 1; 
      Write_Delay          : INTEGER   := 1
   );
   PORT (
      clk:      	      IN    STD_LOGIC;
      reset:            IN    STD_LOGIC := '0';
      
      
      --Debugging signals
      instr_finished:   OUT   STD_LOGIC;
      mem_dump:         IN    STD_LOGIC := '0' 
   );
   
END unpipelined_cpu;

ARCHITECTURE rtl OF unpipelined_cpu IS
   
   TYPE STATE IS (INITIAL, FETCH, EXEC, MEM, MEM_WB);
   
   SIGNAL current_state    : STATE     := INITIAL;
   SIGNAL pc               : NATURAL   := 0;
   
   SIGNAL curr_instr_byte  : NATURAL   := 0;
   SIGNAL curr_instr       : STD_LOGIC_VECTOR(8 * NB_INSTR_BYTES - 1 DOWNTO 0) := (others => '0');
   
   SIGNAL curr_memop_byte  : NATURAL   := 0;
   SIGNAL load_buffer      : STD_LOGIC_VECTOR(REG_DATA_WIDTH - 1 DOWNTO 0) := (others => '0');
   
   --Main memory signals
   SIGNAL mem_address      : NATURAL                                       := 0;  
   SIGNAL mem_we           : STD_LOGIC                                     := '0';
   SIGNAL mem_wr_done      : STD_LOGIC                                     := '0';
   SIGNAL mem_re           : STD_LOGIC                                     := '0';
   SIGNAL mem_rd_ready     : STD_LOGIC                                     := '0';
   SIGNAL mem_data         : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 downto 0)   := (others => 'Z');
   SIGNAL mem_initialize   : STD_LOGIC                                     := '0';
   
   --Instruction decoder signals
   SIGNAL id_instr         : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0)      := (others => '0');
   SIGNAL id_next_pc       : NATURAL                                       := 0;
   
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
   
BEGIN
   
   main_memory : ENTITY work.Main_Memory
      GENERIC MAP (
         File_Address_Read   => File_Address_Read,
         File_Address_Write  => File_Address_Write,
         Mem_Size            => Mem_Size,
         Read_Delay          => Read_Delay, 
         Write_Delay         => Write_Delay
      )
      PORT MAP (
         clk         => clk,
         address     => mem_address,
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
         next_pc        => pc,
         
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
         a           => alu_a,
         b           => alu_b,
         funct       => alu_funct,
         shamt       => alu_shamt,
  
         result      => alu_result
      );
      
   reg_file : ENTITY work.register_file
      PORT MAP (
         clk            => clk,
      
         read1_addr     => reg_read1_addr,
         read1_data     => reg_read1_data,
         read2_addr     => reg_read2_addr,
         read2_data     => reg_read2_data,
         
         we             => reg_we,
         write_addr     => reg_write_addr,
         write_data     => reg_write_data
      );
   
   fsm : PROCESS (clk, current_state, mem_rd_ready, mem_wr_done, mem_data, curr_instr_byte, pc, curr_memop_byte,
                  id_opcode, id_funct, id_branch_addr, id_jump_addr, reg_read1_data, reg_read2_data)
   BEGIN
      IF (clk'event AND clk = '1') THEN
         CASE current_state IS
         
            WHEN INITIAL =>
               current_state <= FETCH;
         
            WHEN FETCH =>
               IF (mem_rd_ready = '1') THEN
                  curr_instr(8*(NB_INSTR_BYTES - curr_instr_byte) - 1 DOWNTO 8*(NB_INSTR_BYTES - curr_instr_byte - 1)) <= mem_data;
               END IF;
            
               IF (curr_instr_byte < NB_INSTR_BYTES - 1 AND mem_rd_ready = '1') THEN
                  curr_instr_byte <= curr_instr_byte + 1;
                  
               ELSIF (curr_instr_byte = NB_INSTR_BYTES - 1 AND mem_rd_ready = '1') THEN
                  current_state     <= EXEC;
                  curr_instr_byte   <= 0;
                  pc <= pc + 4;
               END IF;
               
            WHEN EXEC =>
               current_state <= FETCH;
            
               IF (id_opcode = OP_LB OR id_opcode = OP_SB) THEN
                  curr_memop_byte   <= 1;
                  current_state     <= MEM;
                  
               ELSIF (id_opcode = OP_LW OR id_opcode = OP_SW) THEN
                  curr_memop_byte   <= 4;
                  current_state     <= MEM;
                  
               ELSIF (id_opcode = OP_BEQ AND reg_read1_data = reg_read2_data) THEN
                  pc <= to_integer(unsigned(id_branch_addr));
                  
               ELSIF (id_opcode = OP_BNE AND reg_read1_data /= reg_read2_data) THEN
                  pc <= to_integer(unsigned(id_branch_addr));
                  
               ELSIF (id_opcode = OP_J) THEN
                  pc <= to_integer(unsigned(id_jump_addr));
               
               ELSIF (id_opcode = OP_ALU AND id_funct = FUNCT_JR) THEN
                  pc <= to_integer(unsigned(reg_read1_data));
               
               ELSIF (id_opcode = OP_JAL) THEN
                  pc <= to_integer(unsigned(id_jump_addr));
               
               END IF;
               
            WHEN MEM =>
               IF (mem_rd_ready = '1' AND (id_opcode = OP_LB OR id_opcode = OP_LW)) THEN
                  IF (id_opcode = OP_LB) THEN
                     load_buffer <= std_logic_vector(resize(signed(mem_data), REG_DATA_WIDTH));
                  
                  ELSIF (id_opcode = OP_LW) THEN
                     load_buffer(8*curr_memop_byte-1 DOWNTO 8*(curr_memop_byte-1)) <= mem_data;
                  END IF;
               END IF;
            
               IF (curr_memop_byte > 1 AND (mem_rd_ready = '1' OR mem_wr_done = '1')) THEN
                  curr_memop_byte <= curr_memop_byte - 1;
                  
               ELSIF (curr_memop_byte = 1 AND (mem_rd_ready = '1' OR mem_wr_done = '1')) THEN
                  current_state     <= FETCH;
                  curr_memop_byte   <= 0;
                  
                  IF (id_opcode = OP_LB OR id_opcode = OP_LW) THEN
                     current_state <= MEM_WB;
                  END IF;
               END IF;
            
            WHEN MEM_WB =>
               current_state <= FETCH;
            
            WHEN OTHERS =>
         
         END CASE;
      END IF;
   END PROCESS;
   
   
   control : PROCESS (current_state, pc, curr_instr_byte, id_opcode, id_funct, curr_memop_byte, mem_rd_ready, load_buffer, id_imm,
                      id_rs, id_rt, id_rd, id_shamt, id_imm_sign_ext, id_imm_zero_ext, reg_read1_data, reg_read2_data, alu_result)
   BEGIN
   
      mem_we         <= '0';
      mem_re         <= '0';
      mem_data       <= (others => 'Z');
      mem_initialize <= reset;
      
      reg_we         <= '0';
      reg_read1_addr <= (others => '0');
      reg_read2_addr <= (others => '0');
      reg_write_addr <= (others => '0');
      reg_write_data <= (others => '0');
      
      alu_a          <= (others => '0');
      alu_b          <= (others => '0');
      alu_funct      <= (others => '0');
      alu_shamt      <= (others => '0');
      
      
      CASE current_state IS
         WHEN INITIAL =>
            mem_initialize <= '1';
      
         WHEN FETCH =>
            mem_re      <= '1';
            mem_address <= pc + curr_instr_byte;
            
         WHEN EXEC =>
            IF (id_opcode = OP_ALU) THEN
               reg_read1_addr <= id_rs;
               reg_read2_addr <= id_rt;
               reg_write_addr <= id_rd;
            
               alu_a          <= reg_read1_data;
               alu_b          <= reg_read2_data;
               alu_funct      <= id_funct;
               alu_shamt      <= id_shamt;
               
               -- Don't write the register if this is a branch
               IF (id_funct /= FUNCT_JR) THEN
                  reg_we         <= '1';
               END IF;
               
               reg_write_data <= alu_result;
               
            ELSIF (id_opcode = OP_ADDI OR id_opcode = OP_SLTI OR id_opcode = OP_ANDI OR
                   id_opcode = OP_ORI  OR id_opcode = OP_XORI) THEN
                   
               reg_read1_addr <= id_rs;
               reg_write_addr <= id_rt;
            
               alu_a          <= reg_read1_data;
               alu_b          <= id_imm_zero_ext;
               
               IF (id_opcode = OP_ADDI OR id_opcode = OP_SLTI) THEN
                  alu_b       <= id_imm_sign_ext;
               END IF;
               
               CASE id_opcode IS
                  WHEN OP_ADDI => alu_funct <= FUNCT_ADD;
                  WHEN OP_SLTI => alu_funct <= FUNCT_SLT;
                  WHEN OP_ANDI => alu_funct <= FUNCT_AND;
                  WHEN OP_ORI  => alu_funct <= FUNCT_OR;
                  WHEN OP_XORI => alu_funct <= FUNCT_XOR;
                  WHEN OTHERS  => alu_funct <= (others => '0');
               END CASE;
               
               reg_we         <= '1';
               reg_write_data <= alu_result;
               
            ELSIF (id_opcode = OP_LUI) THEN
               reg_we         <= '1';
               reg_write_addr <= id_rt;
               reg_write_data <= id_imm & OP_LUI_PAD; 
               
            ELSIF (id_opcode = OP_JAL) THEN
               reg_we         <= '1';
               reg_write_addr <= OP_JAL_REG;
               reg_write_data <= std_logic_vector(to_unsigned(pc, REG_DATA_WIDTH)); 
              
            END IF;
            
         WHEN MEM =>
            reg_read1_addr <= id_rs;
            reg_read2_addr <= id_rt;
            
            alu_a          <= reg_read1_data;
            alu_b          <= id_imm_sign_ext;
            alu_funct      <= FUNCT_ADD;
         
            IF (id_opcode = OP_LB OR id_opcode = OP_LW) THEN
               mem_re   <= '1';
            ELSE 
               mem_we   <= '1';
               mem_data <= reg_read2_data(7 DOWNTO 0);
            END IF;
            
            IF (id_opcode = OP_LB OR id_opcode = OP_SB) THEN
               mem_address    <= to_integer(unsigned(alu_result)) + (1 - curr_memop_byte);
            ELSE
               mem_address    <= to_integer(unsigned(alu_result)) + (4 - curr_memop_byte);
            END IF;
            
         WHEN MEM_WB =>
            reg_we         <= '1';
            reg_write_addr <= id_rt;
            reg_write_data <= load_buffer;
         WHEN OTHERS =>
            
      END CASE;
      
   END PROCESS;
   
END rtl;