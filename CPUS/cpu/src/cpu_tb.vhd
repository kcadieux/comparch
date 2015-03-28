-- This file implements an unpipelined CPU
-- for the MIPS ISA.
--
-- entity name: unpipelined_cpu
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:   1.0 
-- Author:    Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:      February 16, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type

ENTITY cpu_tb IS
   
   GENERIC (
      File_Address_Read    : STRING    := "Init.dat";
      File_Address_Write   : STRING    := "MemCon.dat";
      Mem_Size_in_Word     : INTEGER   := 256;
      Execution_Cycles     : INTEGER   := 10000   
   );
   
END cpu_tb;

ARCHITECTURE rtl OF cpu_tb IS
   
   CONSTANT clk_period:		TIME        := 1 ns;
   
   SIGNAL cpu_clk  :       STD_LOGIC   := '0';
   SIGNAL cpu_memdump :    STD_LOGIC   := '0';
   
BEGIN
   
   cpu : ENTITY work.cpu
      GENERIC MAP (
         File_Address_Read   => File_Address_Read,
         File_Address_Write  => File_Address_Write,
         Mem_Size_in_Word    => Mem_Size_in_Word,
         Read_Delay          => 0, 
         Write_Delay         => 0
      )
      PORT MAP (
         clk                 => cpu_clk, 
         reset               => '0',
      
         live_mode           => '0',
         live_instr          => (others => '0'),
         mem_dump            => cpu_memdump
      );
   
   
   clk_process : PROCESS
   BEGIN
        cpu_clk <= '0';
        WAIT FOR clk_period/2;
        cpu_clk <= '1';
        WAIT FOR clk_period/2;
   END PROCESS;
   
         
   
   execute_process : PROCESS
   BEGIN
      WAIT FOR Execution_Cycles * clk_period;
      cpu_memdump <= '1';
      WAIT FOR 10 * clk_period;
      
      WAIT;
   END PROCESS;
   
END rtl;