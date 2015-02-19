library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

use work.architecture_constants.all;

PACKAGE debug_types IS
   TYPE REGISTER_ARRAY_DBG IS ARRAY(0 TO 2**REG_ADDR_WIDTH-1) OF STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
END debug_types;