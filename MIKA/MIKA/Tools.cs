using System;
using System.Collections.Generic;
using System.IO;

namespace MIKA
{
    public static class Tools
    {
        public static string[] GetListOfTests(string path)
        {
            if (!File.Exists(path))
            {
                throw new FileNotFoundException(path);
            }

            var lines = new List<String>();

            using (var fileReader = new StreamReader(new FileStream(path, FileMode.Open)))
            {
                while (fileReader.Peek() != -1)
                {
                    var s = fileReader.ReadLine();
                    if (String.IsNullOrEmpty(s))
                    {
                        continue;
                    }

                    lines.Add(s);
                }
            }

            return lines.ToArray();
        }
    }
}
