library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type

PACKAGE architecture_constants IS
   CONSTANT    MEM_ADDR_WIDTH    : INTEGER := 32;
   CONSTANT    MEM_DATA_WIDTH    : INTEGER := 32;
   
   CONSTANT    REG_ADDR_WIDTH    : INTEGER := 5;
   CONSTANT    REG_DATA_WIDTH    : INTEGER := 32;
   
   CONSTANT    ALU_FUNCT_WIDTH   : INTEGER := 6;
   CONSTANT    ALU_SHAMT_WIDTH   : INTEGER := 5;
   
   CONSTANT    OP_CODE_WIDTH     : INTEGER := 6;
   
   CONSTANT    NB_INSTR_BYTES    : INTEGER := 4;
   CONSTANT    INSTR_WIDTH       : INTEGER := 32;
   
   CONSTANT    IMMEDIATE_WIDTH   : INTEGER := 16;
   
   CONSTANT    ZERO_REG          : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
END architecture_constants;