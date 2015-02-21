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
use work.architecture_constants.all;

ENTITY alu IS
   
   PORT (
      clk:        IN STD_LOGIC;
      a:          IN STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)    := (others => '0');
      b:          IN STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)    := (others => '0');
      funct:      IN STD_LOGIC_VECTOR(ALU_FUNCT_WIDTH-1 DOWNTO 0)   := (others => '0');
      shamt:      IN STD_LOGIC_VECTOR(ALU_SHAMT_WIDTH-1 DOWNTO 0)   := (others => '0');
      
      result:     OUT STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0)
   );
   
END alu;

ARCHITECTURE rtl OF alu IS
   SIGNAL a_s           :  SIGNED(REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL b_u           :  UNSIGNED(REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL b_s           :  SIGNED(REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL shamt_n       :  NATURAL;
   
   SIGNAL result_s      :  SIGNED(REG_DATA_WIDTH-1 DOWNTO 0); 
   
   SIGNAL reg_lo        :  SIGNED(REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL reg_hi        :  SIGNED(REG_DATA_WIDTH-1 DOWNTO 0);
   
   SIGNAL result_mult   :  SIGNED(REG_DATA_WIDTH*2-1 DOWNTO 0); 
   
BEGIN
   
   a_s      <= signed(a);
   b_u      <= unsigned(b);
   b_s      <= signed(b);
   shamt_n  <= to_integer(unsigned(shamt));
   
   result   <= std_logic_vector(result_s);
   
   result_mult <= a_s * b_s;
   
   result_s <= 
      a_s + b_s                              WHEN funct = FUNCT_ADD ELSE
      a_s - b_s                              WHEN funct = FUNCT_SUB ELSE
      to_signed(1, REG_DATA_WIDTH)           WHEN funct = FUNCT_SLT AND a_s < b_s ELSE
      to_signed(0, REG_DATA_WIDTH)           WHEN funct = FUNCT_SLT AND a_s >= b_s ELSE
      a_s AND b_s                            WHEN funct = FUNCT_AND ELSE
      a_s OR b_s                             WHEN funct = FUNCT_OR ELSE
      a_s NOR b_s                            WHEN funct = FUNCT_NOR ELSE
      a_s XOR b_s                            WHEN funct = FUNCT_XOR ELSE
      b_s SLL shamt_n                        WHEN funct = FUNCT_SLL ELSE
      signed(b_u SRL shamt_n)                WHEN funct = FUNCT_SRL ELSE
      b_s SRL shamt_n                        WHEN funct = FUNCT_SRA ELSE
      reg_hi                                 WHEN funct = FUNCT_MFHI ELSE
      reg_lo                                 WHEN funct = FUNCT_MFLO ELSE
      (others => '0');
      
   mult_state : PROCESS (clk, funct, result_mult)
   BEGIN
      IF (clk'event and clk = '1') THEN
         IF (funct = FUNCT_MULT) THEN
            report "In mult";
            reg_hi <= result_mult(REG_DATA_WIDTH * 2 - 1 DOWNTO REG_DATA_WIDTH);
            reg_lo <= result_mult(REG_DATA_WIDTH-1 DOWNTO 0);
            
         ELSIF (funct = FUNCT_DIV) THEN
            reg_hi <= a_s MOD b_s;
            reg_lo <= a_s / b_s;
            
         END IF;
      END IF;
   END PROCESS;
   
END rtl;