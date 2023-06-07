# Create user assigned identity for all nodes. Nodes will use this identity to access storage account, key vault
resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location  
  resource_group_name = azurerm_resource_group.this.name
  name                = "nodes_user_assigned_identity"
}

resource "azurerm_role_assignment" "storage_blob_reader" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}