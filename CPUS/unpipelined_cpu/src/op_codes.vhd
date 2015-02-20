library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;

PACKAGE op_codes IS
   --Standard MIPS op codes
   CONSTANT    OP_ALU      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#00#, OP_CODE_WIDTH));
   CONSTANT    OP_ADDI     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#08#, OP_CODE_WIDTH));
   CONSTANT    OP_SLTI     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#0A#, OP_CODE_WIDTH));
   CONSTANT    OP_ANDI     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#0C#, OP_CODE_WIDTH));
   CONSTANT    OP_ORI      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#0D#, OP_CODE_WIDTH));
   CONSTANT    OP_XORI     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#0E#, OP_CODE_WIDTH));
   CONSTANT    OP_LUI      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#0F#, OP_CODE_WIDTH));
   CONSTANT    OP_LW       : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#23#, OP_CODE_WIDTH));
   CONSTANT    OP_LB       : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#20#, OP_CODE_WIDTH));
   CONSTANT    OP_SW       : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#2B#, OP_CODE_WIDTH));
   CONSTANT    OP_SB       : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#28#, OP_CODE_WIDTH));
   CONSTANT    OP_BEQ      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#04#, OP_CODE_WIDTH));
   CONSTANT    OP_BNE      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#05#, OP_CODE_WIDTH));
   CONSTANT    OP_J        : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#02#, OP_CODE_WIDTH));
   CONSTANT    OP_JAL      : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#03#, OP_CODE_WIDTH));
   
   --Debugging op codes
   CONSTANT    OP_ASRT     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#14#, OP_CODE_WIDTH));
   CONSTANT    OP_ASRTI    : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#15#, OP_CODE_WIDTH));
   CONSTANT    OP_HALT     : STD_LOGIC_VECTOR(OP_CODE_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(16#16#, OP_CODE_WIDTH));
   
   --Op related constants
   CONSTANT    OP_JAL_REG  : STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0) := std_logic_vector(to_unsigned(31, REG_ADDR_WIDTH));
   CONSTANT    OP_LUI_PAD  : STD_LOGIC_VECTOR(15 DOWNTO 0)               := std_logic_vector(to_unsigned(0, 16));
END op_codes;