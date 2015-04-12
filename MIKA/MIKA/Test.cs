using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

namespace MIKA
{
    public enum State
    {
        Unknown,
        Pass,
        Fail
    }

    public class Test : INotifyPropertyChanged
    {
        private string code;
        private readonly string path;
        private bool selected;
        private MainWindow mainWindow;
        private BackgroundWorker worker;
        private static string imageDirectory = Path.Combine(Path.GetDirectoryName(AppDomain.CurrentDomain.BaseDirectory), "MIKA\\Images");

        public Test(string name, string code, string path, MainWindow mainWindow)
        {
            this.code = code;
            this.path = path;
            Log = String.Empty;
            DisplayLog = false;
            Name = name.ToUpper();
            State = State.Unknown;
            selected = false;
            worker = new BackgroundWorker();
            worker.DoWork += Work;
            this.mainWindow = mainWindow;
            //worker.RunWorkerCompleted += new RunWorkerCompletedEventHandler(worker_RunWorkerCompleted);
        }

        public string Code
        {
            get { return code; }

            set
            {
                File.WriteAllText(path, value);
                code = value;
            }
        }

        public bool DisplayLog { get; private set; }

        public string Log { get; private set; }

        public string Name { get; private set; }

        public State State { get; private set; }

        public int Cycles { get; private set; }

        public int Branches { get; private set; }
        
        public double Accuracy { get; private set; }

        public bool Selected 
        {
            get
            {
                return selected;
            }

            set
            {
                selected = value;
                mainWindow.RefreshSelectedText();
            }
        }
        
        public string ImageSource
        {
            get
            {
                switch (State)
                {
                    case State.Unknown: return Path.Combine(imageDirectory, "unknown.png");
                    case State.Pass: return Path.Combine(imageDirectory, "pass.png");
                    case State.Fail: return Path.Combine(imageDirectory, "fail.png");
                }

                throw new InvalidOperationException();
            }
        }

        public string Status
        {
            get
            {
                switch (State)
                {
                    case State.Unknown:
                        return "Unknown";
                    case State.Pass:
                        return "Pass";
                    case State.Fail:
                        return "Fail";
                }

                throw new InvalidOperationException();
            }
        }

        public Brush TextColor
        {
            get
            {
                switch (State)
                {
                    case State.Unknown:
                        return new SolidColorBrush(Colors.DarkOrange);
                    case State.Pass:
                        return new SolidColorBrush(Colors.ForestGreen);
                    case State.Fail:
                        return new SolidColorBrush(Colors.Red);
                }

                throw new InvalidOperationException();
            }
        }

        public ICommand RunTest
        {
            get { return new RelayCommand(param => StartWorker(), param => true); }
        }

        public ICommand LiveCPU
        {
            get { return new RelayCommand(param => StartLiveCPU(), param => true); }
        }

        public void Work(object sender, DoWorkEventArgs e)
        {
            PreTest();
            runTest();
        }

        public void StartWorker()
        {
            if (!worker.IsBusy && !mainWindow.busyThread)
            {
                mainWindow.CursorToWait();
                worker.RunWorkerAsync();
            }
        }

        public void RunTestAsync()
        {
            worker.RunWorkerAsync();
        }

        public void runTest()
        {
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "CPUS\\cpu\\scripts\\RunTest.bat";
            startInfo.Arguments = Name.ToLower();
            startInfo.RedirectStandardOutput = true;
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;
            startInfo.WindowStyle = ProcessWindowStyle.Hidden;
            
            using (Process exeProcess = Process.Start(startInfo))
            {
                exeProcess.WaitForExit();
                Log = exeProcess.StandardOutput.ReadToEnd();
            }
            string tempLog = "";

            if (Log.Contains("SUCCESS"))
            {
                State = State.Pass;
                tempLog = Log;
                Log = String.Empty;
                DisplayLog = false;
            }
            else
            {
                var splitted = Log.Split('\n');
                foreach (var s in splitted)
                {
                    if (s.Contains("FAILURE"))
                    {
                        Log = s;
                        break;
                    }
                }
                State = State.Fail;
                DisplayLog = true;
            }

            var rawStats = Regex.Split(tempLog, "cycles: ");
            if (rawStats.Count() > 1)
            {
                var stats = rawStats[1].Split(' ','\r','\n');
                Cycles = Convert.ToInt32(stats[0]);
                Branches = Convert.ToInt32(stats[3]);
                if (Branches != 0)
                {
                    Accuracy = ((float) Branches - (float) Convert.ToInt32(stats[6]))/(float) Branches*100.0f;
                }
            }

            OnChanged("ImageSource");
            OnChanged("TextColor");
            OnChanged("Status");
            OnChanged("Log");
            OnChanged("Cycles");
            OnChanged("Branches");
            OnChanged("Accuracy");
            //OnChanged("DisplayLog");

            mainWindow.TestDone();
        }

        private void StartLiveCPU()
        {
            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "LiveCPU.bat";
            startInfo.Arguments = Name;
            startInfo.RedirectStandardOutput = true;
            startInfo.UseShellExecute = false;
            startInfo.CreateNoWindow = true;
            startInfo.WindowStyle = ProcessWindowStyle.Hidden;

            using (Process exeProcess = Process.Start(startInfo))
            {
                //exeProcess.WaitForExit();
            }
        }

        public event PropertyChangedEventHandler PropertyChanged;

        void OnChanged(string pn)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(pn));
            }
        }

        // Delete the Work directory in Quartus and Compile again
        public static void PreTest()
        {
            //try
            //{
            //    if (Directory.Exists("CPUS\\cpu\\quartus\\work"))
            //    {
            //        DeleteDirectory("CPUS\\cpu\\quartus\\work");
            //    }
            //}
            //catch (Exception)
            //{
            //}

            //ProcessStartInfo startInfo = new ProcessStartInfo();
            //startInfo.FileName = "CPUS\\cpu\\scripts\\Compile.bat";
            //startInfo.RedirectStandardOutput = true;
            //startInfo.UseShellExecute = false;
            //startInfo.CreateNoWindow = true;
            //startInfo.WindowStyle = ProcessWindowStyle.Hidden;

            //using (Process exeProcess = Process.Start(startInfo))
            //{
            //    exeProcess.WaitForExit();
            //}
        }

        public static void DeleteDirectory(string targetDir)
        {
            File.SetAttributes(targetDir, FileAttributes.Normal);

            string[] files = Directory.GetFiles(targetDir);
            string[] dirs = Directory.GetDirectories(targetDir);

            foreach (string file in files)
            {
                if (File.Exists(file))
                {
                    File.SetAttributes(file, FileAttributes.Normal);
                    File.Delete(file);
                }
            }

            foreach (string dir in dirs)
            {
                DeleteDirectory(dir);
            }

            Directory.Delete(targetDir, false);
        }
    }
}
