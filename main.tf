data "template_file" "windows" {
template = "${file("${path.module}/scripts/custom_data.ps1")}"

  vars {
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    
  }

  }



data "template_file" "consulconfig" {
   template = "${file("${path.module}/scripts/consul.tpl")}"

}

resource "azurerm_resource_group" "windows" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${azurerm_resource_group.windows.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.windows.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.demo_prefix}subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.windows.name}"
  address_prefix       = "${var.subnet_prefix}"
}
# Security group to allow inbound access on port 8200,443,80,22 and 9870-9880
resource "azurerm_network_security_group" "windows-sg" {
  name                = "${var.demo_prefix}-sg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.windows.name}"

  security_rule {
    name                       = "windows-https"
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
    name                       = "windows-setup"
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
    name                       = "windows-run"
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
resource "azurerm_network_interface" "windows-nic" {
  name                = "${var.demo_prefix}windows-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.windows.name}"

  # network_security_group_id = "${azurerm_network_security_group.windows-sg.id}"

  ip_configuration {
    name                          = "${var.demo_prefix}ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.windows-pip.id}"
  }
}

# Every Azure Virtual Machine comes with a private IP address. You can also 
# optionally add a public IP address for Internet-facing applications and 
# demo environments like this one.
resource "azurerm_public_ip" "windows-pip" {
  name                         = "${var.demo_prefix}-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.windows.name}"
  allocation_method            = "Dynamic"
  domain_name_label            = "${var.hostname}"
}


resource "azurerm_virtual_machine" "windows" {
  name                  = "demostack-windows-0"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.windows.name}"
  network_interface_ids = []
  vm_size               = "Standard_B2s"

network_interface_ids         = ["${azurerm_network_interface.windows-nic.id}"]
  delete_os_disk_on_termination = "true"


  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    // sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }

  storage_os_disk {
    name              = "server-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

tags {
    name      = "Guy Barros"
    ttl       = "24"
    owner     = "guy@hashicorp.com"

  }

  os_profile {
    computer_name      = "windows-0"
    admin_username     = "${var.admin_username}"
    admin_password     = "${var.admin_password}"


  custom_data   =  <<EOF

  
Start-Transcript -Path C:\Deploy.Log

Write-Host "Setup WinRM for $RemoteHostName"
net user ${var.admin_username} '${var.admin_password}' /add /y
net localgroup administrators ${var.admin_username} /add


Write-Host "quickconfigure  WinRM"
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'


Write-Host "Open Firewall Port for WinRM"
netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=$WinRmPort
netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
netsh advfirewall firewall add rule name="WinRM 5986" protocol=TCP dir=in localport=5986 action=allow
Write-Host "Open Firewall Port for Consul"
netsh advfirewall firewall add rule name="Consul TCP" dir=in action=allow protocol=TCP localport=8000-9000
netsh advfirewall firewall add rule name="Consul UDP" dir=in action=allow protocol=UDP localport=8000-9000
Write-Host "Open Firewall Port for Nomad"
netsh advfirewall firewall add rule name="Nomad TCP" dir=in action=allow protocol=TCP localport=4000-5000
netsh advfirewall firewall add rule name="Nomad UDP" dir=in action=allow protocol=UDP localport=4000-5000


set-netfirewallprofile -Profile Domain, Public,Private -Enabled false

Write-Host "configure WinRM as a Service"
net stop winrm
sc.exe config winrm start=auto
net start winrm

Stop-Transcript

EOF

  }

   os_profile_windows_config {  //Here defined autoupdate config and also vm agent config
    enable_automatic_upgrades = true  
    provision_vm_agent        = true  
  
    winrm = {  //Here defined WinRM connectivity config
      protocol = "http"  
    } 


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
    source      = "${path.module}/scripts/InstallHashicorp.ps1"
    destination = "C:\\Hashicorp\\InstallHashicorp.ps1"
  
  connection {
       type = "winrm"
            https = false
            insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${azurerm_public_ip.windows-pip.fqdn}"
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
      host     = "${azurerm_public_ip.windows-pip.fqdn}"
    }
  }
  


}
 
