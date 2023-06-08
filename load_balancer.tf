resource "azurerm_public_ip" "elb_pip" {
  name                = "elb-pip"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"  
  # Basic sku doesn't provide support to avaibility zone, lack of metric needed for enterprise environment
  # https://learn.microsoft.com/en-us/azure/load-balancer/skus
  # Standard sku load balancer require standard sku public IPs for the VM in backend pool.
  sku                 = "Standard"
}

resource "azurerm_lb" "this" {
  name                = "elb"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.elb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  for_each                = toset(local.node_list)
  network_interface_id    = module.network_interfaces[each.value].network_interface_id
  ip_configuration_name   = module.network_interfaces[each.value].ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
}

resource "azurerm_lb_probe" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "http-status-200-probe"
  protocol = "Http"
  port            = 80
  request_path = "/probe.php"
}

resource "azurerm_lb_rule" "this" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = azurerm_lb.this.frontend_ip_configuration[0].name
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.this.id]
  probe_id = azurerm_lb_probe.this.id
}
