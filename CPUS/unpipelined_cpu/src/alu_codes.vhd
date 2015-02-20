library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;

PACKAGE alu_codes IS
   --Arithmetic function codes
   CONSTANT    FUNCT_ADD      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#20#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_SUB      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#22#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_MULT     : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#18#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_DIV      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#1A#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_SLT      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#2A#, ALU_FUNCT_WIDTH));
   
   --Logical function codes
   CONSTANT    FUNCT_AND      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#24#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_OR       : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#25#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_NOR      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#27#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_XOR      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#26#, ALU_FUNCT_WIDTH));
   
   --Shift function codes
   CONSTANT    FUNCT_SLL      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#00#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_SRL      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#02#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_SRA      : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#03#, ALU_FUNCT_WIDTH));
   
   --Special codes
   CONSTANT    FUNCT_MFHI     : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#10#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_MFLO     : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#12#, ALU_FUNCT_WIDTH));
   CONSTANT    FUNCT_JR       : STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#08#, ALU_FUNCT_WIDTH));
END alu_codes;