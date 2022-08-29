resource "azurerm_automation_account" "automation-account" {
  name                = "autom-account"
  location            = azurerm_resource_group.app_rg.location
  resource_group_name = azurerm_resource_group.app_rg.name
  sku_name            = "Basic"

}

data "local_file" "runbook-sql-reindex" {
  filename = "files/runbook-ps-reindex.ps1"
}
data "local_file" "runbook-sql-updatestat" {
  filename = "files/runbook-ps-updatestats.ps1"
}


resource "azurerm_automation_runbook" "runbook-reindex" {

  name                    = "TF-Update-SQLIndexRunbook"
  location                = azurerm_resource_group.app_rg.location
  resource_group_name     = azurerm_resource_group.app_rg.name
  automation_account_name = azurerm_automation_account.automation-account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is the tf based Runbook."

  runbook_type = "PowerShell"

  content = data.local_file.runbook-sql-reindex.content
}

resource "azurerm_automation_runbook" "runbook-updatestats" {

  name                    = "TF-Update-SQLUpdateStats"
  location                = azurerm_resource_group.app_rg.location
  resource_group_name     = azurerm_resource_group.app_rg.name
  automation_account_name = azurerm_automation_account.automation-account.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "This is the tf based Runbook."

  runbook_type = "PowerShell"

  content = data.local_file.runbook-sql-updatestat.content
}




locals {
  update_time     = "23:00"
  update_date     = substr(time_offset.tomorrow.rfc3339, 0, 10)
  update_timezone = "UTC"
}

resource "time_offset" "tomorrow" {
  offset_days = 2
}

resource "azurerm_automation_schedule" "daily_run" {
  name = "Run every night at 2300hrs"

  automation_account_name = azurerm_automation_account.automation-account.name
  resource_group_name     = azurerm_resource_group.app_rg.name

  frequency = "Day"
  interval  = 1
  timezone  = "Europe/Amsterdam"
  #start_time =  Defaults to seven minutes in the future from the time the resource is created.
  start_time = "${local.update_date}T${local.update_time}:00+00:00"

}

resource "azurerm_automation_credential" "sql-admin" {
  name                    = "sql-adminazurerm_key_vault_secret.secret.name"
  resource_group_name     = azurerm_resource_group.app_rg.name
  automation_account_name = azurerm_automation_account.automation-account.name
  username                = azurerm_key_vault_secret.secret.name
  password                = data.azurerm_key_vault_secret.db_password.value
  description             = "This is the main admin account, used for db maintenance"
}

resource "azurerm_automation_job_schedule" "daily-updatestats" {
  resource_group_name     = azurerm_resource_group.app_rg.name
  automation_account_name = azurerm_automation_account.automation-account.name
  schedule_name           = azurerm_automation_schedule.daily_run.name
  runbook_name            = azurerm_automation_runbook.runbook-updatestats.name

  parameters = {
    databaseservername     = "sql-prototype-001.database.windows.net"
    databasecredentialname = azurerm_automation_credential.sql-admin.name
    databasename           = "yourdbname" # #or use reference  "azurerm_mssql_database.app_db.name"

  }

    depends_on = [
    azurerm_automation_runbook.runbook-updatestats
  ]
}

resource "azurerm_automation_job_schedule" "daily-reindex" {
  resource_group_name     = azurerm_resource_group.app_rg.name
  automation_account_name = azurerm_automation_account.automation-account.name
  schedule_name           = azurerm_automation_schedule.daily_run.name
  runbook_name            = azurerm_automation_runbook.runbook-reindex.name

  parameters = {
    databaseservername     = "sql-prototype-001.database.windows.net" # #or use reference  "azurerm_mssql_server.app_db_server.name"
    databasecredentialname = azurerm_automation_credential.sql-admin.name
    databasename           = "yourdbname" # #or use reference  "azurerm_mssql_database.app_db.name"
  }

    depends_on = [
    azurerm_automation_runbook.runbook-reindex
  ]
}

