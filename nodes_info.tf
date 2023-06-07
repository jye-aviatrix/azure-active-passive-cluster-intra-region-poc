# Save nodes and their public/private IP information into nodes info file
resource "local_file" "nodes_info" {
    content  = jsonencode(module.network_interfaces)
    filename = "./nodes_info.json"
}




# Upload to storage account bootstrap container
resource "azurerm_storage_blob" "nodes_info" {
  name                   = "bootstrap/nodes_info.json"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type = "application/json"
  source                 = local_file.nodes_info.filename
}