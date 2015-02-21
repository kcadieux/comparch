using System;
using System.Collections.Generic;
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
                Tests.Add(new Test(fileName));
            }

            InitializeComponent();
        }

        public List<Test> Tests { get; private set; }
    }
}
