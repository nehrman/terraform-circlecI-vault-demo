data "template_file" "consulconfig" {
   template = "${file("${path.module}/scripts/consul.tpl")}"

}

##############################################################################
# HashiCorp PTFE instlation Demo
# 
# This Terraform configuration will create the following:
#
# * Resource group with a virtual network and subnet
# * A HashiCorp ptfe server
# *
##############################################################################
# Shared infrastructure resources

# First we'll create a resource group. In Azure every resource belongs to a 
# resource group. Think of it as a container to hold all your resources. 
# You can find a complete list of Azure resources supported by Terraform here:
# https://www.terraform.io/docs/providers/azurerm/
#this change doesnt do anything
resource "azurerm_resource_group" "ptfe" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

# The next resource is a Virtual Network. We can dynamically place it into the
# resource group without knowing its name ahead of time. Terraform handles all
# of that for you, so everything is named consistently every time. Say goodbye
# to weirdly-named mystery resources in your Azure Portal. To see how all this
# works visually, run `terraform graph` and copy the output into the online
# GraphViz tool: http://www.webgraphviz.com/
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${azurerm_resource_group.ptfe.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.ptfe.name}"
}

# Next we'll build a subnet to run our VMs in. These variables can be defined 
# via environment variables, a config file, or command line flags. Default 
# values will be used if the user does not override them. You can find all the
# default variables in the variables.tf file. You can customize this demo by
# making a copy of the terraform.tfvars.example file.
resource "azurerm_subnet" "subnet" {
  name                 = "${var.demo_prefix}subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.ptfe.name}"
  address_prefix       = "${var.subnet_prefix}"
}

##############################################################################
# HashiCorp ptfe Server
#
# Now that we have a network, we'll deploy a stand-alone HashiCorp ptfe 
# server.

# An Azure Virtual Machine has several components. In this example we'll build
# a security group, a network interface, a public ip address, a storage 
# account and finally the VM itself. Terraform handles all the dependencies 
# automatically, and each resource is named with user-defined variables.

# Security group to allow inbound access on port 8200,443,80,22 and 9870-9880
resource "azurerm_network_security_group" "ptfe-sg" {
  name                = "${var.demo_prefix}-sg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ptfe.name}"

  security_rule {
    name                       = "ptfe-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ptfe-setup"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8800"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ptfe-run"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9870-9880"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Consul-run"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000-9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
  security_rule {
    name                       = "Nomad-run"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4000-7000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# A network interface. This is required by the azurerm_virtual_machine 
# resource. Terraform will let you know if you're missing a dependency.
resource "azurerm_network_interface" "ptfe-nic" {
  name                = "${var.demo_prefix}ptfe-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ptfe.name}"

  # network_security_group_id = "${azurerm_network_security_group.ptfe-sg.id}"

  ip_configuration {
    name                          = "${var.demo_prefix}ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.ptfe-pip.id}"
  }
}

# Every Azure Virtual Machine comes with a private IP address. You can also 
# optionally add a public IP address for Internet-facing applications and 
# demo environments like this one.
resource "azurerm_public_ip" "ptfe-pip" {
  name                         = "${var.demo_prefix}-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.ptfe.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "${var.hostname}"
}

/*
resource "azurerm_virtual_machine" "ptfe" {
  name                = "${var.hostname}-ptfe"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ptfe.name}"
  vm_size             = "${var.vm_size}"

  network_interface_ids         = ["${azurerm_network_interface.ptfe-nic.id}"]
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name              = "${var.hostname}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    disk_size_gb      = "${var.storage_disk_size}"
  }

  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  # This shell script starts a ptfe install
  provisioner "remote-exec" {
    inline = [
      "curl https://install.terraform.io/ptfe/stable > install_ptfe.sh",
      "chmod 500 install_ptfe.sh",
      "sudo ./install_ptfe.sh no-proxy bypass-storagedriver-warnings ",
    ]

    connection {
      type     = "ssh"
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${azurerm_public_ip.ptfe-pip.fqdn}"
    }
  }
  }
*/
  

resource "azurerm_virtual_machine" "web_server" {
  name                  = "demostack-windows-0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ptfe.name}"
  network_interface_ids = []
  vm_size               = "Standard_B2s"

network_interface_ids         = ["${azurerm_network_interface.ptfe-nic.id}"]
  delete_os_disk_on_termination = "true"


  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "server-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name      = "windows-0"
    admin_username     = "${var.admin_username}"
    admin_password     = "${var.admin_password}"
    custom_data        =   <<EOF
<powershell>
net user ${var.admin_username} '${var.admin_password}' /add /y
net localgroup administrators ${var.admin_username} /add

winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow

net stop winrm
sc.exe config winrm start=auto
net start winrm
</powershell>
EOF
  
  }

   os_profile_windows_config {  //Here defined autoupdate config and also vm agent config
    enable_automatic_upgrades = true  
    provision_vm_agent        = true  
  
    winrm = {  //Here defined WinRM connectivity config
      protocol = "http"  
    } 

// template = "${file("${path.module}/scripts/consul.tpl")}"
    additional_unattend_config {
            pass = "oobeSystem"
            component = "Microsoft-Windows-Shell-Setup"
            setting_name = "AutoLogon"
            content = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
        }
        
        #Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
        additional_unattend_config {
            pass = "oobeSystem"
            component = "Microsoft-Windows-Shell-Setup"
            setting_name = "FirstLogonCommands"
            content = "${file("${path.module}/scripts/FirstLogonCommands.xml")}"
        }


  }  

 provisioner "file" {
    source      = "${path.module}/scripts/InstallHashicorp.bat"
    destination = "C:\\Hashicorp\\InstallHashicorp.bat"
  
  connection {
       type = "winrm"
            https = false
            insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${azurerm_public_ip.ptfe-pip.fqdn}"
    }
   

  }

   provisioner "file" {
    content       = "${data.template_file.consulconfig.rendered}"
    destination = "C:\\Hashicorp\\Consul\\config.json"
  
  
  connection {
       type = "winrm"
            https = false
            insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${azurerm_public_ip.ptfe-pip.fqdn}"
    }
  }
  


}
 
