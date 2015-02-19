addi $6 $6 -33
andi $t6 $t6 -33
LABEL1:
slti $t4 $t5 -33
ori $t4 $t5 -33
xori $t4 $t5 -33
lui $4 -33
lw $t4, -33($t5) 
lb $t4, -33($t5) 
sw $t4, -33($t5) 
sb $t4, -33($t5) 
LABEL2 :
beq $t4, $t5, LABEL2
bne $t4, $t5, LABEL1
bne $t4, $t5, LABEL3
add $t5, $t6, $t7
sub $at, $v0, $v1 ; some test
mult $at, $t5 ;more test
div $at, $t5			;orly
slt $at, $t5, $t6 ;orly
and $at, $t5, $t6
or $at, $t5, $t6
LABEL3:
nor $at, $t5, $t6
xor $at, $t5, $t6
mfhi $at
mflo $at
sll $at, $t5, 31
srl $at,$t5, 15 ;Due to confusing specs, implemented both srl and slr
slr $at,$t5, 15 ;Due to confusing specs, implemented both srl and slr
sra $at $t5, 31
jr $ra
j LABEL1
jal LABEL2