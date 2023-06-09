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

variable "zone" {
  type = string
  description = "provide availability zone for the VM to be deployed"
}

locals {
    custom_data = <<EOF
#!/bin/bash

# Install apache and create a default page
sudo apt update 
sudo apt install apache2 -y
echo "<h1>${var.vm_name}</h1>" | sudo tee /var/www/html/index.html

# Copy over files
mkdir /etc/bootstrap/
mkdir /var/log/bootstrap/
wget -O /etc/bootstrap/nodes_info.json ${var.bootstrap_url}nodes_info.json
wget -O /etc/bootstrap/probe.html ${var.bootstrap_url}probe.html
wget -O /etc/bootstrap/loader.py ${var.bootstrap_url}loader.py
wget -O /usr/local/bin/bootup.sh ${var.bootstrap_url}bootup.sh
wget -O /etc/systemd/system/bootup.service ${var.bootstrap_url}bootup.service

# Make sure node bootstrap as passive by remove probe.html, this file would only be created by loader.py after evaulate connectivity with other nodes
rm /var/www/html/probe.html

# Make sure node start up as passive during each reboot, bootup.sh will delete probe.html, leaving loader.py to determine if the node need to be passive
chmod +x /usr/local/bin/bootup.sh
sudo systemctl daemon-reload
sudo systemctl enable bootup.service


# Schedule loader to run every one minute
(crontab -l ; echo "* * * * * python3 /etc/bootstrap/loader.py")| crontab -

EOF
}