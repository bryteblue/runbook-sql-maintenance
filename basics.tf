resource "azurerm_resource_group" "app_rg" {
  name     = "my-rg"
  location = "West Europe"
}


resource "azurerm_key_vault_secret" "secret" {
  name         = "my-db-admin-account"
  value        = "MySuperSecretPassword!!02-394-0239"
  key_vault_id = azurerm_key_vault.infra_vault.id
}

resource "azurerm_key_vault" "infra_vault" {
  name                        = "myvault"
  location                    = azurerm_resource_group.app_rg.location
  resource_group_name         = azurerm_resource_group.app_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"

  tags = {
    usage = "infrastructure"
  }
}




resource "azurerm_mssql_server" "app_db_server" {
  name                         = "my-db-001"
  resource_group_name          = azurerm_resource_group.app_rg.name
  location                     = azurerm_resource_group.app_rg.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.db_password.name
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
  minimum_tls_version          = "1.2"

}
resource "azurerm_mssql_database" "app_db" {
  name      = "prototype-db"
  server_id = azurerm_mssql_server.app_db_server.id
  #license_type = "LicenseIncluded"
  max_size_gb = 5
  sku_name    = "S2"

}
