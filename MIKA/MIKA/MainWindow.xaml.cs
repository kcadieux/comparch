using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading;
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
using DataGrid = System.Windows.Controls.DataGrid;
using Path = System.IO.Path;

namespace MIKA
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public bool busyThread;
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
                Tests.Add(new Test(fileName, File.ReadAllText(testName), testName, this));
            }

            OnNeedsUI += (s, e) =>
            {
                Dispatcher.Invoke((Action)delegate() { ChangeCursor(); });
            };

            busyThread = false;
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
            get { return new RelayCommand(param => runAllTests(), param => true); }
        }

        public ICommand RunSelectedTests
        {
            get { return new RelayCommand(param => runSelectedTests(), param => true); }
        }

        public ICommand AddNewTest
        {
            get { return new RelayCommand(param => addNewTest(), param => true); }
        }

        public List<Test> Tests { get; private set; }

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
            if (overallTests == 0)
            {
                ProgressBar.Value = 100;
            }
            else
            {
                ProgressBar.Value = 100 - ((float)testsRunning / (float)overallTests) * 100;
            }            

            if (testsRunning <= 0)
            {
                CursorToArrow();
            }
        }

        public void CursorToWait()
        {
            Cursor = Cursors.AppStarting;
        }

        public void CursorToArrow()
        {
            Cursor = Cursors.Arrow;
        }

        private void runSelectedTests()
        {
            if (busyThread)
            {
                return;
            }

            if (Tests.Count(t => t.Selected) == 0)
            {
                return;
            }

            ProgressBar.Value = 0;
            testsRunning = overallTests = Tests.Count(t => t.Selected);

            Cursor = Cursors.AppStarting;
            var s = new Thread(WorkerThreadRunSelected);
            s.Start();
        }

        private void addNewTest()
        {
            if (String.IsNullOrWhiteSpace(TestName.Text))
            {
                //TODO add warning msg
                return;
            }

            string newFileName = Path.Combine("CPUS\\unpipelined_cpu\\tests", TestName.Text + ".asm");

            if (File.Exists(newFileName))
            {
                //TODO add msg
                return;
            }

            File.Create(newFileName);
            var newTest = new Test(TestName.Text, string.Empty, newFileName, this);
            Tests.Add(newTest);
            Tests = Tests.OrderBy(t => t.Name).ToList();
            TestDataGrid.ItemsSource = null;
            TestDataGrid.ItemsSource = Tests;
            TestDataGrid.SelectedItem = TestDataGrid.Items[Tests.IndexOf(newTest)];
            TestDataGrid.Focus();
            //TestDataGrid.GetBindingExpression(ItemsControl.ItemsSourceProperty).UpdateTarget();
        }

        private void runAllTests()
        {
            if (busyThread)
            {
                return;
            }

            ProgressBar.Value = 0;
            testsRunning = overallTests = Tests.Count;
            Cursor = Cursors.AppStarting;

            var t = new Thread(WorkerThreadRunAll);
            t.Start();
        }

        private void WorkerThreadRunAll()
        {
            busyThread = true;
            Test.PreTest();
            foreach (var test in Tests)
            {
                test.runTest();
            }
            busyThread = false;
        }

        private void WorkerThreadRunSelected()
        {
            busyThread = true;
            List<Test> tsts = Tests.Where(t => t.Selected).ToList();
            Test.PreTest();
            foreach (var test in tsts)
            {
                test.runTest();
            }
            busyThread = false;
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

        public static object DeepCopy(object obj)
        {
            if (obj == null)
                return null;
            Type type = obj.GetType();

            if (type.IsValueType || type == typeof(string))
            {
                return obj;
            }
            else if (type.IsArray)
            {
                Type elementType = Type.GetType(
                     type.FullName.Replace("[]", string.Empty));
                var array = obj as Array;
                Array copied = Array.CreateInstance(elementType, array.Length);
                for (int i = 0; i < array.Length; i++)
                {
                    copied.SetValue(DeepCopy(array.GetValue(i)), i);
                }
                return Convert.ChangeType(copied, obj.GetType());
            }
            else if (type.IsClass)
            {

                object toret = Activator.CreateInstance(obj.GetType());
                FieldInfo[] fields = type.GetFields(BindingFlags.Public |
                            BindingFlags.NonPublic | BindingFlags.Instance);
                foreach (FieldInfo field in fields)
                {
                    object fieldValue = field.GetValue(obj);
                    if (fieldValue == null)
                        continue;
                    field.SetValue(toret, DeepCopy(fieldValue));
                }
                return toret;
            }
            else
                throw new ArgumentException("Unknown type");
        }
    }
}
