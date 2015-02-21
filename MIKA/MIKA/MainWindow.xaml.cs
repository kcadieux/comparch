using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace MIKA
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
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

            InitializeComponent();
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

        public void RefreshSelectedText()
        {
            SelectedButton.GetBindingExpression(Button.ContentProperty).UpdateTarget();
        }

        private void RunSelectedTestsWorker()
        {
            foreach (var test in Tests.Where(t => t.Selected))
            {
                test.StartWorker();
            }
        }

        private void RunAllTestsWorker()
        {
            foreach (var test in Tests)
            {
                test.StartWorker();
            }
        }

        private void RowDoubleClick(object sender, RoutedEventArgs e)
        {
            var row = (DataGridRow)sender;
            row.DetailsVisibility = row.DetailsVisibility == Visibility.Collapsed ?
                Visibility.Visible : Visibility.Collapsed;
        }

        public event DependencyPropertyChangedEventHandler PropertyChanged;
    }
}
