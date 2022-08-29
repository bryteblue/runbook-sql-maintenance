<#

.parameter databaseservername
	specifies the name of the azure sql database server which script will backup
	
.parameter databasecredentialname
	specifies the administrator username of the azure sql database server

.parameter databasename
	comma separated list of databases script will backup
	
#>

param(
    [parameter(mandatory=$true)]
	[string]$databaseservername,
	
    [parameter(mandatory=$true)]
    [string]$databasecredentialname,
	
	[parameter(mandatory=$true)]
    [string]$databasename

)

write-output "databaseservername =   $databaseservername"
write-output "databasecredentialname =   $databasecredentialname" 
write-output "databasename =   $databasename"  


$SqlCredential = Get-AutomationPSCredential -Name $databasecredentialname
$SqlUsername = $SqlCredential.UserName 
$SqlPass = $SqlCredential.GetNetworkCredential().Password

# Define the connection to the SQL Database
$Conn = New-Object System.Data.SqlClient.SqlConnection("Server=tcp:$databaseservername,1433;Database=$databasename;User ID=$SqlUsername;Password=$SqlPass;Trusted_Connection=False;Encrypt=True;Connection Timeout=30;")
			
write-output "Opening connection" 
# Open the SQL connection
$Conn.Open()

# SQL command to find tables and their schemas
$SQLCommandString = "SELECT (dbschemas.[name] + '.' + dbtables.[name] ) as 'FQN',dbindexes.[name] as 'Index',indexstats.avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS indexstats INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id] INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id] INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id] AND indexstats.index_id = dbindexes.index_id WHERE indexstats.database_id = DB_ID() and indexstats.avg_fragmentation_in_percent > 40 ORDER BY indexstats.avg_fragmentation_in_percent desc"

# Return the tables with their corresponding average fragmentation
$Cmd=new-object system.Data.SqlClient.SqlCommand($SQLCommandString, $Conn)
$Cmd.CommandTimeout=120

# Execute the SQL command
$IndexeswithFrag=New-Object system.Data.DataSet
$Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
[void]$Da.fill($IndexeswithFrag)

write-output "Starting to loop thru tables names"
#Write-Warning "Outputting IndexeswithFrag-Tables[0] object "
#Write-Warning ($IndexeswithFrag.Tables[0] | Format-Table | out-string)

# Interate through tables with high fragmentation and rebuild indexes
ForEach ($indexName in $IndexeswithFrag.Tables[0])
{
    ##Write-Output "Creating checkpoint"
    #Checkpoint-Workflow
    ##Write-Output "itemarray : $indexName.item(0)  ==  ($indexName).Table" 
    ##Write-Output "item zero Table : $indexName.itemarray  ==  ($indexName).Table" 
    $schema_table = $indexName.Item(0)
    $index_name = $indexName.Item(1)
    ##Write-Output "Output FQN with item func :$schema_table" 
    ##Write-Output "Output index with item func :$index_name " 

    $SQLCommandString = "ALTER INDEX $index_name ON $schema_table REBUILD with (ONLINE=ON,FILLFACTOR = 80)"
    
    write-output $SQLCommandString

    # Return the tables with their corresponding average fragmentation
    $Cmd=new-object system.Data.SqlClient.SqlCommand($SQLCommandString, $Conn)
    $Cmd.CommandTimeout=120

    # Execute the SQL command
    $results=New-Object system.Data.DataSet
    $Dt=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
    [void]$Dt.fill($results)
    
}
	
write-output "database backup script finished" 

