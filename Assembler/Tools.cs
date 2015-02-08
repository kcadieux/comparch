using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Assembler
{
    class Tools
    {
        public static string FullFilePath;

        public static bool StringToRegister(string s, Register r)
        {
            string lowerCase = s.ToLower();

            switch (lowerCase)
            {
                case "$zero":
                    r = Register.Zero;
                    return true;
                case "$at":
                    r = Register.AT;
                    return true;
                case "$v0":
                    r = Register.V0;
                    return true;
                case "$v1":
                    r = Register.V1;
                    return true;
                case "$a0":
                    r = Register.A0;
                    return true;
                case "$a1":
                    r = Register.A1;
                    return true;
                case "$a2":
                    r = Register.A2;
                    return true;
                case "$a3":
                    r = Register.A3;
                    return true;
                case "$t0":
                    r = Register.T0;
                    return true;
                case "$t1":
                    r = Register.T1;
                    return true;
                case "$t2":
                    r = Register.T2;
                    return true;
                case "$t3":
                    r = Register.T3;
                    return true;
                case "$t4":
                    r = Register.T4;
                    return true;
                case "$t5":
                    r = Register.T5;
                    return true;
                case "$t6":
                    r = Register.T6;
                    return true;
                case "$t7":
                    r = Register.T7;
                    return true;
                case "$t8":
                    r = Register.T8;
                    return true;
                case "$t9":
                    r = Register.T9;
                    return true;
                case "$s0":
                    r = Register.S0;
                    return true;
                case "$s1":
                    r = Register.S1;
                    return true;
                case "$s2":
                    r = Register.S2;
                    return true;
                case "$s3":
                    r = Register.S3;
                    return true;
                case "$s4":
                    r = Register.S4;
                    return true;
                case "$s5":
                    r = Register.S5;
                    return true;
                case "$s6":
                    r = Register.S6;
                    return true;
                case "$s7":
                    r = Register.S7;
                    return true;
                case "$k0":
                    r = Register.K0;
                    return true;
                case "$k1":
                    r = Register.K1;
                    return true;
                case "$gp":
                    r = Register.GP;
                    return true;
                case "$sp":
                    r = Register.SP;
                    return true;
                case "$fp":
                    r = Register.FP;
                    return true;
                case "$ra":
                    r = Register.RA;
                    return true;
                default:
                    return false;
            }
        }

        public static bool StringToOperation(string s, Operation o)
        {
            if (String.IsNullOrEmpty(s))
            {
                return false;
            }

            string lowerCase = s.ToLower();

            switch (lowerCase)
            {
                case "add":
                    o = Operation.Add;
                    return true;
                case "sub":
                    o = Operation.Sub;
                    return true;
                case "addi":
                    o = Operation.Addi;
                    return true;
                case "mult":
                    o = Operation.Mult;
                    return true;
                case "div":
                    o = Operation.Div;
                    return true;
                case "slt":
                    o = Operation.Slt;
                    return true;
                case "slti":
                    o = Operation.Slti;
                    return true;
                case "and":
                    o = Operation.And;
                    return true;
                case "or":
                    o = Operation.Or;
                    return true;
                case "nor":
                    o = Operation.Nor;
                    return true;
                case "xor":
                    o = Operation.Xor;
                    return true;
                case "andi":
                    o = Operation.Andi;
                    return true;
                case "ori":
                    o = Operation.Ori;
                    return true;
                case "xori":
                    o = Operation.Xori;
                    return true;
                case "mfhi":
                    o = Operation.Mfhi;
                    return true;
                case "mflo":
                    o = Operation.Mflo;
                    return true;
                case "lui":
                    o = Operation.Lui;
                    return true;
                case "sll":
                    o = Operation.Sll;
                    return true;
                case "srl":
                    o = Operation.Srl;
                    return true;
                case "sra":
                    o = Operation.Sra;
                    return true;
                case "lw":
                    o = Operation.Lw;
                    return true;
                case "lb":
                    o = Operation.Lb;
                    return true;
                case "sw":
                    o = Operation.Sw;
                    return true;
                case "sb":
                    o = Operation.Sb;
                    return true;
                case "beq":
                    o = Operation.Beq;
                    return true;
                case "bne":
                    o = Operation.Bne;
                    return true;
                case "j":
                    o = Operation.J;
                    return true;
                case "jr":
                    o = Operation.Jr;
                    return true;
                case "jal":
                    o = Operation.Jal;
                    return true;
                default:
                    return false;
            }
        }

        public static bool IsAssembly(string file)
        {
            if (!String.IsNullOrEmpty(file))
            {
                return Path.GetExtension(file).ToLower() == "asm";
            }

            return false;
        }

        public static bool FileExists(string file)
        {
            if (File.Exists(file))
            {
                FullFilePath = file;
                return true;
            }

            if (File.Exists(Path.Combine(System.Reflection.Assembly.GetExecutingAssembly().Location, file)))
            {
                FullFilePath = Path.Combine(System.Reflection.Assembly.GetExecutingAssembly().Location, file);
                return true;
            }

            return false;
        }
    }
}
