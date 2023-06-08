output "public_ip" {
  description = "Public IP"
  value = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP"
  value = azurerm_network_interface.this.private_ip_address
}

output "network_interface_id" {
  description = "Network interface id"
  value = azurerm_network_interface.this.id
}

output "ip_configuration_name" {
  description = "Network interface ip configuration name"
  value = azurerm_network_interface.this.ip_configuration[0].name
}