resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.region
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [
    var.network_interface_id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_file)  
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  custom_data = base64encode(local.custom_data)

  identity {
    type = "UserAssigned"
    identity_ids = [
        var.identity_id
    ]
  }
}