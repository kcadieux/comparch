using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Button = System.Windows.Controls.Button;
using Cursors = System.Windows.Input.Cursors;

namespace MIKA
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private int testsRunning, overallTests;
        public MainWindow()
        {
            DataContext = this;
            var myLinearGradientBrush = new LinearGradientBrush
            {
                StartPoint = new Point(0, 0),
                EndPoint = new Point(0, 1)
            };

            myLinearGradientBrush.GradientStops.Add(
                new GradientStop(Colors.LightSteelBlue, 0.0));
            myLinearGradientBrush.GradientStops.Add(
                new GradientStop(Colors.LightSlateGray, 0.25));

            Background = myLinearGradientBrush;
            Tests = new List<Test>();
            var testNames = System.IO.Directory.GetFiles("CPUS\\unpipelined_cpu\\tests", "*.asm");
            foreach (var testName in testNames)
            {
                string fileNameWithExtension = testName.Split('\\')[3];
                string fileName = fileNameWithExtension.Substring(0, fileNameWithExtension.Length - 4);
                Tests.Add(new Test(fileName, File.ReadAllText(testName), this));
            }

            OnNeedsUI += (s, e) =>
            {
                Dispatcher.Invoke((Action)delegate() { ChangeCursor(); });
            };

            testsRunning = 0;
            InitializeComponent();
            ProgressBar.Value = 100;
        }

        public string RunAllText
        {
            get { return "Run all " + Tests.Count + " Tests"; }
        }

        public string RunSelectedText
        {
            get { return "Run " + Tests.Count(t => t.Selected) + " Selected Tests"; }
        }

        public ICommand RunAllTests
        {
            get { return new RelayCommand(param => RunAllTestsWorker(), param => true); }
        }

        public ICommand RunSelectedTests
        {
            get { return new RelayCommand(param => RunSelectedTestsWorker(), param => true); }
        }

        public List<Test> Tests { get; private set; }

        public bool Sync { get; set; }

        public void RefreshSelectedText()
        {
            SelectedButton.GetBindingExpression(Button.ContentProperty).UpdateTarget();
        }

        public void TestDone()
        {
            testsRunning--;
            RaiseOnNeedsUI();
        }

        private void ChangeCursor()
        {
            ProgressBar.Value = 100 - ((float)testsRunning / (float)overallTests) * 100;

            if (testsRunning <= 0)
            {
                Cursor = Cursors.Arrow;
            }
        }
        
        private void RunSelectedTestsWorker()
        {
            if (Tests.Count(t => t.Selected) == 0)
            {
                return;
            }

            ProgressBar.Value = 0;
            testsRunning = overallTests = Tests.Count(t => t.Selected);
            foreach (var test in Tests.Where(t => t.Selected))
            {
                if (Sync)
                {
                    test.runTest();
                }
                else
                {
                    test.StartWorker();
                }
            }

            Cursor = Cursors.AppStarting;
        }

        private void RunAllTestsWorker()
        {
            ProgressBar.Value = 0;
            testsRunning = overallTests = Tests.Count;
            Cursor = Cursors.AppStarting;
            foreach (var test in Tests)
            {
                if (Sync)
                {
                    test.runTest();
                }
                else
                {
                    test.StartWorker();
                }
            }
        }

        private void RowDoubleClick(object sender, RoutedEventArgs e)
        {
            var row = (DataGridRow)sender;
            row.DetailsVisibility = row.DetailsVisibility == Visibility.Collapsed ?
                Visibility.Visible : Visibility.Collapsed;
        }

        //  Create a Customer Event that your UI will Register with
        public static event EventHandler<EventArgs> OnNeedsUI;
        private static void RaiseOnNeedsUI()
        {
            if (OnNeedsUI != null)
                OnNeedsUI(null, EventArgs.Empty);
        }
    }
}
