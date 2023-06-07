module "nodes" {
  source               = "./modules/virtual_machines"
  for_each             = toset(local.node_list)
  resource_group_name  = azurerm_resource_group.this.name
  region               = azurerm_resource_group.this.location
  vm_name              = each.value
  admin_username       = "ubuntu"
  public_key_file      = var.public_key_file
  network_interface_id = module.network_interfaces[each.value].network_interface_id
  identity_id = azurerm_user_assigned_identity.this.id
}
