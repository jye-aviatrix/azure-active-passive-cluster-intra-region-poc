# Save nodes and their public/private IP information into nodes info file
resource "local_file" "nodes_info" {
    content  = jsonencode(module.network_interfaces)
    filename = "./nodes_info.json"
}




# Upload to storage account bootstrap container
resource "azurerm_storage_blob" "nodes_info" {
  name                   = "nodes_info.json"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.bootstrap.name
  type                   = "Block"
  source                 = local_file.nodes_info.filename
}