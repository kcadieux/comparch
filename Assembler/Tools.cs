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

        public static Register StringToRegister(string s)
        {
            string lowerCase = s.ToLower();

            switch (lowerCase)
            {
                case "$0":
                case "$zero":
                    return Register.Zero;
                case "$1":
                case "$at":
                    return Register.AT;
                case "$2":
                case "$v0":
                    return Register.V0;
                case "$3":
                case "$v1":
                    return Register.V1;
                case "$4":
                case "$a0":
                    return Register.A0;
                case "$5":
                case "$a1":
                    return Register.A1;
                case "$6":
                case "$a2":
                    return Register.A2;
                case "$7":
                case "$a3":
                    return Register.A3;
                case "$8":
                case "$t0":
                    return Register.T0;
                case "$9":
                case "$t1":
                    return Register.T1;
                case "$10":
                case "$t2":
                    return Register.T2;
                case "$11":
                case "$t3":
                    return Register.T3;
                case "$12":
                case "$t4":
                    return Register.T4;
                case "$13":
                case "$t5":
                    return Register.T5;
                case "$14":
                case "$t6":
                    return Register.T6;
                case "$15":
                case "$t7":
                    return Register.T7;
                case "$16":
                case "$t8":
                    return Register.T8;
                case "$17":
                case "$t9":
                    return Register.T9;
                case "$18":
                case "$s0":
                    return Register.S0;
                case "$19":
                case "$s1":
                    return Register.S1;
                case "$20":
                case "$s2":
                    return Register.S2;
                case "$21":
                case "$s3":
                    return Register.S3;
                case "$22":
                case "$s4":
                    return Register.S4;
                case "$23":
                case "$s5":
                    return Register.S5;
                case "$24":
                case "$s6":
                    return Register.S6;
                case "$25":
                case "$s7":
                    return Register.S7;
                case "$26":
                case "$k0":
                    return Register.K0;
                case "$27":
                case "$k1":
                    return Register.K1;
                case "$28":
                case "$gp":
                    return Register.GP;
                case "$29":
                case "$sp":
                    return Register.SP;
                case "$30":
                case "$fp":
                    return Register.FP;
                case "$31":
                case "$ra":
                    return Register.RA;
                default:
                    return Register.NONE;
            }
        }

        public static Operation StringToOperation(string s)
        {
            if (String.IsNullOrEmpty(s))
            {
                return Operation.None;
            }

            string lowerCase = s.ToLower();

            switch (lowerCase)
            {
                case "add":
                    return Operation.Add;
                case "sub":
                    return Operation.Sub;
                case "addi":
                    return Operation.Addi;
                case "mult":
                    return Operation.Mult;
                case "div":
                    return Operation.Div;
                case "slt":
                    return Operation.Slt;
                case "slti":
                    return Operation.Slti;
                case "and":
                    return Operation.And;
                case "or":
                    return Operation.Or;
                case "nor":
                    return Operation.Nor;
                case "xor":
                    return Operation.Xor;
                case "andi":
                    return Operation.Andi;
                case "ori":
                    return Operation.Ori;
                case "xori":
                    return Operation.Xori;
                case "mfhi":
                    return Operation.Mfhi;
                case "mflo":
                    return Operation.Mflo;
                case "lui":
                    return Operation.Lui;
                case "sll":
                    return Operation.Sll;
                case "srl":
                case "slr":
                    return Operation.Srl;
                case "sra":
                    return Operation.Sra;
                case "lw":
                    return Operation.Lw;
                case "lb":
                    return Operation.Lb;
                case "sw":
                    return Operation.Sw;
                case "sb":
                    return Operation.Sb;
                case "beq":
                    return Operation.Beq;
                case "bne":
                    return Operation.Bne;
                case "j":
                    return Operation.J;
                case "jr":
                    return Operation.Jr;
                case "jal":
                    return Operation.Jal;
                default:
                    return Operation.None;
            }
        }

        public static bool IsAssembly(string file)
        {
            if (!String.IsNullOrEmpty(file))
            {
                return Path.GetExtension(file).ToLower() == ".asm";
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
