using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SDS = System.Data.SqlClient;
using MSM = Microsoft.SqlServer.Management;
using MSS = Microsoft.SqlServer.Server;
using SD = System.Data;

namespace AWDWConsole
{
    class Program
    {
        static void Main(string[] args)
        {
            SelectClr();
            Console.ReadLine();
        }

        public static void SelectClr ()
        {
            string connectionString = AWDWConsole.Settings1.Default.connectionString;
            SDS.SqlConnectionStringBuilder scsb = new SDS.SqlConnectionStringBuilder(connectionString);
            string dataSource = scsb.DataSource;
            MSM.Common.ServerConnection serverConnection = new MSM.Common.ServerConnection(dataSource);


            SDS.SqlDataReader reader = serverConnection.ExecuteReader("select * from sys.tables");

            int colCount = reader.FieldCount;
            while (reader.Read())
            {
                for (int i = 0; i < colCount; i++)
                {
                    Console.Write(String.Format("{0,12}", reader[i]));
                }
            }
            reader.Close();
            
            
            SD.DataSet dataSet = serverConnection.ExecuteWithResults("select * from sys.tables");
            SD.DataTable dataTable = dataSet.Tables[0];

            foreach (SD.DataRow dataRow in dataTable.Rows)
            {
                Console.WriteLine();
                foreach (SD.DataColumn dataColumn in dataTable.Columns)
                {
                    Console.Write(dataRow[dataColumn].ToString());
                }
            }
        }
    }
}
