##############################################################################
# Outputs File
#
# Expose the outputs you want your users to see after a successful 
# `terraform apply` or `terraform output` command. You can add your own text 
# and include any data from the state file. Outputs are sorted alphabetically;
# use an underscore _ to move things to the bottom. In this example we're 
# providing instructions to the user on how to connect to their own custom 
# demo environment.

#output "file" {
#  value = "${data.template_file.consulconfig.rendered}"
#}

output "rg_name" {
  value = "${azurerm_resource_group.windows-rg.name}"
  description = "Name of the resource group created by terraform"
}

output "vnet_name" {
  value = "${azurerm_virtual_network.windows-vnet.name}"
  description = "Name of the Virtual Network created by terraform"
}

output "vnet_address_space" {
  value = "${azurerm_virtual_network.windows-vnet.address_space}"
  description = "Address Space of the Virtual Network created by terraform"
}

output "subnet_name" {
  value = "${azurerm_subnet.windows-subnet.name}"
  description = "Name of the Subnet created by terraform"
}

output "subnet_address_prefix" {
  value = "${azurerm_subnet.windows-subnet.address_prefix}"
  description = "Address Prefix of the Subnet created by terraform"
}

output "vm_name" {
  value = "${azurerm_virtual_machine[count.index].web_server.name}"
  description = "Name of Virtual Machines created by terraform"
}

output "vm_blic_ipu" {
  value = "${azurerm_public_ip[count.index].windows-pip.ip_address}"
  description = "Public IP Addresses of Virtual Machines created by terraform"
}
  
