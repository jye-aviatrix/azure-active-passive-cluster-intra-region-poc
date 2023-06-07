variable "region" {
  type        = string
  description = "Provide region (location) of the VM"
}


variable "resource_group_name" {
  type = string
  description = "Provide the Resource Group name"
}


variable "subnet_id" {
  type = string
  description = "Provide public subnet id, format: /subscriptions/<subscription_guid>/resourceGroups/<resource_group>/providers/Microsoft.Network/virtualNetworks/<vNet_name>/subnets/<subnet_name>"
}

variable "vm_name" {
  type        = string
  description = "Provide name of the VM. The VM name will be added to tags by default"
}