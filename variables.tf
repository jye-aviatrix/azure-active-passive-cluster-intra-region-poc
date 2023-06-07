variable "location" {
    type = string
    description = "Provide Azure region for the resources"
    default = "East US"
}

variable "resource_group_name" {
  type = string
  description = "Provide Resource Group Name"
  default = "active-passive-cluster"
}

variable "virtual_network_name" {
  type = string
  description = "Provide virtual network name"
  default = "active-passive-cluster-vnet"
}

variable "virtual_network_cidr" {
  type = string
  description = "Provide virtual network cidr"
  default = "10.0.0.0/24"
}

variable "node_name" {
  type = string
  description = "Provide virtual machine name for the active-passive cluster"
  default = "node"
}

variable "public_key_file" {
  type = string
  description = "Description: Provide path to SSH public key for the VM"
}

variable "admin_username" {
  type = string
  description = "Provide ubuntu vm admin username"
  default = "azureuser"
}

variable "node_count" {
  type = number
  description = "Provide total number of VMs to be part of the active-passive cluster, must be odd number with minimum of 3"
  validation {
    condition     = var.node_count % 2 != 0
    error_message = "Only odd numbers are accepted."
  }
  validation {
    condition     = var.node_count >= 3
    error_message = "Minimum of 3"
  }
  default = 3
}

locals {
  node_list = [for i in range(var.node_count) : "${var.node_name}${i + 1}"]
}