using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace Assembler
{
    class ByteWriter : System.IDisposable
    {
        public const int BitsPerByte = 8;
        private readonly StreamWriter writer;
        private int bitIndex;

        public ByteWriter(string fileName)
        {
            writer = new StreamWriter(File.Open(fileName, FileMode.Create));
            bitIndex = 0;
        }

        // Writes one byte (8 characters) per line 
        public void Write(string s)
        {
            var charString = s.ToCharArray();
            for (int i = 0; i < charString.Count(); i++)
            {
                if (bitIndex == 32)
                {
                    bitIndex = 0;
                    writer.Write("\n");
                } 

                writer.Write(charString[i]);
                bitIndex++;
            }
        }

        public void Dispose()
        {
            writer.Dispose();
        }
    }
}
