addi $t6 $t6 103
andi $t4 $t5 -33
slti $t4 $t5 -33
ori $t4 $t5 -33
xori $t4 $t5 -33
lui $t4 -33
lw $t4, $t5, -33
lb $t4, $t5, -33
sw $t4, $t5, -33
sb $t4, $t5, -33
beq $t4, $t5, -33
bne $t4, $t5, -33
add $t5, $t6, $t7
sub $at, $v0, $v1 ; some test
mult $at, $t5 ;more test
div $at, $t5			;orly
slt $at, $t5, $t6 ;orly
and $at, $t5, $t6
or $at, $t5, $t6
nor $at, $t5, $t6
xor $at, $t5, $t6
mfhi $at
mflo $at
sll $at, $t5, 31
srl $at,$t5, 15 ;Due to confusing specs, implemented both srl and slr
slr $at,$t5, 15 ;Due to confusing specs, implemented both srl and slr
sra $at $t5, 31
jr $ra
j 1023
jal 1023