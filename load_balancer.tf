# resource "azurerm_public_ip" "elb_pip" {
#   name                = "elb-pip"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   allocation_method   = "Static"
#   sku = "Standard"
# }

# resource "azurerm_lb" "this" {
#   name                = "elb"
#   location            = azurerm_resource_group.this.location
#   resource_group_name = azurerm_resource_group.this.name
#   sku = "Standard"

#   frontend_ip_configuration {
#     name                 = "PublicIPAddress"
#     public_ip_address_id = azurerm_public_ip.elb_pip.id
#   }
# }

# resource "azurerm_lb_backend_address_pool" "this" {
#   loadbalancer_id = azurerm_lb.this.id
#   name            = "BackEndAddressPool"
# }

# resource "azurerm_network_interface_backend_address_pool_association" "this" {
#   network_interface_id    = module.azure-linux-vm-private.network_interface_id
#   ip_configuration_name   = module.azure-linux-vm-private.ip_configuration_name
#   backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
# }

# resource "azurerm_lb_probe" "this" {
#   loadbalancer_id = azurerm_lb.this.id
#   name            = "ssh-running-probe"
#   port            = 22
# }

# resource "azurerm_lb_rule" "this" {
#   loadbalancer_id                = azurerm_lb.this.id
#   name                           = "LBRule"
#   protocol                       = "Tcp"
#   frontend_port                  = 22
#   backend_port                   = 22
#   frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration[0].name
#   backend_address_pool_ids = [azurerm_lb_backend_address_pool.this.id]
#   probe_id = azurerm_lb_probe.this.id
# }