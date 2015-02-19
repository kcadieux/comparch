using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Assembler
{
    public enum Operation
    {
        None,
        Add,
        Sub,
        Addi,
        Mult,
        Div,
        Slt,
        Slti,
        And,
        Or,
        Nor,
        Xor,
        Andi,
        Ori,
        Xori,
        Mfhi,
        Mflo,
        Lui,
        Sll,
        Srl,
        Sra,
        Lw,
        Lb,
        Sw,
        Sb,
        Beq,
        Bne,
        J,
        Jr,
        Jal,
        Slr,
        Asrt,
        Asrti,
        Halt
    }
}
