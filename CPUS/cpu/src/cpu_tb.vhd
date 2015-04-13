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
use STD.textio.all; --Don't forget to include this library for file operations.

ENTITY cpu_tb IS
   
   GENERIC (
      File_Address_Read    : STRING    := "Init.dat";
      File_Address_Write   : STRING    := "MemCon.dat";
      File_Instr_Trace     : STRING    := "trace.dat";
      Mem_Size_in_Word     : INTEGER   := 256;
      Execution_Cycles     : INTEGER   := 10000   
   );
   
END cpu_tb;

ARCHITECTURE rtl OF cpu_tb IS
   
   CONSTANT clk_period:		   TIME        := 1 ns;
   
   SIGNAL cpu_clk  :          STD_LOGIC   := '0';
   SIGNAL cpu_memdump :       STD_LOGIC   := '0';
   SIGNAL cpu_pc:             NATURAL     := 0;
   SIGNAL cpu_new_issue:      STD_LOGIC   := '0';
   SIGNAL cpu_finished_prog:  STD_LOGIC   := '0';
   
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
         mem_dump            => cpu_memdump,
         finished_prog       => cpu_finished_prog,
         pc                  => cpu_pc,
         new_issue           => cpu_new_issue 
      );
   
   
   clk_process : PROCESS
   BEGIN
        cpu_clk <= '0';
        WAIT FOR clk_period/2;
        cpu_clk <= '1';
        WAIT FOR clk_period/2;
   END PROCESS;
   
         
   
   execute_process : PROCESS
      file file_pointer : text;
      
      variable line_write : line;
   BEGIN
      
      file_open(file_pointer,File_Instr_Trace,WRITE_MODE);
      
      
      FOR i IN 0 TO Execution_Cycles-1 LOOP
         IF (cpu_finished_prog = '1') THEN
            EXIT;
         END IF;
         
         IF (cpu_new_issue = '1') THEN
            write(line_write,cpu_pc);
            writeline(file_pointer, line_write);
         END IF;
         
         WAIT FOR clk_period;
      END LOOP;
      
      cpu_memdump <= '1';
      WAIT FOR 10 * clk_period;
      
      file_close(file_pointer);
      
      WAIT;
   END PROCESS;
   
END rtl;