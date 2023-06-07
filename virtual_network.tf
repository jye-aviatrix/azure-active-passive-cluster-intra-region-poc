# Create a virtual network within the resource group
resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  address_space       = [var.virtual_network_cidr]
}



# Split virtual network CIDR into two for public and private subnets
locals {
  public_subnet_cidr=cidrsubnets(var.virtual_network_cidr,1,1)[0]
  private_subnet_cidr=cidrsubnets(var.virtual_network_cidr,1,1)[1]
}



# Create public subnet
resource "azurerm_subnet" "public" {
  name                 = "public-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.public_subnet_cidr]
}



# Create private subnet
resource "azurerm_subnet" "private" {
  name                 = "private-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [local.private_subnet_cidr]
}



# Create public route table
resource "azurerm_route_table" "public" {
  name                          = "public-route-table"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  disable_bgp_route_propagation = true

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
}



# Create private route table
resource "azurerm_route_table" "private" {
  name                          = "private-route-table"
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  disable_bgp_route_propagation = true

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "None"
  }
}


# Associate public route table to public subnet
resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.public.id
}



# Associate public route table to private subnet
resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.private.id
}