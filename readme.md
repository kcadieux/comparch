In this repository, you will find a MIPS assembler, a MIPS 
processor and a completely automatic test suite.
________________________________________________________________
Everything is under Copyrights and shall not be reproduced in 
any partial or complete way without the express consent of the author(s) 
of the respective section.
© Maxime Grégoire
© Kevin Cadieux
© Cheryl Guo
© Nicole Witter
________________________________________________________________
1) ASSEMBLER
The assembler files are located in the Assembler/ directory.
It consists of the C# solution and the binaries (compiled files).
NOTE: Given that we have written this in C#, it will only run on
Windows computer with .NET 4.0 installed.

To run the assembler, go to Assembler/bin/Release and run the 
Assembler.exe file. Use the following options, depending on your
needs:

-h 					: 	Tutorial on how to assemble files.
example: CMD> Assembler -h

-i "instruction"	:	Assemble one instruction. Don't forget the double quotes.
example: CMD> Assembler -i "addi $2 $3 36"

"file path"			: 	Assemble a .asm file located at the given path. 
						The assembled file will appear in the the assembly file folder.
example: CMD> Assembler "C:\Grader\fib.asm"

_________________________________________________________________

2) PROCESSOR

The processor VHDL files are located in the CPUS/unpipelined_cpu/src folder.

Processor extras:

- Additional instructions have been developed to facilitate debugging:

```	
asrti $rt imm     #Verify if register $rt is equal to imm. Assert if not.
asrt  $rs $rt	  #Verify that registers $rs and $rt are equal. Assert if not.
halt			  #Halt the processor (eliminated the need to writing an infinite loop)
```
	
- LiveCPU tool, allowing interactive assembly instruction execution from the ModelSim command line (also see LiveCPU.pdf). 
Most popular commands supported by LiveCPU:

```
asm <assembly instruction>   #Run the provided assembly instruction.
							 #(e.g. asm addi $1 $2 30)
reg <register> <radix>	     #Inspect the value of the provided register and print it in the given radix.
							 #If no radix is provided, the default value is "signed".
							 #(e.g. reg $1 unsigned)
regs <radix>				 #Print the value of all registers in the given radix. If no radix is provided,
							 #the default value is "signed".
							 #(e.g. regs unsigned)
test <test name>			 #Runs the test program with the given name in the unpipelined_cpu/tests folder.
							 #The test name must NOT include the .asm extension.
							 #(e.g. test addi)  This will test the addi.asm file in the tests folder
RebootCPU					 #Restarts the CPU from the beginning. 
```

_________________________________________________________________

3) MIKA Test Suite

In order to efficiently test our processor, a series of more than 30 tests
has been developed. Usually, we would have to assemble them all, one by one
and run them, again one by one in ModelSim. However, we built a complete test
suite where a user can add a test inside the suite, assemble it, run it and see
the result in as little as one click of a button.

To open MIKA, open the MIKA.exe file in the root directory. To view or edit the 
assembly code of a test, double click the row. To run it, click the button with the test's name.
To debug it with the LiveCPU tool, hit the "Live CPU Debugging" button.
To run a subset of tests, check the tests' checkboxes and hit the "Run Selected Test" 
button. To run all the test, hit the "Run All Tests" button. If a test fails, the details
will be displayed. To add a new test, add the wanted name in the textbox and hit the "Add
a new test" button.


```

                                 `| |
                    .-"-.__       | .' 
                   /  ,-|  ```'-, || . `
                  /  /@)|_       `-,  | 
                 /  ( ~ \_```""--.,_',  :
              _.'    \   /```''''""`^
             /        | /        `|   :
            /         \/          | |   .
           /      __/  |          |. |
          |     __/  / |          |     |
"-._      |    _/ _/=_//          ||  :
'.  `~~`~^|   /=/-_/_/`~~`~~~`~~`~^~`. 
  `> ' .   \  ~/_/_ /"   `  .  ` ' .   |  
 .' ,'~^~`^|   |~^`^~~`~~~^~~~^~`;       '
 .-'       | | |                  \ ` : `
           |  :|                  | : |
      jgs  |:  |                  ||    '
           | |/                   |  |   :
           |_/                    | .  '

```		   
