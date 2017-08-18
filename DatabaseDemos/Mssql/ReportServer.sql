/*

*/

SELECT * FROM  ReportServer.dbo.ReportSchedule a 
JOIN msdb.dbo.sysjobs b
	ON CAST(a.ScheduleID AS NVARCHAR(50)) = b.name
JOIN ReportServer.dbo.Subscriptions d
	ON a.SubscriptionID = d.SubscriptionID
JOIN ReportServer.dbo.Catalog e
	ON d.report_oid = e.itemid
WHERE e.name = 'KemperFulfillmentDocuments'

SELECT * FROM ReportServer.dbo.ReportSchedule
SELECT * FROM ReportServer.dbo.Subscriptions
SELECT * FROM msdb.dbo.sysjobs
SELECT * FROM ReportServer.dbo.Catalog WHERE name LIKE 'k%' ORDER BY name


SELECT  'EXEC ReportServer.dbo.AddEvent @EventType=''TimedSubscription'', @EventData='''
        + CAST(a.SubscriptionID AS VARCHAR(40)) + '''' AS ReportCommand
       ,b.name AS JobName
       ,a.SubscriptionID
       ,e.Name
       ,e.Path
       ,d.Description
       ,d.LastStatus
       ,d.EventType
       ,d.LastRunTime
       ,b.date_created
       ,b.date_modified
FROM    ReportServer.dbo.ReportSchedule a
JOIN    msdb.dbo.sysjobs b
        ON a.ScheduleID = b.name
JOIN    ReportServer.dbo.ReportSchedule c
        ON b.name = c.ScheduleID
JOIN    ReportServer.dbo.Subscriptions d
        ON c.SubscriptionID = d.SubscriptionID
JOIN    ReportServer.dbo.Catalog e
        ON d.Report_OID = e.ItemID
WHERE   e.Name = 'Sales_Report';
    
/*
https://msdn.microsoft.com/en-us/library/ms186757.aspx
*/

