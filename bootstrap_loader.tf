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
  content_md5            = local_file.loader.content_md5 # This is important to make sure file change gets updated
}


resource "azurerm_storage_blob" "probe" {
  name                   = "bootstrap/probe.html"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/octet-stream"
  source                 = "./bootstrap/probe.html"
  content_md5            = filemd5("./bootstrap/probe.html") # This is important to make sure file change gets updated
}



resource "azurerm_storage_blob" "bootup" {
  name                   = "bootstrap/bootup.sh"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "text/x-sh"
  source                 = "./bootstrap/bootup.sh"
  content_md5            = filemd5("./bootstrap/bootup.sh") # This is important to make sure file change gets updated
}

resource "azurerm_storage_blob" "bootup_service" {
  name                   = "bootstrap/bootup.service"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = "$web"
  type                   = "Block"
  content_type           = "application/octet-stream"
  source                 = "./bootstrap/bootup.service"
  content_md5            = filemd5("./bootstrap/bootup.service") # This is important to make sure file change gets updated
}