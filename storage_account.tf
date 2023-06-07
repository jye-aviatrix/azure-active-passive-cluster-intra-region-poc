resource "random_id" "storage_account" {
  byte_length = 8
}

resource "azurerm_storage_account" "this" {
  name                     = "apc${lower(random_id.storage_account.hex)}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  static_website {
    
  }
}

# resource "azurerm_storage_container" "bootstrap" {
#   name                  = "bootstrap"
#   storage_account_name  = azurerm_storage_account.this.name
#   container_access_type = "private"
# }