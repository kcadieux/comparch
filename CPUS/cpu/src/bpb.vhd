-- This file implements a direct mapped cache
--
-- entity name: cache
--
-- Copyright (C) 2015 Kevin Cadieux
--
-- Version:	1.0 
-- Author: 	Kevin Cadieux (kevin.cadieux@mail.mcgill.ca)
-- Date:		April 13, 2015

library ieee;

use ieee.std_logic_1164.all; -- allows use of the std_logic_vector type
use ieee.numeric_std.all; -- allows use of the unsigned type


ENTITY cache IS
	
	
	GENERIC(
		data_width: 			INTEGER := 32;		--Width of each individual element in the cache
		address_width:			INTEGER := 32;		--Number of bits in the address
		nb_entries:       	INTEGER := 256;   --Number of bits in the block index, which results in 2^block_index_width blocks in the set
      nb_history_bits:     INTEGER := 1
	);
	PORT (
		clk:	 				IN STD_LOGIC;
		read_address: 	   IN STD_LOGIC_VECTOR (address_width-1 DOWNTO 0);
      write_address: 	IN STD_LOGIC_VECTOR (address_width-1 DOWNTO 0);
      
		write_data: 		IN STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		read_mem:			IN STD_LOGIC;
		write_mem:			IN STD_LOGIC;
      write_taken:      IN STD_LOGIC;
	
      history:          IN STD_LOGIC_VECTOR (nb_history_bits-1 DOWNTO 0);
   
		read_data:  		OUT STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		hit:					OUT STD_LOGIC;
		valid:				OUT STD_LOGIC;
      taken:            OUT STD_LOGIC
	);
	
	
END cache;

ARCHITECTURE rtl OF cache IS
   CONSTANT NB_LOCAL_BITS  : INTEGER := 2;
	CONSTANT NB_TAG_BITS 	: INTEGER := address_width;
	CONSTANT NB_FLAG_BITS	: INTEGER := 1; -- (valid)
   CONSTANT NB_PRED_BITS   : INTEGER := 2*nb_history_bits * NB_LOCAL_BITS;
   CONSTANT NB_LOCAL_PRED  : INTEGER := 2*nb_history_bits;
   
	CONSTANT WRITE_FLAGS		: STD_LOGIC_VECTOR(NB_FLAG_BITS - 1 DOWNTO 0) := (others => '1');  --All flags are set to 1 when we write.
	
	CONSTANT VALID_INDEX		: INTEGER := NB_TAG_BITS;
	
	SUBTYPE 	HEADER_ENTRY 	   IS STD_LOGIC_VECTOR(NB_FLAG_BITS + NB_TAG_BITS - 1 DOWNTO 0);
	SUBTYPE	DATA_ENTRY		   IS STD_LOGIC_VECTOR(data_width - 1 DOWNTO 0);
   SUBTYPE  PRED_ENTRY        IS STD_LOGIC_VECTOR(NB_PRED_BITS - 1 DOWNTO 0);
   SUBTYPE  PRED_LOCAL_ENTRY  IS STD_LOGIC_VECTOR(nb_local_bits - 1 DOWNTO 0);
	TYPE 		HEADER_MEM		   IS ARRAY(0 TO nb_entries - 1) OF HEADER_ENTRY;
	TYPE		DATA_MEM			   IS ARRAY(0 TO nb_entries - 1) OF DATA_ENTRY;
   TYPE     PRED_MEM          IS ARRAY(0 TO nb_entries - 1) OF PRED_ENTRY;
   TYPE     PRED_LOCAL        IS ARRAY(0 TO NB_LOCAL_PRED - 1) OF PRED_LOCAL_ENTRY;
   
	
	SIGNAL sram_headers: 	HEADER_MEM;		--Memory that holds the headers (flags + tag)
	SIGNAL sram_data:			DATA_MEM;		--Memory that holds the actual data (every individual element of a block is addressable)
   SIGNAL sram_pred:			PRED_MEM;
   
   SIGNAL write_local:     PRED_LOCAL  := (others => (others => '0')); 
   SIGNAL write_local_new: PRED_LOCAL  := (others => (others => '0')); 
   
   SIGNAL read_local:      PRED_LOCAL  := (others => (others => '0'));
   SIGNAL chosen_pred:     PRED_LOCAL_ENTRY  :=  (others => '0');
	
	SIGNAL hit_flag:			STD_LOGIC := '0';
	SIGNAL valid_flag:		STD_LOGIC := '0';
   SIGNAL taken_flag:      STD_LOGIC := '0';
   
   SIGNAL write_ptr:       NATURAL   := 0;
   
   SIGNAL write_present:   STD_LOGIC := '0';
   SIGNAL write_index:     NATURAL := 0;
BEGIN
	
   hit      <= hit_flag;
   valid    <= valid_flag;
   taken    <= taken_flag;
   
   read_write: PROCESS(clk, read_mem, write_mem, sram_data, sram_headers, read_address, write_address, write_ptr,
                       sram_pred, write_local, history, write_taken, read_local, chosen_pred)
   BEGIN
   
      --Initialize memory during simulation. Flags are set to zero to make sure memory starts as invalid.
      IF(now < 1 ps)THEN
         FOR i IN 0 TO nb_entries-1 LOOP
            sram_headers(i) <= (others => '0');
            sram_data(i) <= (others => '0');
            sram_pred(i) <= (others => '0');
         END LOOP;
      END IF;
   
      --Determine if an entry exists in the BPB for the given address.
      --If so, precompute it's updated prediction bits
      write_present     <= '0';
      write_index       <= 0;
      write_local       <= (others => (others => '0'));
      write_local_new   <= (others => (others => '0'));
      
      FOR i IN 0 TO nb_entries-1 LOOP
         IF (write_address = sram_headers(i)(NB_TAG_BITS-1 DOWNTO 0)) THEN
            write_present  <= '1';
            write_index    <= i;
            
            FOR j IN 0 TO NB_LOCAL_PRED-1 LOOP
               write_local(j)        <= sram_pred(i)(NB_PRED_BITS - (NB_LOCAL_BITS * j) - 1 DOWNTO NB_PRED_BITS - (NB_LOCAL_BITS * (j + 1)));
               
               write_local_new(j)    <= write_local(j);
               IF (j = to_integer(unsigned(history))) THEN
                  IF    (write_taken = '1' AND write_local(j) = "00") THEN write_local_new(j) <= "01";
                  ELSIF (write_taken = '1' AND write_local(j) = "01") THEN write_local_new(j) <= "11";
                  ELSIF (write_taken = '1' AND write_local(j) = "10") THEN write_local_new(j) <= "11";
                  ELSIF (write_taken = '0' AND write_local(j) = "01") THEN write_local_new(j) <= "00";
                  ELSIF (write_taken = '0' AND write_local(j) = "10") THEN write_local_new(j) <= "00";
                  ELSIF (write_taken = '0' AND write_local(j) = "11") THEN write_local_new(j) <= "10";
                  END IF;
               END IF;
            END LOOP;
            
            EXIT;
         END IF;
      END LOOP;
      
      --Read the desired entry in the BPB
      read_data   <= (others => '0');
      hit_flag    <= '0';
      valid_flag  <= '0';
      taken_flag  <= '0';
      read_local  <= (others => (others => '0'));
      chosen_pred <= (others => '0');
      
      IF (read_mem = '1') THEN
         
         FOR i IN 0 TO nb_entries-1 LOOP
            IF (read_address = sram_headers(i)(NB_TAG_BITS-1 DOWNTO 0)) THEN
               read_data   <= sram_data(i);
               hit_flag    <= '1';
               valid_flag  <= sram_headers(i)(VALID_INDEX);
               
               FOR j IN 0 TO NB_LOCAL_PRED-1 LOOP
                  read_local(j)     <= sram_pred(i)(NB_PRED_BITS - (NB_LOCAL_BITS * j) - 1 DOWNTO NB_PRED_BITS - (NB_LOCAL_BITS * (j + 1)));
               END LOOP;
               
               chosen_pred <= read_local(to_integer(unsigned(history)));
               
               taken_flag  <= '0';
               IF (chosen_pred = "11" OR chosen_pred = "10") THEN 
                  taken_flag <= '1';
               END IF;
            END IF;
         END LOOP;
         
      END IF;

      IF (clk'event AND clk = '1') THEN
         
         IF (write_mem = '1') THEN
         
            IF (write_present = '1') THEN
               sram_headers(write_index) <= WRITE_FLAGS & write_address;
               sram_data(write_index) <= write_data;
               
               FOR i IN 0 TO NB_LOCAL_PRED-1 LOOP
                  sram_pred(write_index)(NB_PRED_BITS - (NB_LOCAL_BITS * i) - 1 DOWNTO NB_PRED_BITS - (NB_LOCAL_BITS * (i + 1))) <= write_local_new(i);
               END LOOP;
               
            ELSE
               sram_headers(write_ptr) <= WRITE_FLAGS & write_address;
               sram_data(write_ptr) <= write_data;
               sram_pred(write_ptr) <= (others => '1'); -- Initialize as predict taken
               
               write_ptr <= write_ptr + 1;
               IF (write_ptr = nb_entries - 1) THEN
                  write_ptr <= 0;
               END IF;
            END IF;
         END IF;
      
      
      END IF;
   
   END PROCESS;
   
	
	
END rtl;