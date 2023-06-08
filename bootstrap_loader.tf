# Upload python loader to storage account static web

resource "local_file" "loader" {
  content = templatefile("./bootstrap/loader.template.py",
    {
      bootstrap_url = "${azurerm_storage_account.this.primary_web_endpoint}bootstrap/"
    }
  )
  filename = "./bootstrap/loader.py"
}

resource "azurerm_storage_blob" "loader" {
  name                   = "bootstrap/loader.py"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/x-python"
  source                 = local_file.loader.filename
  content_md5            = local_file.loader.content_md5
}


resource "azurerm_storage_blob" "active" {
  name                   = "bootstrap/active.php"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/octet-stream"
  source                 = "./bootstrap/active.php"
  content_md5            = filemd5("./bootstrap/active.php")
}

resource "azurerm_storage_blob" "passive" {
  name                   = "bootstrap/passive.php"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/octet-stream"
  source                 = "./bootstrap/passive.php"
  content_md5            = filemd5("./bootstrap/passive.php")
}