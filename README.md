# Introduction 
These files can set up a Azure automation account and set up 2 runbook designed to optimize and maintain an Azure SQL database (PaaS variant).
The scripts are based on Terraform.

These scripts will deploy two PowerShell runbooks, the contents are in files/*.ps1. Both scripts will need some variables. SQL Server
1. 1 will asses index fragmentation and will rebuild an index when fragmentation is above 20%.
2. 1 will update internal sql statistics

# Problems that need solving
When a data is removed and added from a database a indexes can get fragmentated. Meaning that the index points to a location where the data is not present. Typically resulting in a performance penalty.
When you rebuild an index this problem will get sorted. However, the internal statistics of the SQL Server (based upon query history) will still indicate an old and fragmentated index. The internal statistics need to be updated. Those statistics are used to determine the best execution plan.

Both need to be up to date to make sure the database is performing in good order. This runbook will try and keep that up to spec.

Background information 'SQL statistics' : https://docs.microsoft.com/en-us/sql/relational-databases/statistics/statistics?view=sql-server-ver16

Background information 'Index Fragmentation' : https://docs.microsoft.com/en-us/sql/relational-databases/indexes/reorganize-and-rebuild-indexes?view=sql-server-ver16

# Set up
The main part are the objects in runbook-resources.tf. You may need objects that relate to the main objects, you will find examples in basics.tf. Like a key vault, a secret, resources group.

Review providers, the required providers are AzureRM, time (to set a new date time for the schedule) and local (to read the powerschell scripts from disk and post them to the runbook). 

# Results
The script will create 1 automation account, 2 runbooks, 1 schedule, 1 credential and use a secret from a key vault.

# Resources explained
- Automation Account
- Runbooks : Scripts thate are run. One for reindexing, one for updating internal statistics.
- Credential : Credential is an object holds a username and password, fetched from a key vault. Both runbook use this single credential
- Schedule : Schedule the runbook will follow for firing. Both runbooks use this single schedule. When not providing a schedule it will default no now + 7 minutes.


# Caveats and gotcha's
- The credential name does not need to match admin user name, it actually a good idea to have different names.
- The script only works against a single database
- When not specifing a time on the schedule it will default to now + 7 minutes.

# Recommendations
- Create a Automation account per environment
