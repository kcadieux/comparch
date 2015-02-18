-- This file implements a MIPS
-- instruction decoder
--
-- entity name: instr_decoder
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

ENTITY instr_decoder IS
   
   PORT (
      instr:         IN    STD_LOGIC_VECTOR(INSTR_WIDTH-1 DOWNTO 0)        := (others => '0');
      next_pc:       IN    NATURAL  := 0;
      
      opcode:        OUT   STD_LOGIC_VECTOR(5 DOWNTO 0);
      
      rs:            OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);
      rt:            OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);
      rd:            OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);
      
      shamt:         OUT   STD_LOGIC_VECTOR(4 DOWNTO 0);
      funct:         OUT   STD_LOGIC_VECTOR(5 DOWNTO 0);
      
      imm:           OUT   STD_LOGIC_VECTOR(IMMEDIATE_WIDTH-1 DOWNTO 0);
      imm_sign_ext:  OUT   STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      imm_zero_ext:  OUT   STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      
      branch_addr:   OUT   STD_LOGIC_VECTOR(REG_DATA_WIDTH-1 DOWNTO 0);
      jump_addr:     OUT   STD_LOGIC_VECTOR(MEM_ADDR_WIDTH-1 DOWNTO 0)
   );
   
END instr_decoder;

ARCHITECTURE rtl OF instr_decoder IS
   
   SIGNAL imm_s         : SIGNED (REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL imm_u         : UNSIGNED (REG_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL next_pc_vec   : STD_LOGIC_VECTOR (REG_DATA_WIDTH-1 DOWNTO 0);
   
BEGIN
   
   opcode         <= instr(31 DOWNTO 26);
   
   rs             <= instr(25 DOWNTO 21);
   rt             <= instr(20 DOWNTO 16);
   rd             <= instr(15 DOWNTO 11);
   
   shamt          <= instr(10 DOWNTO 6);
   funct          <= instr(5 DOWNTO 0);
   
   imm_s          <= resize(signed(instr(15 DOWNTO 0)), REG_DATA_WIDTH);
   imm_u          <= resize(unsigned(instr(15 DOWNTO 0)), REG_DATA_WIDTH);
   imm            <= instr(IMMEDIATE_WIDTH-1 DOWNTO 0);
   imm_sign_ext   <= std_logic_vector(imm_s);
   imm_zero_ext   <= std_logic_vector(imm_u);
   
   next_pc_vec    <= std_logic_vector(to_unsigned(next_pc, REG_DATA_WIDTH));
   branch_addr    <= std_logic_vector((imm_s SLL 2) + signed(next_pc_vec));
   jump_addr      <= next_pc_vec(31 DOWNTO 28) & instr(25 DOWNTO 0) & "00";
   
END rtl;