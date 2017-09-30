/*
    Author: Alex Yoo
    Content: Gets tables and columns from database and replace in script
    Usage: console
*/
using Microsoft.SqlServer.Management.Common;
using Microsoft.SqlServer.Management.Smo;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace AppDataRefresh_SPScript2
{
    internal class DataRefreshTable
    {
        public string TableName { get; set; }
        public string TableNameSS { get; set; }
        public string ColumnList { get; set; }
        public string ColumnListAA { get; set; }
        public string ColumnListUpdate { get; set; }
    }

    internal class AppDataRefresh_SPScript
    {
        private static void Main(string[] args)
        {
            CreateScripts();
        }

        /* Stream reader and writer to make scripts. */
        public static void CreateScripts()
        {
            List<DataRefreshTable> DataTablesRaw = GetDataRefreshTables();
            List<DataRefreshTable> DataTables = DataTablesRaw.OrderBy((DataRefreshTable i) => i.TableName == "CarrierProducts")
                .ThenBy(i => i.TableName == "RateTables")
                .ThenBy(i => i.TableName == "CarrierProductPlanOptions")
                .ThenBy(i => i.TableName == "CarrierProductRiders")
                .ThenBy(i => i.TableName == "Rates_RateTableModalRoundingOverrides")
                .ThenBy(i => i.TableName == "RateTableDetails")
                .ThenBy(i => i.TableName == "CarrierProductRiderPlanOptions")
                .ThenBy(i => i.TableName == "PlanReference_ProductBenefitValues")
                .ThenBy(i => i.TableName == "Rates_ModalRates")
                .ThenBy(i => i.TableName == "PlanReference_RiderBenefitValues")
                .Reverse<DataRefreshTable>()
                .ToList<DataRefreshTable>();
            string AssemblyPath = Assembly.GetExecutingAssembly().Location;
            string ExternalFilePath = Path.GetDirectoryName(Path.GetDirectoryName(Path.GetDirectoryName(AssemblyPath)));
            string InputFile1 = Path.Combine(ExternalFilePath, "ExternalFiles", "InputScript1.txt");
            string InputFile2 = Path.Combine(ExternalFilePath, "ExternalFiles", "InputScript2.txt");
            string InputFile3 = Path.Combine(ExternalFilePath, "ExternalFiles", "InputScript3.txt");
            string OutputFile1 = Path.Combine(ExternalFilePath, "ExternalFiles", "OutputScript1.txt");
            string OutputFile2 = Path.Combine(ExternalFilePath, "ExternalFiles", "OutputScript2.txt");
            string OutputFile3 = Path.Combine(ExternalFilePath, "ExternalFiles", "OutputScript3.txt");
            File.Delete(OutputFile1);
            File.Delete(OutputFile2);
            File.Delete(OutputFile3);

            string input = String.Empty;
            using (StreamReader sr = new StreamReader(InputFile1))
            {
                input = sr.ReadToEnd();
            }

            foreach (DataRefreshTable DataTable in DataTables)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append(input);
                sb.Replace("<TableName>", DataTable.TableName);
                sb.Replace("<TableNameSS>", DataTable.TableNameSS);
                sb.Replace("<ColumnList>", DataTable.ColumnList);
                sb.Replace("<ColumnListAA>", DataTable.ColumnListAA);
                sb.Replace("<ColumnListUpdate>", DataTable.ColumnListUpdate);
                using (StreamWriter sw = new StreamWriter(OutputFile1, true))
                {
                    sw.WriteLine(sb);
                }
            }

            string input2 = String.Empty;
            using (StreamReader sr = new StreamReader(InputFile2))
            {
                input2 = sr.ReadToEnd();
            }

            foreach (DataRefreshTable DataTable in DataTables)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append(input2);
                sb.Replace("<TableName>", DataTable.TableName);
                sb.Replace("<TableNameSS>", DataTable.TableNameSS);
                sb.Replace("<ColumnList>", DataTable.ColumnList);
                sb.Replace("<ColumnListAA>", DataTable.ColumnListAA);
                sb.Replace("<ColumnListUpdate>", DataTable.ColumnListUpdate);
                using (StreamWriter sw = new StreamWriter(OutputFile2, true))
                {
                    sw.WriteLine(sb);
                }
            }

            string input3 = String.Empty;
            using (StreamReader sr = new StreamReader(InputFile3))
            {
                input3 = sr.ReadToEnd();
            }

            foreach (DataRefreshTable DataTable in DataTables)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append(input3);
                sb.Replace("<TableName>", DataTable.TableName);
                sb.Replace("<TableNameSS>", DataTable.TableNameSS);
                sb.Replace("<ColumnList>", DataTable.ColumnList);
                sb.Replace("<ColumnListAA>", DataTable.ColumnListAA);
                sb.Replace("<ColumnListUpdate>", DataTable.ColumnListUpdate);
                using (StreamWriter sw = new StreamWriter(OutputFile3, true))
                {
                    sw.WriteLine(sb);
                }
            }
        }

        /* Connect to database and get table and column lists. */
        public static List<DataRefreshTable> GetDataRefreshTables()
        {
            string DummyConnString = ConfigurationManager.ConnectionStrings["Test"].ConnectionString;
            SqlConnectionStringBuilder DummyConnStringBuilder = new SqlConnectionStringBuilder(DummyConnString);
            SqlConnection DummySqlConn = new SqlConnection(DummyConnString);
            ServerConnection DummyServerConn = new ServerConnection(DummySqlConn);
            Server DummyServer = new Server(DummyServerConn);
            Database DummyDatabase = DummyServer.Databases[DummyConnStringBuilder.InitialCatalog];

            List<DataRefreshTable> DummyTables = new List<DataRefreshTable>();
            foreach (Table DummyTable in DummyDatabase.Tables)
            {
                if (DummyTable.ToString() == "[dbo].[CarrierProducts]" || DummyTable.ToString() == "[dbo].[CarrierProductPlanOptions]" || DummyTable.ToString() == "[dbo].[CarrierProductRiders]" || DummyTable.ToString() == "[dbo].[CarrierProductRiderPlanOptions]" || DummyTable.ToString() == "[dbo].[RateTables]" || DummyTable.ToString() == "[dbo].[RateTableDetails]" || DummyTable.ToString() == "[dbo].[Rates_ModalRates]" || DummyTable.ToString() == "[dbo].[Rates_RateTableModalRoundingOverrides]" || DummyTable.ToString() == "[dbo].[PlanReference_ProductBenefitValues]" || DummyTable.ToString() == "[dbo].[PlanReference_RiderBenefitValues]")
                {
                    DataRefreshTable DummyDataRefreshTable = new DataRefreshTable();
                    string TableName = DummyTable.ToString().Replace("[dbo].[", "").Replace("]", "");
                    string TableNameSS = Regex.Replace(TableName, @"([^s]+)s$", @"$1", RegexOptions.IgnoreCase);
                    TableNameSS = Regex.Replace(TableNameSS, @"([a-zA-Z0-9]+)_(\w+)$", @"$2", RegexOptions.IgnoreCase);
                    string ColumnList = String.Empty;
                    string ColumnListAA = String.Empty;
                    string ColumnListUpdate = String.Empty;

                    foreach (Column DummyColumn in DummyTable.Columns)
                    {
                        string ColumnName = DummyColumn.ToString().Replace("[", "").Replace("]", "");
                        ColumnList = ColumnList + "\t," + ColumnName + Environment.NewLine;
                        ColumnListAA = ColumnListAA + "\t,aa." + ColumnName + Environment.NewLine;
                        if (DummyColumn.InPrimaryKey == false)
                            ColumnListUpdate = ColumnListUpdate + "\t,aa." + ColumnName + " = bb." + ColumnName + Environment.NewLine;
                        //ColumnList.Add($",{ColumnName}");
                    }
                    DummyDataRefreshTable.TableName = TableName;
                    DummyDataRefreshTable.TableNameSS = TableNameSS;
                    DummyDataRefreshTable.ColumnList = ColumnList.TrimStart('\t').TrimStart(',');
                    DummyDataRefreshTable.ColumnListAA = ColumnListAA.TrimStart('\t').TrimStart(',');
                    DummyDataRefreshTable.ColumnListUpdate = ColumnListUpdate.TrimStart('\t').TrimStart(',');

                    DummyTables.Add(DummyDataRefreshTable);
                }
            }

            return DummyTables;
        }
    }
}
