# Introduction 
These files can set up a Azure automation account and set up 2 runbook designed to optimize and maintain an Azure SQL database (PaaS variant).
The scripts are based on Terraform.

These scripts will deploy two PowerShell runbooks, the contents are in files/*.ps1. Both scripts will need some variables. SQL Server
1. 1 will asses index fragmentation and will rebuild an index when fragmentation is above 20%.
2. 1 will update internal sql statistics

# Set up
The main part are the objects in runbook-resources.tf. You may need objects that relate to the main objects, you will find examples in basics.tf. Like a key vault, a secret, resources group.

Review providers, the required providers are AzureRM, time (to set a new date time for the schedule) and local (to read the powerschell scripts from disk and post them to the runbook). 

# Results
The script will create 1 automation account, 2 runbooks, 1 schedule, 1 credential and use a secret from a key vault.

# Resources explained
- Automation Account
- Runbooks : Scripts thate are run. One for reindexing, one for updating internal statistics.
- Credential : Credential is an object holds a username and password, fetched from a key vault. Both runbook use this single credential
- Schedule : Schedule the runbook will follow for firing. Both runbooks use this single schedule


# Caveats and gotcha's
- The credential name does not need to match admin user name, it actually a good idea to have different names.
- The script only works against a single database
- When not specifing a time on the schedule it will default to now + 7 minutes.

# Recommendations
- Create a Automation account per environment