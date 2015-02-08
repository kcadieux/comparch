using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
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
            var lines = File.ReadAllLines(Tools.FullFilePath);

            foreach (var line in lines)
            {
                // Comment line
                if (line[0] == '#')
                {
                    continue;
                }

                // Label
                if (line[0] != ' ' && line[0] != '\t')
                {
                    //TODO
                }

                // Tokenize baby
                var words = line.Split(' ', '\t', ',');

                if (words.Length == 0)
                {
                    continue;
                }

                if (words[0].StartsWith("#"))
                {
                    continue;
                }

                Operation op = Operation.Add;
                if (Tools.StringToOperation(words[0], op))
                {
                    //TODO
                }
                else
                {
                    // Label
                    //TODO
                }
            }

            return log;
        }
    }
}
