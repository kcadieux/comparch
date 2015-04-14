library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;
use work.alu_codes.all;
use work.op_codes.all;

PACKAGE cpu_lib IS 

   CONSTANT    POS_ID            : NATURAL := 1;
   CONSTANT    POS_EX            : NATURAL := 2;
   CONSTANT    POS_MEM           : NATURAL := 3;
   CONSTANT    POS_WB            : NATURAL := 4;
   CONSTANT    POS_NEVER_READS   : NATURAL := 100;
   CONSTANT    POS_NEVER_WRITES  : NATURAL := 0;
   CONSTANT    POS_NO_FWD        : NATURAL := 0;

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
   
   --Extra Info Pipeline registers
   
   TYPE ID_EXTRA IS RECORD
      instr                : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_ID : ID_EXTRA := (
      instr                => (others => '0')
   );
   
   
   TYPE EX_EXTRA IS RECORD
      rs_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      rt_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
     
      imm                  : STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0);
      imm_sign_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      imm_zero_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   
      shamt                : STD_LOGIC_VECTOR(ALU_SHAMT_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_EX : EX_EXTRA := (
      rs_val               => (others => '0'),
      rt_val               => (others => '0'),
   
      imm                  => (others => '0'),
      imm_sign_ext         => (others => '0'),
      imm_zero_ext         => (others => '0'),

      shamt            => (others => '0')
   );
   
   TYPE MEM_EXTRA IS RECORD
      rt_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_MEM : MEM_EXTRA := (
      rt_val               => (others => '0')
   );
   
   -- Internal Pipeline Signals
   TYPE IF_INTERNAL IS RECORD
      pc                   : NATURAL;
      instr_ready          : STD_LOGIC;
      instr_buffered       : STD_LOGIC;
      instr                : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
      instr_selection      : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
      next_pc              : NATURAL;
      mem_is_free          : STD_LOGIC;
      can_issue            : STD_LOGIC;
      mem_tx_ongoing       : STD_LOGIC;
      mem_tx_complete      : STD_LOGIC;
      mem_lock             : STD_LOGIC;
      need_mem             : STD_LOGIC;
      branch_predicted     : STD_LOGIC;
      mm_address           : NATURAL;
   END RECORD;
   
   CONSTANT DEFAULT_IF_INTERNAL : IF_INTERNAL := (
      pc                   => 0,
      instr_ready          => '0',
      instr_buffered       => '0',
      instr                => (others => '0'),
      instr_selection      => (others => '0'),
      next_pc              => 0,
      mem_is_free          => '0',
      can_issue            => '0',
      mem_tx_ongoing       => '1',
      mem_tx_complete      => '0',
      mem_lock             => '0',
      need_mem             => '0',
      branch_predicted     => '0',
      mm_address           => 0
   );
   
   TYPE ID_INTERNAL IS RECORD
      is_stalled           : STD_LOGIC;
      branch_requested     : STD_LOGIC;
      halt_requested       : STD_LOGIC;
      branch_addr          : NATURAL;
      forward_rs           : BOOLEAN;
      forward_rt           : BOOLEAN;
      next_pc              : NATURAL;
      history              : UNSIGNED(NB_HISTORY_BITS-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_ID_INTERNAL : ID_INTERNAL := (
      is_stalled           => '0',
      branch_requested     => '0',
      halt_requested       => '0',
      branch_addr          => 0,
      forward_rs           => false,
      forward_rt           => false,
      next_pc              => 4,
      history              => (others => '1')
   );
   
   TYPE EX_INTERNAL IS RECORD
      is_stalled           : STD_LOGIC;
      rs_fwd_val           : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      rt_fwd_val           : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      assertion            : STD_LOGIC;
   END RECORD;
   
   CONSTANT DEFAULT_EX_INTERNAL : EX_INTERNAL := (
      is_stalled           => '0',
      rs_fwd_val           => (others => '0'),
      rt_fwd_val           => (others => '0'),
      assertion            => '0'
   );
   
   TYPE MEM_INTERNAL IS RECORD
      is_stalled           : STD_LOGIC;
      mem_lock             : STD_LOGIC;
      mem_request_lock     : STD_LOGIC;
      mem_tx_ongoing       : STD_LOGIC;
      mem_tx_done          : STD_LOGIC;
      mm_read              : STD_LOGIC;
      mm_word_byte         : STD_LOGIC;
      mm_address           : NATURAL;
      mm_data              : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_MEM_INTERNAL : MEM_INTERNAL := (
      is_stalled           => '0',
      mem_lock             => '0',
      mem_request_lock     => '0',
      mem_tx_ongoing       => '0',
      mem_tx_done          => '0',
      mm_read              => '0',
      mm_word_byte         => '0',
      mm_address           => 0,
      mm_data              => (others => '0')
   );
   
   TYPE WB_INTERNAL IS RECORD
      halt                 : STD_LOGIC;
   END RECORD;
   
   CONSTANT DEFAULT_WB_INTERNAL : WB_INTERNAL := (
      halt                 => '0'
   );
      
   FUNCTION IS_ALU_OP         (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_SHIFT_OP       (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_MOVE_OP        (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_LOAD_OP        (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_STORE_OP       (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_MEM_OP         (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_BRANCH_OP      (p : PIPE_REG) RETURN BOOLEAN;
   FUNCTION IS_JUMP_OP        (p : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION GET_RS_READ_STAGE (p : PIPE_REG) RETURN NATURAL;
   FUNCTION GET_RT_READ_STAGE (p : PIPE_REG) RETURN NATURAL;
   FUNCTION GET_WRITE_STAGE   (p : PIPE_REG) RETURN NATURAL;
   
   FUNCTION GET_RS_SRC        (p1, p2, p3 : PIPE_REG) RETURN NATURAL;
   FUNCTION GET_RT_SRC        (p1, p2, p3 : PIPE_REG) RETURN NATURAL;
   
   FUNCTION GET_DST_ADDR      (p : PIPE_REG) RETURN STD_LOGIC_VECTOR;
   
   FUNCTION HAS_DD_RS         (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   FUNCTION HAS_DD_RT         (p1, p2 : PIPE_REG) RETURN BOOLEAN;
   
   FUNCTION DD_STALL          (p1, p2, p3 : PIPE_REG) RETURN BOOLEAN;
   
END cpu_lib;

PACKAGE BODY cpu_lib IS

   -----------------------------------------------------------------------------------------------
   -- OP CLASSIFICATION FUNCTIONS
   -----------------------------------------------------------------------------------------------
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
   
   FUNCTION IS_SHIFT_OP       (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_ALU AND 
          (p.funct = FUNCT_SLL OR 
           p.funct = FUNCT_SRL OR
           p.funct = FUNCT_SRA)) THEN
         RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   FUNCTION IS_MOVE_OP        (p : PIPE_REG) RETURN BOOLEAN IS
   BEGIN
      IF (p.op = OP_ALU AND 
          (p.funct = FUNCT_MFHI OR 
           p.funct = FUNCT_MFLO)) THEN
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


   -----------------------------------------------------------------------------------------------
   -- DATA DEPENDENCE AND STALL DETECTION FUNCTIONS
   -----------------------------------------------------------------------------------------------
   FUNCTION GET_RS_READ_STAGE (p : PIPE_REG) RETURN NATURAL IS
   BEGIN
      IF    (IS_ALU_OP(p) AND NOT IS_SHIFT_OP(p) AND NOT IS_MOVE_OP(p)) THEN 
         RETURN POS_EX;
      ELSIF (IS_MEM_OP(p)) THEN
         RETURN POS_EX;
      ELSIF (p.op = OP_ASRT) THEN
         RETURN POS_EX;
      ELSIF (IS_BRANCH_OP(p) OR (p.op = OP_ALU AND p.funct = FUNCT_JR)) THEN
         RETURN POS_ID;
      END IF;
      
      RETURN POS_NEVER_READS;
   END FUNCTION;
   
   FUNCTION GET_RT_READ_STAGE (p : PIPE_REG) RETURN NATURAL IS
   BEGIN
      IF    (p.op = OP_ALU AND p.funct /= FUNCT_JR AND NOT IS_MOVE_OP(p)) THEN
         RETURN POS_EX;
      ELSIF (p.op = OP_ASRT OR p.op = OP_ASRTI) THEN
         RETURN POS_EX;
      ELSIF (IS_STORE_OP(p)) THEN
         RETURN POS_MEM;
      ELSIF (IS_BRANCH_OP(p)) THEN
         RETURN POS_ID;
      END IF;
      
      RETURN POS_NEVER_READS;
   END FUNCTION;
   
   FUNCTION GET_WRITE_STAGE   (p : PIPE_REG) RETURN NATURAL IS
   BEGIN
      IF    (IS_ALU_OP(p) AND p.funct /= FUNCT_MULT AND p.funct /= FUNCT_DIV) THEN
         RETURN POS_EX;
      ELSIF (p.op = OP_LUI OR p.op = OP_JAL) THEN
         RETURN POS_EX;
      ELSIF (IS_LOAD_OP(p)) THEN
         RETURN POS_MEM;
      END IF;
      
      RETURN POS_NEVER_WRITES;
   END FUNCTION;
   
   
   FUNCTION GET_RS_SRC        (p1, p2, p3 : PIPE_REG) RETURN NATURAL IS
      VARIABLE src : NATURAL  := POS_NO_FWD;
   BEGIN
      IF (HAS_DD_RS(p1, p3)) THEN
         src := p3.pos;
      END IF;
      
      IF (HAS_DD_RS(p1, p2)) THEN
         src := p2.pos;
      END IF;
      
      RETURN src;
   END FUNCTION;
   
   FUNCTION GET_RT_SRC        (p1, p2, p3 : PIPE_REG) RETURN NATURAL IS
      VARIABLE src : NATURAL  := POS_NO_FWD;
   BEGIN
      IF (HAS_DD_RT(p1, p3)) THEN
         src := p3.pos;
      END IF;
      
      IF (HAS_DD_RT(p1, p2)) THEN
         src := p2.pos;
      END IF;
      
      RETURN src;
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
   
   
   FUNCTION DD_STALL(p1, p2, p3: PIPE_REG) RETURN BOOLEAN IS
      VARIABLE rsReadingNow   : BOOLEAN;
      VARIABLE rtReadingNow   : BOOLEAN;
      VARIABLE p2NotReady     : BOOLEAN; 
      VARIABLE p3NotReady     : BOOLEAN; 
   BEGIN
   
      rsReadingNow := p1.pos = GET_RS_READ_STAGE(p1);
      rtReadingNow := p1.pos = GET_RT_READ_STAGE(p1);
      
      p2NotReady   := GET_WRITE_STAGE(p2) >= p2.pos;
      p3NotReady   := GET_WRITE_STAGE(p3) >= p3.pos;
    
      IF ((rsReadingNow AND p2NotReady AND HAS_DD_RS(p1, p2)) OR
          (rsReadingNow AND p3NotReady AND HAS_DD_RS(p1, p3)) OR
          (rtReadingNow AND p2NotReady AND HAS_DD_RT(p1, p2)) OR
          (rtReadingNow AND p3NotReady AND HAS_DD_RT(p1, p3))) THEN
          
          RETURN true;
      END IF;
      
      RETURN false;
   END FUNCTION;
   
   
   
   
   
   
END cpu_lib;