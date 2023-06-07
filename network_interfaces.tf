module "network_intefaces" {
  source   = "./modules/network_interfaces"
  for_each = local.node_list
  resource_group_name = azurerm_resource_group.this.name
  region = azurerm_resource_group.this.location
  subnet_id = azurerm_subnet.public.id
  vm_name = each.value
}
