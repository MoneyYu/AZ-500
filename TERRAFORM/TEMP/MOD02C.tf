## LAB-8-VM
resource "azurerm_virtual_network" "lab02c" {
  name                = "${local.lab02c_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02c" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02c.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "lab02c" {
  name                = "${local.lab02c_name}-nsg-01-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab02c" {
  name                        = "RDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az500.name
  network_security_group_name = azurerm_network_security_group.lab02c.name
}

resource "azurerm_subnet_network_security_group_association" "lab02c" {
  subnet_id                 = azurerm_subnet.lab02c.id
  network_security_group_id = azurerm_network_security_group.lab02c.id
}

resource "azurerm_application_security_group" "lab02c" {
  name                = "${local.lab02c_name}-asg-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
}

resource "azurerm_network_interface_application_security_group_association" "lab02c" {
  network_interface_id          = azurerm_network_interface.lab02c.id
  application_security_group_id = azurerm_application_security_group.lab02c.id
}

resource "azurerm_public_ip" "lab02c" {
  name                = "${local.lab02c_name}-pip-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab02c" {
  name                = "${local.lab02c_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab02c_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02c.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab02c" {
  name                  = "${local.lab02c_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02c.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02c_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02c_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02cscript" {
  name                       = "${local.lab02c_name}-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02c.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
