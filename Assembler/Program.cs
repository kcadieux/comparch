using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.Remoting.Metadata.W3cXsd2001;
using System.Text;

namespace Assembler
{
    class Program
    {
        Dictionary<String, int> LabelDictionary;

        static void Main(string[] args)
        {
            new Program(args);
        }

        public List<Instruction> Instructions = new List<Instruction>(); 
        public static string ApplicationDirectory =
            Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
        public Program(string[] args)
        {
            // Help option
            if (args == null || args.Length == 0 || args.Any(a => a == "-h"))
            {
                Console.Out.WriteLine("To assemble a file, use the assembler in the following way : \"MipsAssembler\" nameOfTheAssemblyFile.asm");
                return;
            }

            using (var writer = new StringWriter())
            {
                // Single instruction
                if (args[0] == "-i")
                {
                    if (args.Count() <= 1)
                    {
                        Console.Out.WriteLine("To know how to use this function, use the help (-h)");
                        return;
                    }

                    using (var reader = new StringReader(args[1]))
                    {
                        string error = Assemble(reader, writer, false);

                        if (String.IsNullOrEmpty(error))
                        {
                            Console.Out.WriteLine(writer.ToString());
                        }
                        else
                        {
                            Console.Out.WriteLine(error);
                        }

                        return;
                    }
                    
                }

                // File option
                string asmName = Path.Combine(ApplicationDirectory, args[0]);
                if (!Tools.FileExists(asmName))
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


                using (var fileReader = new StreamReader(new FileStream(asmName, FileMode.Open)))
                using (var byteWriter = new ByteWriter(objFileName))
                {
                    string errorLog = Assemble(fileReader, writer, true);

                    if (String.IsNullOrEmpty(errorLog))
                    {
                        Console.Out.WriteLine("The binary file has been successfuly generated.");
                        Console.Out.WriteLine("Now checking to reorder some of the code.");
                        Reorder();

                        foreach (var instruct in Instructions)
                        {
                            writer.Write(instruct.MachineCode);
                        }

                        byteWriter.Write(writer.ToString());
                        return;
                    }

                        Console.Out.WriteLine("There was an error in the assembly file :");
                        Console.Out.WriteLine(errorLog);
                        return;
                }
            }

            
        }

        public void Reorder()
        {
            int instructionNumber = 0;
            foreach (var instruction in Instructions)
            {
                List<Register> forbidden = new List<Register>();
                if (instruction.Operation == Operation.Lw)
                {
                    if (instructionNumber + 1 == Instructions.Count)
                    {
                        continue;
                    }


                    if ((Instructions.ElementAt(instructionNumber + 1).RegisterD == instruction.RegisterS ||
                        Instructions.ElementAt(instructionNumber + 1).RegisterT == instruction.RegisterS) &&
                        Instructions.ElementAt(instructionNumber + 1).Operation != Operation.Asrt &&
                        Instructions.ElementAt(instructionNumber + 1).Operation != Operation.Asrti &&
                        Instructions.ElementAt(instructionNumber + 1).Operation != Operation.Halt &&
                        Instructions.ElementAt(instructionNumber + 1).Operation != Operation.Beq &&
                        Instructions.ElementAt(instructionNumber + 1).Operation != Operation.Bne)
                    {
                        // Need a swap
                        forbidden.Add(instruction.RegisterS);
                        var potentialSwaps = Instructions.GetRange(instructionNumber + 2, Instructions.Count - instructionNumber - 2);
                        int potentialInstructionIndex = instructionNumber + 2;
                        foreach (var potentialInst in potentialSwaps)
                        {
                            if (potentialInst.Operation == Operation.Beq ||
                                potentialInst.Operation == Operation.Bne ||
                                potentialInst.Operation == Operation.J ||
                                potentialInst.Operation == Operation.Halt ||
                                potentialInst.Operation == Operation.Asrt ||
                                potentialInst.Operation == Operation.Asrti)
                            {
                                break;
                            }

                            if (LabelDictionary.Values.Contains(potentialInstructionIndex))
                            {
                                break;
                            }
                            
                            if (!forbidden.Contains(potentialInst.RegisterD) &&
                                !forbidden.Contains(potentialInst.RegisterS) &&
                                !forbidden.Contains(potentialInst.RegisterT))
                            {
                                // Swapping
                                var regD = Instructions.ElementAt(instructionNumber + 1).RegisterD;
                                var regS = Instructions.ElementAt(instructionNumber + 1).RegisterS;
                                var regT = Instructions.ElementAt(instructionNumber + 1).RegisterT;
                                var op = Instructions.ElementAt(instructionNumber + 1).Operation;
                                var mc = Instructions.ElementAt(instructionNumber + 1).MachineCode;
                                Instructions.ElementAt(instructionNumber + 1).Swap(Instructions.ElementAt(potentialInstructionIndex));
                                Instructions.ElementAt(potentialInstructionIndex).SwapRegisterD(regD);
                                Instructions.ElementAt(potentialInstructionIndex).SwapRegisterS(regS);
                                Instructions.ElementAt(potentialInstructionIndex).SwapRegisterT(regT);
                                Instructions.ElementAt(potentialInstructionIndex).SwapOperation(op);
                                Instructions.ElementAt(potentialInstructionIndex).SwapMachineCode(mc);
                                break;
                            }
                            else
                            {
                                if (potentialInst.RegisterD != Register.NONE && potentialInst.RegisterD != Register.Zero)
                                {
                                    forbidden.Add(potentialInst.RegisterD);
                                }

                                if (potentialInst.RegisterT != Register.NONE && potentialInst.RegisterT != Register.Zero)
                                {
                                    forbidden.Add(potentialInst.RegisterT);
                                }

                                if (potentialInst.RegisterS != Register.NONE && potentialInst.RegisterS != Register.Zero)
                                {
                                    forbidden.Add(potentialInst.RegisterS);
                                }
                            }

                            potentialInstructionIndex++;
                        }
                    }
                }

                instructionNumber++;
            }
        }

        public string Assemble(TextReader source, StringWriter writer, bool labelPass)
        {
            string log = String.Empty;
            int instruction = 0;
            Dictionary<String, int> labelDictionary = new Dictionary<string, int>();
            
            //var lines = File.ReadAllLines(filePath);

            var lines = new List<String>();
            while (source.Peek() != -1)
            {
                lines.Add(source.ReadLine());
            }

            if (labelPass)
            {
                FirstPassThroughAssembly(lines, labelDictionary);  
            }
            
            foreach (var line in lines)
            {
                bool error = false;

                // Comment line
                if (String.IsNullOrEmpty(line) || line[0] == '#')
                {
                    if (labelPass)
                    {
                        continue;
                    }

                    return "error in instruction";
                }
                    
                // Tokenize baby
                var words = line.Split(' ', '\t', ',').Where(w => !String.IsNullOrEmpty(w)).ToArray();

                if (words.Length == 0)
                {
                    if (labelPass)
                    {
                        continue;
                    }

                    return "error in instruction";
                }

                if (words[0].StartsWith("#"))
                {
                    if (labelPass)
                    {
                        continue;
                    }

                    return "error in instruction";
                }

                if (labelPass)
                {
                    if (words[0].EndsWith(":"))
                    {
                        // This is a label, check if there is an instruction
                        words = words.Skip(1).Take(words.Length - 1).ToArray();
                    }
                    else if (words.Count() > 1 && words[1].StartsWith(":"))
                    {
                        words = words.Skip(1).Take(words.Length - 2).ToArray();
                    }

                    if (words.Length == 0) continue;
                }

                Operation op = Tools.StringToOperation(words[0]);
                if (op != Operation.None)
                {
                    var inst = new Instruction(op, words, instruction, ref labelDictionary, ref log);
                    Instructions.Add(inst);
                    //writer.Write(inst.MachineCode);

                    if (inst.Error)
                    {
                        break;
                    }

                    instruction++;
                }
                else if (!labelPass)
                {
                    return "error in instruction";
                }
            }

            LabelDictionary = labelDictionary;
            return log;
        }

        public static void FirstPassThroughAssembly(List<String> lines, Dictionary<string, int> labelDictionary)
        {
            int instruction = 0;
            int lineNumber = 0; 
            foreach (var line in lines)
            {
                // Comment line
                if (String.IsNullOrEmpty(line) || line[0] == '#')
                {
                    lineNumber++;
                    continue;
                }

                var words = line.Split(' ', '\t', ',').Where(w => !String.IsNullOrEmpty(w)).ToArray();

                if (words.Length == 0)
                {
                    lineNumber++;
                    continue;
                }

                if (words[0].StartsWith("#"))
                {
                    lineNumber++;
                    continue;
                }

                Operation op = Tools.StringToOperation(words[0]);
                if (op == Operation.None)
                {
                    // Label
                    if (words[0].EndsWith(":") || (words.Count() >= 2 && words[1].StartsWith(":")))
                    {
                        string label = words[0].Split(':')[0];
                        labelDictionary.Add(label, instruction);

                        //If the LABEL line also contains an instruction, count it
                        if (words.Length > 1 && Tools.StringToOperation(words[1]) != Operation.None)
                        {
                            instruction++;
                        }
                    }
                }
                else
                {
                    instruction++;
                }
                
                lineNumber++;
            }
        }

        public static bool LabelEncoding26(StringWriter writer, ref string log, string[] words, Dictionary<string, int> labelDictionary)
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

        public static bool LabelEncodingRelative16(StringWriter writer, ref string log, string[] words, Dictionary<string, int> labelDictionary, int addressCount)
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

        public static bool EncodingOneRegister(StringWriter writer, ref string log, string[] words)
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

        public static bool EncodingTwoRegisters(StringWriter writer, ref string log, string[] words)
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

        public static bool EncodingThreeRegisters(StringWriter writer, ref string log, string[] words)
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

        public static bool ImmediateEncoding0To32TwoRegisters(StringWriter writer, ref string log, string[] words)
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

        public static bool ImmediateEncodingTwoRegisters(StringWriter writer, ref string log, string[] words, int immediateBits)
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

        public static bool ImmediateEncodingTwoRegistersOffset(StringWriter writer, ref string log, string[] words)
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

        public static bool ImmediateEncodingOneRegister(StringWriter writer, ref string log, string[] words)
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

        public static bool ImmediateEncodingZeroRegister(StringWriter writer, ref string log, string[] words)
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
