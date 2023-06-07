output "public_ip" {
  description = "Public IP"
  value = azurerm_public_ip.this.ip_address
}

output "private_ip" {
  description = "Private IP"
  value = azurerm_network_interface.this.private_ip_address
}