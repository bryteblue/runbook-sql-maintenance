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
$SQLCommandString = "EXEC sp_updatestats;"

# Return the tables with their corresponding average fragmentation
$Cmd=new-object system.Data.SqlClient.SqlCommand($SQLCommandString, $Conn)
$Cmd.CommandTimeout=120

# Execute the SQL command
$IndexeswithFrag=New-Object system.Data.DataSet
$Da=New-Object system.Data.SqlClient.SqlDataAdapter($Cmd)
[void]$Da.fill($IndexeswithFrag)

write-output "database statistics updated." 

