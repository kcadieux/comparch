using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
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
        private BackgroundWorker worker;
        private static string imageDirectory = Path.Combine(Path.GetDirectoryName(AppDomain.CurrentDomain.BaseDirectory), "MIKA\\Images");

        public Test(string name)
        {
            Name = name.ToUpper();
            State = State.Unknown;
            Sync = false;
            worker = new BackgroundWorker();
            worker.DoWork += Work;
            //worker.RunWorkerCompleted += new RunWorkerCompletedEventHandler(worker_RunWorkerCompleted);
        }

        public string Name { get; private set; }

        public State State { get; private set; }

        public bool Sync { get; set; }

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

        public void Work(object sender, DoWorkEventArgs e)
        {
            runTest();
        }

        public void StartWorker()
        {
            if (Sync)
            {
                runTest();
            }
            else
            {
                worker.RunWorkerAsync();
            }
        }

        private void runTest()
        {
            var processInfo = new ProcessStartInfo("cmd.exe", "/c" + "\"CPUS\\unpipelined_cpu\\scripts\\RunTest.bat " + Name.ToLower() + "\"");

            processInfo.CreateNoWindow = true;

            processInfo.UseShellExecute = false;

            processInfo.RedirectStandardError = true;
            processInfo.RedirectStandardOutput = true;

            var process = Process.Start(processInfo);

            process.Start();

            process.WaitForExit();

            string output = process.StandardOutput.ReadToEnd();
            if (output.Contains("SUCCESS"))
            {
                State = State.Pass;
            }
            else
            {
                State = State.Fail;
            }

            OnChanged("ImageSource");
            OnChanged("TextColor");
            OnChanged("Status"); 
        }


        public event PropertyChangedEventHandler PropertyChanged;

        void OnChanged(string pn)
        {
            if (PropertyChanged != null)
            {
                PropertyChanged(this, new PropertyChangedEventArgs(pn));
            }
        }
    }
}
