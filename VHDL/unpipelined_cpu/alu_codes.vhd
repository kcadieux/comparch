library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

PACKAGE alu_codes IS
	--Arithmetic function codes
	CONSTANT	FUNCT_ADD 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#20#, 6));
	CONSTANT	FUNCT_SUB 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#22#, 6));
	CONSTANT	FUNCT_MULT 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#18#, 6));
	CONSTANT	FUNCT_DIV 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#1A#, 6));
	CONSTANT	FUNCT_SLT 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#2A#, 6));
	
	--Logical function codes
	CONSTANT	FUNCT_AND 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#24#, 6));
	CONSTANT	FUNCT_OR 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#25#, 6));
	CONSTANT	FUNCT_NOR 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#27#, 6));
	CONSTANT	FUNCT_XOR 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#26#, 6));
	
	--Shift function codes
	CONSTANT	FUNCT_SLL 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#00#, 6));
	CONSTANT	FUNCT_SRL 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#02#, 6));
	CONSTANT	FUNCT_SRA 	: STD_LOGIC_VECTOR(5 DOWNTO 0) := std_logic_vector(to_unsigned(16#03#, 6));
END alu_codes;