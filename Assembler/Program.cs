using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Remoting.Metadata.W3cXsd2001;
using System.Text;

namespace Assembler
{
    class Program
    {
        static void Main(string[] args)
        {
            // Help option
            if (args == null || args.Length == 0 || args.Any(a => a == "-h"))
            {
                Console.Out.WriteLine("To assemble a file, use the assembler in the following way : \"MipsAssembler\" nameOfTheAssemblyFile.asm");
                return;
            }

            // Single instruction
            if (args[0] == "-i")
            {
                if (args.Count() <= 1)
                {
                    Console.Out.WriteLine("To know how to use this function, use the help (-h)");
                    return;
                }

                string tempFileName = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), "temp.asm");
                string binaryFileName = Path.Combine(Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location), "temp.dat");
                File.WriteAllText(tempFileName, args[1]);
                string error = Assemble(tempFileName);

                File.Delete(tempFileName);


                if (String.IsNullOrEmpty(error))
                {
                    Console.Out.WriteLine(File.ReadAllText(binaryFileName));
                }
                else
                {
                    Console.Out.WriteLine(error);
                }

                File.Delete(binaryFileName);
                return;
            }

            // File option
            if (!Tools.FileExists(args[0]))
            {
                Console.Out.WriteLine("The specified file cannot be found in the current folder.");
                return;
            }

            if (!Tools.IsAssembly(Tools.FullFilePath))
            {
                Console.Out.WriteLine("The specified file is not in a valid assembly format");
                return;
            }

            string objFileName = Path.Combine(Path.GetDirectoryName(Tools.FullFilePath),
                Path.GetFileNameWithoutExtension(Tools.FullFilePath)) + ".dat";
            string errorLog = Assemble(objFileName);

            if (String.IsNullOrEmpty(errorLog))
            {
                Console.Out.WriteLine("The binary file has been successfuly generated");
                return;
            }
            else
            {
                Console.Out.WriteLine("There was an error in the assembly file :");
                Console.Out.WriteLine(errorLog);
                return;
            }
        }

        public static string Assemble(string filePath)
        {
            string log = String.Empty;
            int instruction = 0;
            Dictionary<String, int> labelDictionary = new Dictionary<string, int>();
            
            var lines = File.ReadAllLines(filePath);

            string objFileName = Path.Combine(Path.GetDirectoryName(filePath),
                Path.GetFileNameWithoutExtension(filePath)) + ".dat";

            FirstPassThroughAssembly(lines, labelDictionary);
            using (var writer = new ByteWriter(objFileName))
            //using (StreamWriter writer = new StreamWriter(File.Open(objFileName, FileMode.Create)))
            {
                foreach (var line in lines)
                {
                    // Comment line
                    if (line[0] == '#')
                    {
                        continue;
                    }
                    
                    // Tokenize baby
                    var words = line.Split(' ', '\t', ',').Where(w => !String.IsNullOrEmpty(w)).ToArray();

                    if (words.Length == 0)
                    {
                        continue;
                    }

                    if (words[0].StartsWith("#"))
                    {
                        continue;
                    }

                    if (words[0].EndsWith(":"))
                    {
                        // This is a label, check if there is an instruction
                        words = words.Skip(1).Take(words.Length - 1).ToArray();
                    }
                    else if (words.Count() > 1 && words[1].StartsWith(":"))
                    {
                        words = words.Skip(1).Take(words.Length - 2).ToArray();
                    }

                    if (words.Length == 0)
                    {
                        continue;
                    }

                    Operation op = Tools.StringToOperation(words[0]);
                    if (op != Operation.None)
                    {
                        bool error = false;
                        switch (op)
                        {
                            case Operation.Add:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100000");
                                break;
                            case Operation.Sub:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100010");
                                break;
                            case Operation.Addi:
                                writer.Write("001000");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words, 16);
                                break;
                            case Operation.Mult:
                                writer.Write("000000");
                                error = !EncodingTwoRegisters(writer, ref log, words);
                                writer.Write("0000000000011000");
                                break;
                            case Operation.Div:
                                writer.Write("000000");
                                error = !EncodingTwoRegisters(writer, ref log, words);
                                writer.Write("0000000000011010");
                                break;
                            case Operation.Slt:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000101010");
                                break;
                            case Operation.Slti:
                                writer.Write("001010");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words, 16);
                                break;
                            case Operation.And:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100100");
                                break;
                            case Operation.Or:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100101");
                                break;
                            case Operation.Nor:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100111");
                                break;
                            case Operation.Xor:
                                writer.Write("000000");
                                error = !EncodingThreeRegisters(writer, ref log, words);
                                writer.Write("00000100110");
                                break;
                            case Operation.Andi:
                                writer.Write("001100");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words, 16);
                                break;
                            case Operation.Ori:
                                writer.Write("001101");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words, 16);
                                break;
                            case Operation.Xori:
                                writer.Write("001110");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words, 16);
                                break;
                            case Operation.Mfhi:
                                writer.Write("0000000000000000");
                                error = !EncodingOneRegister(writer, ref log, words);
                                writer.Write("00000010000");
                                break;
                            case Operation.Mflo:
                                writer.Write("0000000000000000");
                                error = !EncodingOneRegister(writer, ref log, words);
                                writer.Write("00000010010");
                                break;
                            case Operation.Lui:
                                writer.Write("001111");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncodingOneRegister(writer, ref log, words);
                                break;
                            case Operation.Sll:
                                writer.Write("000000");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncoding0To32TwoRegisters(writer, ref log, words);
                                writer.Write("000000");
                                break;
                            case Operation.Srl: // Due to confusing specs, I added both
                            case Operation.Slr:
                                writer.Write("000000");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncoding0To32TwoRegisters(writer, ref log, words);
                                writer.Write("000010");
                                break;
                            case Operation.Sra:
                                writer.Write("000000");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncoding0To32TwoRegisters(writer, ref log, words);
                                writer.Write("000011");
                                break;
                            case Operation.Lw:
                                writer.Write("100011");
                                error = !ImmediateEncodingTwoRegistersOffset(writer, ref log, words);
                                break;
                            case Operation.Lb:
                                writer.Write("100000");
                                error = !ImmediateEncodingTwoRegistersOffset(writer, ref log, words);
                                break;
                            case Operation.Sw:
                                writer.Write("101011");
                                error = !ImmediateEncodingTwoRegistersOffset(writer, ref log, words);
                                break;
                            case Operation.Sb:
                                writer.Write("101000");
                                error = !ImmediateEncodingTwoRegistersOffset(writer, ref log, words);
                                break;
                            case Operation.Beq:
                                writer.Write("000100");
                                error = !EncodingTwoRegisters(writer, ref log, words);
                                error &= !LabelEncodingRelative16(writer, ref log, words, labelDictionary, instruction);
                                break;
                            case Operation.Bne:
                                writer.Write("000101");
                                error = !EncodingTwoRegisters(writer, ref log, words);
                                error &= !LabelEncodingRelative16(writer, ref log, words, labelDictionary, instruction);
                                break;
                            case Operation.J:
                                writer.Write("000010");
                                error = !LabelEncoding26(writer, ref log, words, labelDictionary);
                                break;
                            case Operation.Jr:
                                writer.Write("000000");
                                error = !EncodingOneRegister(writer, ref log, words);
                                writer.Write("000000000000000001000");
                                break;
                            case Operation.Jal:
                                writer.Write("000011");
                                error = !LabelEncoding26(writer, ref log, words, labelDictionary);
                                break;
                            case Operation.Asrt:
                                writer.Write("001110");
                                error = !EncodingTwoRegisters(writer, ref log, words);
                                writer.Write("0000000000000000");
                                break;
                            case Operation.Asrti:
                                writer.Write("001111");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncodingOneRegister(writer, ref log, words);
                                break;
                            case Operation.Halt:
                                writer.Write("01000000000000000000000000000000");
                                break;
                            default:
                                break;
                        }

                        if (error)
                        {
                            break;
                        }

                        instruction++;
                    }
                }
            }

            return log;
        }

        public static void FirstPassThroughAssembly(string[] lines, Dictionary<string, int> labelDictionary)
        {
            int instruction = 0;

            foreach (var line in lines)
            {
                // Comment line
                if (line[0] == '#')
                {
                    continue;
                }

                var words = line.Split(' ', '\t', ',').Where(w => !String.IsNullOrEmpty(w)).ToArray();

                if (words.Length == 0)
                {
                    continue;
                }

                if (words[0].StartsWith("#"))
                {
                    continue;
                }

                Operation op = Tools.StringToOperation(words[0]);
                if (op == Operation.None)
                {
                    // Label
                    if (words[0].EndsWith(":") || words[1].StartsWith(":"))
                    {
                        string label = words[0].Split(':')[0];
                        labelDictionary.Add(label, instruction);
                    }
                }
                else
                {
                    instruction++;
                }
            }
        }

        public static bool LabelEncoding26(ByteWriter writer, ref string log, string[] words, Dictionary<string, int> labelDictionary)
        {
            int address;
            if (labelDictionary.TryGetValue(words[1], out address))
            {
                writer.Write(CheckAndPadForXChar(Convert.ToString(address, 2), 26));
                return true;
            }

            log += "Wrong label at line ";
            log = words.Aggregate(log, (current, word) => current + word);
            return false;
        }

        public static bool LabelEncodingRelative16(ByteWriter writer, ref string log, string[] words, Dictionary<string, int> labelDictionary, int addressCount)
        {
            int address;
            if (labelDictionary.TryGetValue(words[3], out address))
            {
                short difference = (short)(address - addressCount);
                writer.Write(CheckAndPadForXChar(Convert.ToString(difference, 2), 16));
                return true;
            }

            log += "Wrong label at line ";
            log = words.Aggregate(log, (current, word) => current + word);
            return false;
        }

        public static bool EncodingOneRegister(ByteWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 2)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            return true;
        }

        public static bool EncodingTwoRegisters(ByteWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 3)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            Register second = Tools.StringToRegister(words[2]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            return true;
        }

        public static bool EncodingThreeRegisters(ByteWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            Register second = Tools.StringToRegister(words[3]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            Register third = Tools.StringToRegister(words[1]);
            if (third == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)third, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            return true;
        }

        public static bool ImmediateEncoding0To32TwoRegisters(ByteWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);


            Register second = Tools.StringToRegister(words[1]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            short immediate = 0;
            if (Int16.TryParse(words[3], out immediate) && immediate >= 0 && immediate <= 31)
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 5);
                writer.Write(s);
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }
            
            return true;
        }

        public static bool ImmediateEncodingTwoRegisters(ByteWriter writer, ref string log, string[] words, int immediateBits)
        {
            if (words.Count() < 4)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word);
                return false;
            }

            Register dest = Tools.StringToRegister(words[2]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte) dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            Register second = Tools.StringToRegister(words[1]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            short immediate = 0;
            if (Int16.TryParse(words[3], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), immediateBits);
                writer.Write(s);
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public static bool ImmediateEncodingTwoRegistersOffset(ByteWriter writer, ref string log, string[] words)
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
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line : ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            Register second = Tools.StringToRegister(words[1]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);

            short immediate = 0;
            if (Int16.TryParse(sub[0], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 16);
                writer.Write(s);
            }
            else
            {
                log = log + "\n Error, invalid immediate value on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public static bool ImmediateEncodingOneRegister(ByteWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 3)
            {
                log = log + "\n Error, not enough parameters on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            Register dest = Tools.StringToRegister(words[1]);
            if (dest == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            var s = Convert.ToString((byte)dest, 2);
            s = CheckAndPadForXChar(s, 5);

            writer.Write(s);
            
            short immediate = 0;
            if (Int16.TryParse(words[2], out immediate))
            {
                s = CheckAndPadForXChar(Convert.ToString(immediate, 2), 16);
                writer.Write(s);
            }
            else
            {
                log = log + "\n Error, invalid immediate value or bad format on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            return true;
        }

        public static bool ImmediateEncodingZeroRegister(ByteWriter writer, ref string log, string[] words)
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
                writer.Write(s);
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
