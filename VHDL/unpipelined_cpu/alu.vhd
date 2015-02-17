-- This file implements an ALU for
-- a MIPS CPU
--
-- entity name: alu
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:   1.0 
-- Author:    Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:      February 16, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type
use ieee.math_real.all;

use work.alu_codes.all;

ENTITY alu IS
   
   PORT (
      a:          IN STD_LOGIC_VECTOR(31 DOWNTO 0)   := (others => '0');
      b:          IN STD_LOGIC_VECTOR(31 DOWNTO 0)   := (others => '0');
      funct:      IN STD_LOGIC_VECTOR(5 DOWNTO 0)   := (others => '0');
      shamt:      IN STD_LOGIC_VECTOR(4 DOWNTO 0)   := (others => '0');
      
      result_lo:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      result_hi:  OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
   );
   
END alu;

ARCHITECTURE rtl OF alu IS
   SIGNAL a_u           :  UNSIGNED(31 DOWNTO 0);
   SIGNAL a_s           :  SIGNED(31 DOWNTO 0);
   SIGNAL b_s           :  SIGNED(31 DOWNTO 0);
   SIGNAL shamt_n       :  NATURAL;
   
   SIGNAL result_lo_s   :  SIGNED(31 DOWNTO 0);
   SIGNAL result_hi_s   :  SIGNED(31 DOWNTO 0);
   
   SIGNAL result_mult   :  SIGNED(63 DOWNTO 0);
   
BEGIN
   
   a_u      <= unsigned(a);
   a_s      <= signed(a);
   b_s      <= signed(b);
   shamt_n  <= to_integer(unsigned(shamt));
   
   result_lo   <= std_logic_vector(result_lo_s);
   result_hi   <= std_logic_vector(result_hi_s);
   
   result_mult <= a_s * b_s;
   
   result_lo_s <= 
      a_s + b_s                  WHEN funct = FUNCT_ADD ELSE
      a_s - b_s                  WHEN funct = FUNCT_SUB ELSE
      result_mult(31 DOWNTO 0)   WHEN funct = FUNCT_MULT ELSE
      a_s / b_s                  WHEN funct = FUNCT_DIV ELSE
      to_signed(1, 32)           WHEN funct = FUNCT_SLT AND a_s < b_s ELSE
      to_signed(0, 32)           WHEN funct = FUNCT_SLT AND a_s >= b_s ELSE
      a_s AND b_s                WHEN funct = FUNCT_AND ELSE
      a_s OR b_s                 WHEN funct = FUNCT_OR ELSE
      a_s NOR b_s                WHEN funct = FUNCT_NOR ELSE
      a_s XOR b_s                WHEN funct = FUNCT_XOR ELSE
      a_s SLL shamt_n            WHEN funct = FUNCT_SLL ELSE
      signed(a_u SRL shamt_n)    WHEN funct = FUNCT_SRL ELSE
      a_s SRL shamt_n            WHEN funct = FUNCT_SRA ELSE
      (others => '0');
      
   result_hi_s    <=    result_mult(63 DOWNTO 32);
   
END rtl;