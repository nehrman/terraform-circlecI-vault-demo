module "rootcertificate" {
  source                = "github.com/GuyBarros/terraform-tls-certificate"
  version               = "0.0.1"
  algorithm             = "ECDSA"
  ecdsa_curve           = "P521"
  common_name           = "service.consul"
  organization          = "service.consul"
  validity_period_hours = 720
  is_ca_certificate     = true
}

data "template_file" "consulconfig" {
  template = "${file("${path.module}/scripts/consul.tpl")}"
}

data "template_file" "nomadconfig" {
  template = "${file("${path.module}/scripts/nomad.tpl")}"
}

resource "azurerm_resource_group" "windows-rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "windows-vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${azurerm_resource_group.windows-rg.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.windows-rg.name}"
}

resource "azurerm_subnet" "windows-subnet" {
  name                 = "${var.demo_prefix}subnet"
  virtual_network_name = "${azurerm_virtual_network.windows-vnet.name}"
  resource_group_name  = "${azurerm_resource_group.windows-rg.name}"
  address_prefix       = "${var.subnet_prefix}"
}

resource "azurerm_network_security_group" "windows-sg" {
  name                = "${var.demo_prefix}-sg"
  location            = "${azurerm_resource_group.windows-rg.location}"
  resource_group_name = "${azurerm_resource_group.windows-rg.name}"

  security_rule {
    name                       = "winrm"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "rdp"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
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
  count               = "${var.servers}"
  name                = "${var.demo_prefix}windows-nic-${count.index}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.windows-rg.name}"

  # network_security_group_id = "${azurerm_network_security_group.ptfe-sg.id}"

  ip_configuration {
    name                          = "${var.demo_prefix}ipconfig-${count.index}"
    subnet_id                     = "${azurerm_subnet.windows-subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.windows-pip.*.id, count.index)}"
  }
}

# Every Azure Virtual Machine comes with a private IP address. You can also 
# optionally add a public IP address for Internet-facing applications and 
# demo environments like this one.
resource "azurerm_public_ip" "windows-pip" {
  count               = "${var.servers}"
  name                = "${var.demo_prefix}-ip-${count.index}"
  location            = "${azurerm_resource_group.windows-rg.location}"
  resource_group_name = "${azurerm_resource_group.windows-rg.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.hostname}-${count.index}"
}

resource "azurerm_virtual_machine" "web_server" {
  count                 = "${var.servers}"
  name                  = "${var.hostname}-${count.index}"
  location              = "${azurerm_resource_group.windows-rg.location}"
  resource_group_name   = "${azurerm_resource_group.windows-rg.name}"
  network_interface_ids = []
  vm_size               = "Standard_D2s_v3"

  network_interface_ids         = ["${element(azurerm_network_interface.windows-nic.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"

    // sku       = "2016-Datacenter-Server-Core-smalldisk"
    version = "latest"
  }

  storage_os_disk {
    name              = "server-os-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  tags {
    name  = "Nicolas Ehrman"
    ttl   = "13"
    owner = "nehrman@hashicorp.com"
  }

  os_profile {
    computer_name  = "${var.hostname}-${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true //Here defined autoupdate config and also vm agent config
    provision_vm_agent        = true

    winrm = {
      protocol = "http" //Here defined WinRM connectivity config
    }

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = "${file("${path.module}/scripts/FirstLogonCommands.xml")}"
    }
  }

  /*provisioner "file" {
    source      = "${path.module}/scripts/InstallHashicorp.ps1"
    destination = "C:\\Hashicorp\\InstallHashicorp.ps1"

    connection {
      type     = "winrm"
      timeout  = "10m"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.winmad-pip.*.fqdn, count.index)}"
    }
  }
  */

  provisioner "file" {
    content     = "${data.template_file.consulconfig.rendered}"
    destination = "C:\\Hashicorp\\Consul\\config.json"

    connection {
      type     = "winrm"
      timeout  = "10m"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.windows-pip.*.fqdn, count.index)}"
    }
  }
  provisioner "file" {
    content     = "${data.template_file.nomadconfig.rendered}"
    destination = "C:\\Hashicorp\\Nomad\\config.json"

    connection {
      type     = "winrm"
      timeout  = "10m"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.windows-pip.*.fqdn, count.index)}"
    }
  }
  # tls key
  provisioner "file" {
    content     = "${element(tls_private_key.servers.*.private_key_pem, count.index)}"
    destination = "C:\\Hashicorp\\Consul\\me.key"

    connection {
      type     = "winrm"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.windows-pip.*.fqdn, count.index)}"

      # host     = "${element(azurerm_public_ip.winmad-pip.*.fqdn, count.index)}"
    }
  }
  # tls crt
  provisioner "file" {
    content     = "${element(tls_locally_signed_cert.servers.*.cert_pem, count.index)}"
    destination = "C:\\Hashicorp\\Consul\\me.crt"

    connection {
      type     = "winrm"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.windows-pip.*.fqdn, count.index)}"

      # host     = "${element(azurerm_public_ip.winmad-pip.*.fqdn, count.index)}"
    }
  }
  # tls ca cert
  provisioner "file" {
    content     = "${module.rootcertificate.ca_cert_pem}"
    destination = "C:\\Hashicorp\\Consul\\01-me.crt"

    connection {
      type     = "winrm"
      https    = false
      insecure = true
      user     = "${var.admin_username}"
      password = "${var.admin_password}"
      host     = "${element(azurerm_public_ip.windows-pip.*.fqdn, count.index)}"
    }
  }
}

resource "azurerm_virtual_machine_extension" "test" {
  count                = "${var.servers}"
  name                 = "webserver-${count.index}"
  location             = "${azurerm_resource_group.windows-rg.location}"
  resource_group_name  = "${azurerm_resource_group.windows-rg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.web_server.*.name, count.index)}"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  depends_on           = ["azurerm_virtual_machine.web_server"]

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/nehrman/terraform-azure-windows/master/scripts/InstallHashicorp.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file InstallHashicorp.ps1"
    }
SETTINGS
}
