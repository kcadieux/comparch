using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Assembler
{
    class Instruction
    {
        public Instruction(Operation operation, string[] words, int instruction, ref Dictionary<string, int> labelDictionary, ref string log)
        {
            Operation = operation;

            RegisterD = Register.NONE;
            RegisterS = Register.NONE;
            RegisterT = Register.NONE;

            log = "";
            string machineCode = "";
            switch (operation)
            {
                case Operation.Add:

                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100000";
                    break;
                case Operation.Sub:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100010";
                    break;
                case Operation.Addi:
                    machineCode = "001000";
                    Error = !ImmediateEncodingTwoRegisters(ref machineCode, ref log, words, 16);
                    break;
                case Operation.Mult:
                    machineCode = "000000";
                    Error = !EncodingTwoRegisters(ref machineCode, ref log, words);
                    machineCode+="0000000000011000";
                    break;
                case Operation.Div:
                    machineCode = "000000";
                    Error = !EncodingTwoRegisters(ref machineCode, ref log, words);
                    machineCode+="0000000000011010";
                    break;
                case Operation.Slt:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000101010";
                    break;
                case Operation.Slti:
                    machineCode = "001010";
                    Error = !ImmediateEncodingTwoRegisters(ref machineCode, ref log, words, 16);
                    break;
                case Operation.And:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100100";
                    break;
                case Operation.Or:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100101";
                    break;
                case Operation.Nor:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100111";
                    break;
                case Operation.Xor:
                    machineCode = "000000";
                    Error = !EncodingThreeRegisters(ref machineCode, ref log, words);
                    machineCode+="00000100110";
                    break;
                case Operation.Andi:
                    machineCode = "001100";
                    Error = !ImmediateEncodingTwoRegisters(ref machineCode, ref log, words, 16);
                    break;
                case Operation.Ori:
                    machineCode = "001101";
                    Error = !ImmediateEncodingTwoRegisters(ref machineCode, ref log, words, 16);
                    break;
                case Operation.Xori:
                    machineCode = "001110";
                    Error = !ImmediateEncodingTwoRegisters(ref machineCode, ref log, words, 16);
                    break;
                case Operation.Mfhi:
                    machineCode = "0000000000000000";
                    Error = !EncodingOneRegister(ref machineCode, ref log, words);
                    machineCode+="00000010000";
                    break;
                case Operation.Mflo:
                    machineCode = "0000000000000000";
                    Error = !EncodingOneRegister(ref machineCode, ref log, words);
                    machineCode+="00000010010";
                    break;
                case Operation.Lui:
                    machineCode = "001111";
                    machineCode += "00000"; // Ignored by processor
                    Error = !ImmediateEncodingOneRegister(ref machineCode, ref log, words);
                    break;
                case Operation.Sll:
                    machineCode = "000000";
                    machineCode += "00000"; // Ignored by processor
                    Error = !ImmediateEncoding0To32TwoRegisters(ref machineCode, ref log, words);
                    machineCode+="000000";
                    break;
                case Operation.Srl: // Due to confusing specs, I added both
                case Operation.Slr:
                    machineCode = "000000";
                    machineCode += "00000"; // Ignored by processor
                    Error = !ImmediateEncoding0To32TwoRegisters(ref machineCode, ref log, words);
                    machineCode+="000010";
                    break;
                case Operation.Sra:
                    machineCode = "000000";
                    machineCode += "00000"; // Ignored by processor
                    Error = !ImmediateEncoding0To32TwoRegisters(ref machineCode, ref log, words);
                    machineCode+="000011";
                    break;
                case Operation.Lw:
                    machineCode = "100011";
                    Error = !ImmediateEncodingTwoRegistersOffset(ref machineCode, ref log, words);
                    break;
                case Operation.Lb:
                    machineCode = "100000";
                    Error = !ImmediateEncodingTwoRegistersOffset(ref machineCode, ref log, words);
                    break;
                case Operation.Sw:
                    machineCode = "101011";
                    Error = !ImmediateEncodingTwoRegistersOffset(ref machineCode, ref log, words);
                    break;
                case Operation.Sb:
                    machineCode = "101000";
                    Error = !ImmediateEncodingTwoRegistersOffset(ref machineCode, ref log, words);
                    break;
                case Operation.Beq:
                    machineCode = "000100";
                    Error = !EncodingTwoRegisters(ref machineCode, ref log, words);
                    Error &= !LabelEncodingRelative16(ref machineCode, ref log, words, ref labelDictionary, instruction + 1);
                    break;
                case Operation.Bne:
                    machineCode = "000101";
                    Error = !EncodingTwoRegisters(ref machineCode, ref log, words);
                    Error &= !LabelEncodingRelative16(ref machineCode, ref log, words, ref labelDictionary, instruction + 1);
                    break;
                case Operation.J:
                    machineCode = "000010";
                    Error = !LabelEncoding26(ref machineCode, ref log, words, ref labelDictionary);
                    break;
                case Operation.Jr:
                    machineCode = "000000";
                    Error = !EncodingOneRegister(ref machineCode, ref log, words);
                    machineCode+="000000000000000001000";
                    break;
                case Operation.Jal:
                    machineCode = "000011";
                    Error = !LabelEncoding26(ref machineCode, ref log, words, ref labelDictionary);
                    break;
                case Operation.Asrt:
                    machineCode = "010100";
                    Error = !EncodingTwoRegisters(ref machineCode, ref log, words);
                    machineCode+="0000000000000000";
                    break;
                case Operation.Asrti:
                    machineCode = "010101";
                    machineCode += "00000"; // Ignored by processor
                    Error = !ImmediateEncodingOneRegister(ref machineCode, ref log, words);
                    break;
                case Operation.Halt:
                    machineCode = "01011000000000000000000000000000";
                    break;
                default:
                    break;
            }
            MachineCode = machineCode;

        }

        public Operation Operation { get; private set; }

        public Register RegisterD { get; private set; }

        public Register RegisterS { get; private set; }

        public Register RegisterT { get; private set; }

        public string MachineCode { get; private set; }

        public bool Error { get; private set; }

        public void Swap(Instruction ins)
        {
            Operation = ins.Operation;
            RegisterD = ins.RegisterD;
            RegisterT = ins.RegisterT;
            RegisterS = ins.RegisterS;
            MachineCode = ins.MachineCode;
            Error = ins.Error;
        }

        public void SwapRegisterD(Register regD)
        {
            RegisterD = regD;
        }

        public void SwapRegisterS(Register regS)
        {
            RegisterS = regS;
        }

        public void SwapRegisterT(Register regT)
        {
            RegisterT = regT;
        }

        public void SwapOperation(Operation op)
        {
            Operation = op;
        }

        public void SwapMachineCode(string mc)
        {
            MachineCode = mc;
        }

        public static bool LabelEncoding26(ref string machineCode, ref string log, string[] words, ref Dictionary<string, int> labelDictionary)
        {
            int address;
            if (labelDictionary.TryGetValue(words[1], out address))
            {
                machineCode+=CheckAndPadForXChar(Convert.ToString(address, 2), 26);
                return true;
            }

            log += "Wrong label at line ";
            log = words.Aggregate(log, (current, word) => current + word);
            return false;
        }

        public static bool LabelEncodingRelative16(ref string machineCode, ref string log, string[] words, ref Dictionary<string, int> labelDictionary, int addressCount)
        {
            int address;
            if (labelDictionary.TryGetValue(words[3], out address))
            {
                short difference = (short)(address - addressCount);
                machineCode+=CheckAndPadForXChar(Convert.ToString(difference, 2), 16);
                return true;
            }

            log += "Wrong label at line ";
            log = words.Aggregate(log, (current, word) => current + word);
            return false;
        }

        public bool EncodingOneRegister(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 2)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            RegisterD = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            return true;
        }

        public bool EncodingTwoRegisters(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 3)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            RegisterD = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            Register second = Tools.StringToRegister(words[2]);
            RegisterS = second;
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            return true;
        }

        public bool EncodingThreeRegisters(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            RegisterS = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            Register second = Tools.StringToRegister(words[3]);
            RegisterT = second;
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            Register third = Tools.StringToRegister(words[1]);
            RegisterD = third;
            if (third == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)third, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            return true;
        }

        public bool ImmediateEncoding0To32TwoRegisters(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            RegisterS = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;


            Register second = Tools.StringToRegister(words[1]);
            RegisterD = second;
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            short immediate = 0;
            if (Int16.TryParse(words[3], out immediate) && immediate >= 0 && immediate <= 31)
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 5);
                machineCode+=s;
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public bool ImmediateEncodingTwoRegisters(ref string machineCode, ref string log, string[] words, int immediateBits)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            RegisterS = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode += s;

            Register second = Tools.StringToRegister(words[1]);
            RegisterD = second;
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            short immediate = 0;
            if (Int16.TryParse(words[3], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), immediateBits);
                machineCode+=s;
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public bool ImmediateEncodingTwoRegistersOffset(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 3)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + " " + word);
                return false;
            }

            // Split the string of the format offset($reg)
            var sub = words[2].Split('(', ')');
            if (sub.Count() < 2)
            {
                log = log + "\n Error, wrong parameter format on the line :  ";
                log = words.Aggregate(log, (current, word) => current + " " + word);
                return false;
            }

            Register dest = Tools.StringToRegister(sub[1]);
            RegisterD = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line : ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            Register second = Tools.StringToRegister(words[1]);
            RegisterS = second;
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            short immediate = 0;
            if (Int16.TryParse(sub[0], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 16);
                machineCode+=s;
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public bool ImmediateEncodingOneRegister(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 3)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            RegisterS = dest;
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            machineCode+=s;

            short immediate = 0;
            if (Int16.TryParse(words[2], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 16);
                machineCode+=s;
            }
            else
            {
                log = log + "\n Error, invalid immediate value or bad format on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public static bool ImmediateEncodingZeroRegister(ref string machineCode, ref string log, string[] words)
        {
            if (words.Count() < 2)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            short immediate = 0;
            if (Int16.TryParse(words[1], out immediate))
            {
                string s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 26);
                machineCode+=s;
            }
            else
            {
                log = log + "\n Error, invalid immediate value or bad format on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public static string CheckAndPadForXChar(string s, int amountOfChar)
        {
            if (amountOfChar < 0)
            {
                throw new ArgumentException("amountOfChar cannot be smaller than 0", "amountOfChar");
            }

            int charCount = s.ToCharArray().Count();
            if (charCount > amountOfChar)
            {
                return s.Substring(charCount - amountOfChar);
            }

            if (charCount == amountOfChar)
            {
                return s;
            }

            while (charCount < amountOfChar)
            {
                s = "0" + s;
                charCount = s.ToCharArray().Count();
            }

            return s;
        }
    }
}
