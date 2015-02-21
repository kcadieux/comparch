using System;

public static class Tools
{
	public Tools()
	{
        public static string[] GetListOfTests(string path)
        {
            Path.CheckifExist();
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
