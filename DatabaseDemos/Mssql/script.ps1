[reflection.assembly]::loadwithpartialname("Microsoft.SqlServer.SMO")
$SObject = new-object Microsoft.SqlServer.Management.Smo.ScriptingOptions

$SObject

if (test-path 'c:\temp\tablescript.sql') {
	remove-item 'c:\temp\tablescript.sql'
}

cd sqlserver:\sql\e6cmo24\eval\databases\dbzoo\tables

gci  | % {$_.script($SObject) | out-file c:\temp\tablescript.sql -append}

cd c:\temp

$i = 1; $ct = (gci tablescript.sql).count; gci tablescript.sql | % {(get-content $_) | % {$_ -replace 'SET ANSI_NULLS ON', ''} | set-content $_; "$i of $ct"}
$i = 1; $ct = (gci tablescript.sql).count; gci tablescript.sql | % {(get-content $_) | % {$_ -replace 'SET QUOTED_IDENTIFIER ON', ''} | set-content $_; "$i of $ct"}

cd sqlserver:\sql\e6cmo24\eval\databases\dbsea\tables

invoke-sqlcmd -inputfile 'c:\temp\tablescript.sql'