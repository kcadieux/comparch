library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;
use work.alu_codes.all;
use work.op_codes.all;

PACKAGE cpu_lib IS 

   CONSTANT    POS_ID   : NATURAL := 1;
   CONSTANT    POS_EX   : NATURAL := 2;
   CONSTANT    POS_MEM  : NATURAL := 3;

   TYPE PIPE_REG IS RECORD
      pc                   : NATURAL;
      pos                  : NATURAL;
      op                   : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0);
      funct                : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0);
      
      rs_addr              : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      rt_addr              : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      rd_addr              : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      
      dst_addr             : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      
      result               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_PIPE_REG : PIPE_REG := (
      pc       => 0,
      pos      => 0,
      op       => (others => '0'),
      funct    => (others => '0'),
      rs_addr  => ZERO_REG,
      rt_addr  => ZERO_REG,
      rd_addr  => ZERO_REG,
      dst_addr => ZERO_REG,
      result   => (others => '0')
   );
   
   --Pipeline registers
   TYPE PIPELINE_INFO_IF IS RECORD
      pc                   : NATURAL;
      instr_ready          : STD_LOGIC;
      instr                : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
      
      instr_dispatched     : STD_LOGIC;
      instr_dispatching    : STD_LOGIC;
      instr_start_fetch    : STD_LOGIC;
      
      mem_tx_ongoing       : STD_LOGIC;
      mem_lock             : STD_LOGIC;
      mem_address          : NATURAL;
   END RECORD;
   
   CONSTANT DEFAULT_IF : PIPELINE_INFO_IF := (
      pc                => 0,
      instr_ready       => '0',
      instr             => (others => '0'),
      instr_dispatched  => '0',
      instr_dispatching => '0',
      instr_start_fetch => '0',
      mem_tx_ongoing    => '1',
      mem_lock          => '1',
      mem_address       => 0
   );
      
   
   TYPE PIPELINE_INFO_ID IS RECORD
      next_pc              : NATURAL;
      instr                : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
      
      is_stalled           : STD_LOGIC;
      
      branch_requested     : STD_LOGIC;
      branch_addr          : NATURAL;
      forward_rs           : BOOLEAN;
      forward_rt           : BOOLEAN;
   END RECORD;
   
   CONSTANT DEFAULT_ID : PIPELINE_INFO_ID := (
      next_pc              => 0,
      instr                => (others => '0'),
      is_stalled           => '0',
      branch_requested     => '0',
      branch_addr          => 0,
      forward_rs           => false,
      forward_rt           => false
   );
   
   
   TYPE PIPELINE_INFO_EX IS RECORD
      rs_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      rt_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
     
      imm                  : STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0);
      imm_sign_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      imm_zero_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   
      alu_shamt            : STD_LOGIC_VECTOR(ALU_SHAMT_WIDTH-1 DOWNTO 0);
      alu_funct            : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0);
      
      is_stalled           : STD_LOGIC;
   END RECORD;
   
   CONSTANT DEFAULT_EX : PIPELINE_INFO_EX := (
      rs_val               => (others => '0'),
      rt_val               => (others => '0'),
   
      imm                  => (others => '0'),
      imm_sign_ext         => (others => '0'),
      imm_zero_ext         => (others => '0'),

      alu_shamt            => (others => '0'),
      alu_funct            => (others => '0'),
   
      is_stalled           => '0'
   );
   
   
   TYPE PIPELINE_INFO_MEM IS RECORD 
      is_stalled           : STD_LOGIC;
      
      mem_lock             : STD_LOGIC;
      mem_read             : STD_LOGIC;
      mem_word_byte        : STD_LOGIC;
      mem_address          : NATURAL;
      mem_data             : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_MEM : PIPELINE_INFO_MEM := (
      is_stalled           => '0',
      
      mem_lock             => '0',
      mem_read             => '0',
      mem_word_byte        => '0',
      mem_address          => 0,
      mem_data             => (others => '0')
   );
   
   
   TYPE PIPELINE_INFO_WB IS RECORD
      reg_address          : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      write_data           : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_WB : PIPELINE_INFO_WB := (
      reg_address          => (others => '0'),
      write_data           => (others => '0')
   );
      
   FUNCTION IS_ALU_OP         (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_LOAD_OP        (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_STORE_OP       (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_MEM_OP         (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_BRANCH_OP      (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_JUMP_OP        (p : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION READS_DURING_ID   (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION READS_DURING_EX   (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION READS_DURING_MEM  (p : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION WRITES_DURING_EX  (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION WRITES_DURING_MEM (p : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION GET_DST_ADDR      (p : PIPE_REG) RETURN STD_LOGIC_VECTOR;
   
   FUNCTION HAS_DD_RS         (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   FUNCTION HAS_DD_RT         (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   FUNCTION HAS_DD            (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION DD_STALL_RS       (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   FUNCTION DD_STALL_RT       (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   FUNCTION DD_STALL          (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   
END cpu_lib;

PACKAGE BODY cpu_lib IS

   FUNCTION IS_ALU_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF ((p.op = OP_ALU AND p.funct /= FUNCT_JR) OR 
          p.op = OP_ADDI OR 
          p.op = OP_SLTI OR
          p.op = OP_ANDI OR
          p.op = OP_ORI OR
          p.op = OP_XORI) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_LOAD_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_LW OR 
          p.op = OP_LB) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_STORE_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_SW OR 
          p.op = OP_SB) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_MEM_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (IS_LOAD_OP(p) OR IS_STORE_OP(p)) THEN 
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_BRANCH_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_BEQ OR 
          p.op = OP_BNE) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_JUMP_OP(p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_J OR 
          p.op = OP_JAL OR
          (p.op = OP_ALU AND p.funct = FUNCT_JR)) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;


   FUNCTION READS_DURING_ID (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (IS_BRANCH_OP(p) OR 
          IS_JUMP_OP(p)) THEN
         RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;

   FUNCTION READS_DURING_EX (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (IS_ALU_OP(p) OR
          IS_MEM_OP(p) OR
          p.op = OP_LUI) THEN
         RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;

   FUNCTION READS_DURING_MEM (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      RETURN IS_MEM_OP(p);
   END FUNCTION;
   
   FUNCTION WRITES_DURING_EX (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF ((IS_ALU_OP(p) AND p.funct /= FUNCT_MULT AND p.funct /= FUNCT_DIV AND p.funct /= FUNCT_JR) OR
           p.op = OP_LUI OR
           p.op = OP_JAL) THEN
         RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;
   
   FUNCTION WRITES_DURING_MEM (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (IS_LOAD_OP(p)) THEN
         RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;
   
   FUNCTION GET_DST_ADDR    (p : PIPE_REG) RETURN STD_LOGIC_VECTOR IS
   BEGIN
      IF    (p.op = OP_ALU AND (p.funct = FUNCT_MULT OR p.funct = FUNCT_DIV)) THEN RETURN ZERO_REG;
      ELSIF (p.op = OP_ALU) THEN RETURN p.rd_addr;
      ELSIF (IS_ALU_OP(p))  THEN RETURN p.rt_addr;
      ELSIF (p.op = OP_LUI) THEN RETURN p.rt_addr;
      ELSIF (IS_LOAD_OP(p)) THEN RETURN p.rt_addr;
      ELSIF (p.op = OP_JAL) THEN RETURN OP_JAL_REG;
      END IF;
      
      RETURN ZERO_REG;
   END FUNCTION;
   
   FUNCTION HAS_DD_RS(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p1.rs_addr /= ZERO_REG AND p1.rs_addr = p2.dst_addr) THEN RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;
   
   FUNCTION HAS_DD_RT(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p1.rt_addr /= ZERO_REG AND p1.rt_addr = p2.dst_addr) THEN RETURN true;
      END IF;
      RETURN false;
   END FUNCTION;
   
   FUNCTION HAS_DD(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      RETURN HAS_DD_RS(p1, p2) OR HAS_DD_RT(p1, p2);
   END FUNCTION;
   
   FUNCTION DD_STALL_RS(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (HAS_DD_RS(p1, p2)) THEN
         IF    (WRITES_DURING_EX(p2)  AND (POS_EX  - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         ELSIF (WRITES_DURING_MEM(p2) AND (POS_MEM - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         END IF;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION DD_STALL_RT(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (HAS_DD_RT(p1, p2)) THEN
         IF    (WRITES_DURING_EX(p2)  AND (POS_EX  - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         ELSIF (WRITES_DURING_MEM(p2) AND (POS_MEM - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         END IF;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION DD_STALL(p1, p2 : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (HAS_DD(p1, p2)) THEN
         IF    (WRITES_DURING_EX(p2)  AND (POS_EX  - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         ELSIF (WRITES_DURING_MEM(p2) AND (POS_MEM - (p2.pos - p1.pos)) > 0) THEN RETURN true;
         END IF;
      END IF;
      
      RETURN false;
   END FUNCTION;

END cpu_lib;