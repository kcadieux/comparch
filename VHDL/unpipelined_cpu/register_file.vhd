-- This file implements a register file for
-- a MIPS CPU
--
-- entity name: register_file
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:   1.0 
-- Author:    Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:      February 16, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

ENTITY register_file IS
   
   PORT (
      clk:           IN    STD_LOGIC;
      
      read_addr:     IN    STD_LOGIC_VECTOR(4 DOWNTO 0) := (others => '0');
      read_data:     OUT   STD_LOGIC_VECTOR(31 DOWNTO 0);
      
      we:            IN    STD_LOGIC := '0';
      write_addr:    IN    STD_LOGIC_VECTOR(4 DOWNTO 0) := (others => '0');
      write_data:    IN    STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0')
   );
   
   
END register_file;

ARCHITECTURE rtl OF register_file IS

   TYPE REG_ARRAY IS ARRAY(1 TO 2**5-1) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
   SIGNAL regs          : REG_ARRAY;
   
   SIGNAL read_addr_n   : NATURAL;
   SIGNAL write_addr_n  : NATURAL;
   
BEGIN
   
   read_addr_n       <= to_integer(unsigned(read_addr));
   write_addr_n      <= to_integer(unsigned(write_addr));
   
   register_file_process : PROCESS (read_addr_n, write_addr_n, clk, write_data, we)
   BEGIN
      --Writes happen at the middle of the clock cycle.
      --Therefore, this component is sensitive to falling edges
      IF (clk'event AND clk = '0') THEN
         IF (we = '1') THEN
            regs(write_addr_n) <= write_data;
         END IF;
      END IF;
   END PROCESS;
   
   read_data <= (others => '0') WHEN read_addr_n = 0 ELSE
                regs(read_addr_n);
   
END rtl;