library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;
use work.alu_codes.all;
use work.op_codes.all;

PACKAGE cpu_types IS
   TYPE PIPE_STAGE         IS (ID, EX, MEM);   
   
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
      pc                   : NATURAL;
      next_pc              : NATURAL;
      instr                : STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0);
      
      is_stalled           : STD_LOGIC;
      
      branch_requested     : STD_LOGIC;
      branch_addr          : NATURAL;
      branch_rs_dd_exists  : STD_LOGIC;
      branch_rt_dd_exists  : STD_LOGIC;
   END RECORD;
   
   CONSTANT DEFAULT_ID : PIPELINE_INFO_ID := (
         pc                   => 0,
         next_pc              => 0,
         instr                => (others => '0'),
         is_stalled           => '0',
         branch_requested     => '0',
         branch_addr          => 0,
         branch_rs_dd_exists  => '0',
         branch_rt_dd_exists  => '0'
      );
   
   
   TYPE PIPELINE_INFO_EX IS RECORD
      opcode               : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0);
   
      rs_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      rt_val               : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      
      imm                  : STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0);
      imm_sign_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      imm_zero_ext         : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   
      alu_shamt            : STD_LOGIC_VECTOR(ALU_SHAMT_WIDTH-1 DOWNTO 0);
      alu_funct            : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0);
      
      reg_address          : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      
      is_stalled           : STD_LOGIC;
   END RECORD;
   
   CONSTANT DEFAULT_EX : PIPELINE_INFO_EX := (
         opcode               => OP_ALU,
   
         rs_val               => (others => '0'),
         rt_val               => (others => '0'),
      
         imm                  => (others => '0'),
         imm_sign_ext         => (others => '0'),
         imm_zero_ext         => (others => '0'),
   
         alu_shamt            => (others => '0'),
         alu_funct            => (others => '0'),
      
         reg_address          => (others => '0'),
      
         is_stalled           => '0'
      );
   
   
   TYPE PIPELINE_INFO_MEM IS RECORD
      opcode               : STD_LOGIC_VECTOR(5 DOWNTO 0);
   
      mem_source           : PIPE_STAGE;
      
      reg_address          : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0);
      reg_data             : STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      
      is_stalled           : STD_LOGIC;
      
      mem_lock             : STD_LOGIC;
      mem_read             : STD_LOGIC;
      mem_word_byte        : STD_LOGIC;
      mem_address          : NATURAL;
      mem_data             : STD_LOGIC_VECTOR(MEM_DATA_WIDTH-1 DOWNTO 0);
   END RECORD;
   
   CONSTANT DEFAULT_MEM : PIPELINE_INFO_MEM := (
         opcode               => OP_ALU,
         
         mem_source           => EX,
      
         reg_address          => (others => '0'),
         reg_data             => (others => '0'),
      
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
   
END cpu_types;