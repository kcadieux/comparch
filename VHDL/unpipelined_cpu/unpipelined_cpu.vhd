-- This file implements an unpipelined CPU
-- for the MIPS ISA.
--
-- entity name: unpipelined_cpu
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:	1.0 
-- Author: 	Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:		February 16, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

ENTITY unpipelined_cpu IS
	
	PORT (
		clk:	 			IN STD_LOGIC
	);
	
	
END unpipelined_cpu;

ARCHITECTURE rtl OF unpipelined_cpu IS
	
BEGIN
	
	
	
	
END rtl;