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

            string errorLog = Assemble();

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

        public static string Assemble()
        {
            string log = String.Empty;

            string objFileName = Path.Combine(Path.GetDirectoryName(Tools.FullFilePath),
                Path.GetFileNameWithoutExtension(Tools.FullFilePath)) + ".dat";
            var lines = File.ReadAllLines(Tools.FullFilePath);
            using (BinaryWriter writer = new BinaryWriter(File.Open(objFileName, FileMode.Create)))
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

                    Operation op = Tools.StringToOperation(words[0]);
                    if (op != Operation.None)
                    {
                        //TODO
                        bool error = false;
                        switch (op)
                        {
                            case Operation.Addi:
                                writer.Write("001000");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Andi:
                                writer.Write("001100");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Slti:
                                writer.Write("001010");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Ori:
                                writer.Write("001101");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Xori:
                                writer.Write("001110");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Lui:
                                writer.Write("001111");
                                writer.Write("00000"); // Ignored by processor
                                error = !ImmediateEncodingOneRegister(writer, ref log, words);
                                break;
                            case Operation.Lw:
                                writer.Write("100011");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Sw:
                                writer.Write("101011");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Lb:
                                writer.Write("100000");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Sb:
                                writer.Write("101000");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Beq:
                                writer.Write("000100");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.Bne:
                                writer.Write("000101");
                                error = !ImmediateEncodingTwoRegisters(writer, ref log, words);
                                break;
                            case Operation.J:
                                writer.Write("000010");
                                error = !ImmediateEncodingZeroRegister(writer, ref log, words);
                                break;

                            default:
                                break;
                        }

                        if (error)
                        {
                            break;
                        }

                        writer.Write("\n");
                    }
                    else
                    {
                        // Label
                        //TODO
                    }
                }
            }

            return log;
        }

        public static bool ImmediateEncodingTwoRegisters(BinaryWriter writer, ref string log, string[] words)
        {
            if (words.Count() < 4)
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

            var s = Convert.ToString((byte) dest, 2);
            s = CheckForXChar(s, 5);

            writer.Write(s);

            Register second = Tools.StringToRegister(words[2]);
            if (second == Register.NONE)
            {
                log = log + "\n Error on the line :  ";
                log = words.Aggregate(log, (current, word) => current + word + " ");
                return false;
            }

            s = Convert.ToString((byte)second, 2);
            s = CheckForXChar(s, 5);

            writer.Write(s);

            short immediate = 0;
            if (Int16.TryParse(words[3], out immediate))
            {
                s = CheckForXChar(Convert.ToString(immediate, 2), 16);
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

        public static bool ImmediateEncodingOneRegister(BinaryWriter writer, ref string log, string[] words)
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
            s = CheckForXChar(s, 5);

            writer.Write(s);
            
            short immediate = 0;
            if (Int16.TryParse(words[2], out immediate))
            {
                s = CheckForXChar(Convert.ToString(immediate, 2), 16);
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

        public static bool ImmediateEncodingZeroRegister(BinaryWriter writer, ref string log, string[] words)
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
            s = CheckForXChar(s, 5);

            writer.Write(s);

            short immediate = 0;
            if (Int16.TryParse(words[2], out immediate))
            {
                s = CheckForXChar(Convert.ToString(immediate, 2), 16);
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

        public static string CheckForXChar(string s, int amountOfChar)
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
