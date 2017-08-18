using System;
using SCG = System.Collections.Generic;
using System.Linq;
using ST = System.Text;
using System.Threading.Tasks;
using SDS = System.Data.SqlClient;
using MSM = Microsoft.SqlServer.Management;
using SI = System.IO;

namespace AWDWScripts
{
    class Program
    {
        static void Main(string[] args)
        {
            SCG.Dictionary<string, string> columnList = GetColumnList();
            string assemblyPath = System.Reflection.Assembly.GetExecutingAssembly().Location;
            string assemblyDir = SI.Path.GetDirectoryName(assemblyPath);
            string AWDWInputPath = SI.Path.Combine(assemblyDir, "AWDWInput.txt");
            string AWDWOutputPath = SI.Path.Combine(assemblyDir, "AWDWOutput.txt");

            string AWDWInput = "";
            using (SI.StreamReader sr = new SI.StreamReader(AWDWInputPath))
            {
                AWDWInput = sr.ReadToEnd();
            }

            SI.File.Delete(AWDWOutputPath);
            foreach (SCG.KeyValuePair<string, string> item in columnList)
            {
                string[] itemSplit = new string[2];
                itemSplit = item.Key.Split('.');
                string schemaName = itemSplit[0];
                string tableName = itemSplit[1];

                ST.StringBuilder sb = new ST.StringBuilder();
                sb.Append(AWDWInput);

                sb = sb.Replace("<SchemaName>", schemaName);
                sb = sb.Replace("<TableName>", tableName);
                sb = sb.Replace("<ColumnList>", item.Value);

                using (SI.StreamWriter sw = new SI.StreamWriter(AWDWOutputPath, true))
                {
                    sw.WriteLine(sb.ToString());
                }
            }
        }

        public static SCG.Dictionary<string, string> GetColumnList()
        {
            string connectionString = AWDWScripts.Settings1.Default.connectionString;
            SDS.SqlConnectionStringBuilder csb = new SDS.SqlConnectionStringBuilder(connectionString);
            string initialCatalog = csb.InitialCatalog;
            string dataSource = csb.DataSource;

            MSM.Common.ServerConnection serverConnection = new MSM.Common.ServerConnection(dataSource);
            MSM.Smo.Server server = new MSM.Smo.Server(serverConnection);
            MSM.Smo.Database database = server.Databases[initialCatalog];

            SCG.Dictionary<string, string> columnList = new SCG.Dictionary<string, string>();
            foreach (MSM.Smo.Table tt in database.Tables)
            {
                if (tt.Schema != "dbo")
                {
                    string ttString = tt.ToString().Replace("[", "").Replace("]", "");
                    ST.StringBuilder sb = new ST.StringBuilder();
                    string ttcolumnList = "";
                    foreach (MSM.Smo.Column column in tt.Columns)
                    {
                        sb.Append(", " + column.ToString().Replace("[", "").Replace("]", ""));
                    }
                    ttcolumnList = sb.ToString().TrimStart(',');
                    columnList.Add(ttString, ttcolumnList);
                }
            }
            
            return columnList;
        }
    }
}
