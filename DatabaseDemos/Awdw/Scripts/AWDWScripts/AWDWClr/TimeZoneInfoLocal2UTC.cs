using System;
using SD = System.Data;
using SDC = System.Data.SqlClient;
using SDT = System.Data.SqlTypes;
using MSS = Microsoft.SqlServer.Server;
using STR = System.Text.RegularExpressions;

public partial class UserDefinedFunctions
{
    [Microsoft.SqlServer.Server.SqlFunction]
    public static SDT.SqlString TimeZoneInfoLocal2UTC(DateTime local)
    {
        string result = TimeZoneInfo.ConvertTimeToUtc(local).ToString();
        return new SDT.SqlString(result);
    }

    [Microsoft.SqlServer.Server.SqlFunction]
    public static SDT.SqlString TimeZoneInfoUTC2Local(DateTime utc)
    {
        TimeZoneInfo localTimeZone = TimeZoneInfo.FindSystemTimeZoneById(TimeZoneInfo.Local.Id);

        string result = TimeZoneInfo.ConvertTimeFromUtc(utc, localTimeZone).ToString();
        return new SDT.SqlString(result);
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void HelloWorld(out string text)
    {
        MSS.SqlContext.Pipe.Send("Hello World!" + Environment.NewLine);
        text = "Hello world!";
    }

    [Microsoft.SqlServer.Server.SqlFunction]
    public static int RegexIndex(string pattern, string input, int startAt)
    {
        STR.Regex regexPattern = new STR.Regex(pattern);
        STR.Match regexMatch = regexPattern.Match(input, startAt);
        int regexIndex = regexMatch.Index;
        return regexIndex;
    }

    public static void RegexMatches(string pattern, string input)
    {
        STR.MatchCollection matchCollection = STR.Regex.Matches(input, pattern, STR.RegexOptions.IgnoreCase | STR.RegexOptions.Compiled);
        MSS.SqlMetaData column_001 = new MSS.SqlMetaData("RegexSubstring", SD.SqlDbType.NVarChar, 128);
        MSS.SqlMetaData column_002 = new MSS.SqlMetaData("RegexIndex", SD.SqlDbType.Int);
        MSS.SqlMetaData column_003 = new MSS.SqlMetaData("RegexLength", SD.SqlDbType.Int);

        MSS.SqlMetaData[] columns = new MSS.SqlMetaData[] { column_001, column_002, column_003 };
        MSS.SqlDataRecord record = new MSS.SqlDataRecord(columns);

        MSS.SqlContext.Pipe.SendResultsStart(record);

        foreach (STR.Match match in matchCollection)
        {

            record.SetSqlString(0, match.Value);
            record.SetInt32(1, match.Index);
            record.SetInt32(1, match.Length);
            MSS.SqlContext.Pipe.SendResultsRow(record);
        }

        MSS.SqlContext.Pipe.SendResultsEnd();
    }

    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void Transpose(SDT.SqlString queryParameter)
    {
        // SECTION 1: Variable declarations
        // .NET SQL objects. These objects will GET instantiated later IN the code. 
        try
        {
            // SECTION 2 : EXECUTE Caller's query and store data
            string callersQuery = queryParameter.ToString();
            SDC.SqlConnection conn;
            SDC.SqlCommand comm;
            SDC.SqlDataReader dataReader;

            conn = new SDC.SqlConnection("context connection=true;");
            comm = new SDC.SqlCommand(callersQuery, conn);
            conn.Open();

            int columnCount = 0;
            int maxNumberofRows = 2048;
            int rowCount = 1;
            string[,] queryData;

            dataReader = comm.ExecuteReader();
            columnCount = dataReader.FieldCount;
            queryData = new string[maxNumberofRows, columnCount];
            for (int j = 0; j < columnCount; j++)
            {
                queryData[0, j] = dataReader.GetName(j);
            }

            while (dataReader.Read())
            {
                for (int j = 0; j < columnCount; j++)
                {
                    queryData[rowCount, j] = dataReader[j].ToString();
                }
                rowCount++;
            }
            dataReader.Close();
            conn.Close();

            // SECTION 3:  Transpose the data
            int transposedColumnCount = 0;
            int maxDataSize = 100;
            int transposedRowCount = 0;
            string[,] transposedData;

            transposedRowCount = columnCount;
            transposedColumnCount = rowCount;
            transposedData = new string[transposedRowCount, transposedColumnCount];

            for (int i = 0; i < transposedRowCount; i++)
            {
                for (int j = 0; j < transposedColumnCount; j++)
                {
                    transposedData[i, j] = queryData[j, i];
                }
            }

            // SECTION 4: Ouput the data back to Caller
            MSS.SqlMetaData[] transposedColumns;
            MSS.SqlDataRecord rowRecord;

            transposedColumns = new MSS.SqlMetaData[transposedColumnCount];
            for (int j = 0; j < transposedColumnCount; j++)
            {
                transposedColumns[j]
                        = new MSS.SqlMetaData(transposedData[0, j], SD.SqlDbType.VarChar, maxDataSize);
            }

            rowRecord = new MSS.SqlDataRecord(transposedColumns);
            MSS.SqlContext.Pipe.SendResultsStart(rowRecord);

            for (int i = 1; i < transposedRowCount; i++)
            {
                for (int j = 0; j < transposedColumnCount; j++)
                {
                    rowRecord.SetSqlString(j, transposedData[i, j]);
                }
                MSS.SqlContext.Pipe.SendResultsRow(rowRecord);
            }

            MSS.SqlContext.Pipe.SendResultsEnd();
            MSS.SqlContext.Pipe.Send("Transpose complete.");
        }
        // SECTION 5: Handle errors
        catch (Exception e)
        {
            MSS.SqlContext.Pipe.Send("There was a problem. \n\nException Report: ");
            MSS.SqlContext.Pipe.Send(e.Message.ToString());
        }
        return;
    }
}
