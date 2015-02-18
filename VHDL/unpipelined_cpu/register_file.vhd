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

use work.architecture_constants.all;

ENTITY register_file IS
   
   PORT (
      clk:           IN    STD_LOGIC;
      
      read1_addr:    IN    STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
      read1_data:    OUT   STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      read2_addr:    IN    STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
      read2_data:    OUT   STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      
      we:            IN    STD_LOGIC := '0';
      write_addr:    IN    STD_LOGIC_VECTOR(REG_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
      write_data:    IN    STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0) := (others => '0')
   );
   
   
END register_file;

ARCHITECTURE rtl OF register_file IS

   TYPE REG_ARRAY IS ARRAY(1 TO 2**REG_ADDR_WIDTH-1) OF STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL regs             : REG_ARRAY;
   
   SIGNAL read1_addr_n     : NATURAL;
   SIGNAL read2_addr_n     : NATURAL;
   SIGNAL write_addr_n     : NATURAL;
   
BEGIN
   
   read1_addr_n      <= to_integer(unsigned(read1_addr));
   read2_addr_n      <= to_integer(unsigned(read2_addr));
   write_addr_n      <= to_integer(unsigned(write_addr));
   
   register_file_process : PROCESS (write_addr_n, clk, write_data, we)
   BEGIN
      --Initialize memory during simulation.
      IF (now < 1 ps) THEN
         FOR i IN 1 TO 2**REG_ADDR_WIDTH-1 LOOP
            regs(i) <= (others => '0');
         END LOOP;
      END IF;
   
      --Writes happen at the middle of the clock cycle.
      --Therefore, this component is sensitive to falling edges
      IF (clk'event AND clk = '0') THEN
         IF (we = '1' AND write_addr_n > 0) THEN
            regs(write_addr_n) <= write_data;
         END IF;
      END IF;
   END PROCESS;
   
   read1_data <= (others => '0') WHEN read1_addr_n = 0 ELSE
                 regs(read1_addr_n);
                 
   read2_data <= (others => '0') WHEN read2_addr_n = 0 ELSE
                 regs(read2_addr_n);
   
END rtl;