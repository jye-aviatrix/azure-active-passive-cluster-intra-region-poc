variable "region" {
  type        = string
  description = "Provide region (location) of the VM"
}


variable "resource_group_name" {
  type = string
  description = "Provide the Resource Group name"
}


variable "vm_name" {
  type        = string
  description = "Provide name of the VM. The VM name will be added to tags by default"
}

variable "network_interface_id" {
  type = string
  description = "Provide network interface ID"
}

variable "public_key_file" {
  type = string
  description = "Provide path to SSH public key for the VM"
}

variable "admin_username" {
  type = string
  default = "ubuntu"
  description = "Provide local user of the VM"
}

variable "identity_id" {
  type = string
  description = "Provide user assigned identity id"
}

variable "bootstrap_url" {
  type = string
  description = "Provide uri where bootstrap files are stored, example: https://apc7e317c4fbd9749f7.z13.web.core.windows.net/bootstrap/"
}

locals {
    custom_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
echo "<h1>${var.vm_name}</h1>" | sudo tee /var/www/html/index.html
BOOTSTRAP_DIR="/etc/bootstrap/"
mkdir $BOOTSTRAP_DIR
wget -O "$BOOTSTRAP_DIR"nodes_info.json ${var.bootstrap_url}nodes_info.json
EOF
}