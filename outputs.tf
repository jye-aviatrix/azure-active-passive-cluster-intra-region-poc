output "loadbalancer_public_ip" {
  value = azurerm_public_ip.elb_pip.ip_address
}