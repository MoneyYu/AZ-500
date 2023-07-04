## LAB-05-A-PEERING
resource "azurerm_virtual_network" "lab02b01" {
  name                = "${local.lab02b_name}-vnet-01-${local.random_str}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b01" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02b01.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "lab02b01" {
  name                = "${local.lab02b_name}-pip-01-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab02b_name}-pip-01-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02b01" {
  name                = "${local.lab02b_name}-nsg-01-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab02b01" {
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
  network_security_group_name = azurerm_network_security_group.lab02b01.name
}

resource "azurerm_network_interface" "lab02b01" {
  name                = "${local.lab02b_name}-nic-01-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-01-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab02b01.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab02b01" {
  network_interface_id      = azurerm_network_interface.lab02b01.id
  network_security_group_id = azurerm_network_security_group.lab02b01.id
}

resource "azurerm_windows_virtual_machine" "lab02b01" {
  name                  = "${local.lab02b_name}-vm01-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02b01.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-01-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm01-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b01script" {
  name                       = "${local.lab02b_name}-script-01-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b01.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab02b02" {
  name                = "${local.lab02b_name}-vnet-02-${local.random_str}"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b02" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02b02.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_public_ip" "lab02b02" {
  name                = "${local.lab02b_name}-pip-02-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab02b_name}-pip-02-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02b02" {
  name                = "${local.lab02b_name}-nsg-02-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab02b02" {
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
  network_security_group_name = azurerm_network_security_group.lab02b02.name
}

resource "azurerm_network_interface" "lab02b02" {
  name                = "${local.lab02b_name}-nic-02-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-02-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b02.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab02b02.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab02b02" {
  network_interface_id      = azurerm_network_interface.lab02b02.id
  network_security_group_id = azurerm_network_security_group.lab02b02.id
}

resource "azurerm_windows_virtual_machine" "lab02b02" {
  name                  = "${local.lab02b_name}-vm02-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02b02.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-02-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm02-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b02script" {
  name                       = "${local.lab02b_name}-script-02-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b02.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_network" "lab02b03" {
  name                = "${local.lab02b_name}-vnet-03-${local.random_str}"
  address_space       = ["10.3.0.0/16"]
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02b03" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02b03.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_public_ip" "lab02b03" {
  name                = "${local.lab02b_name}-pip-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Dynamic"
  domain_name_label   = "${local.lab02b_name}-pip-03-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02b03" {
  name                = "${local.lab02b_name}-nsg-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab02b03" {
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
  network_security_group_name = azurerm_network_security_group.lab02b03.name
}

resource "azurerm_network_interface" "lab02b03" {
  name                = "${local.lab02b_name}-nic-03-${local.random_str}"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab02b_name}-ipconfig-03-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02b03.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab02b03.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab02b03" {
  network_interface_id      = azurerm_network_interface.lab02b03.id
  network_security_group_id = azurerm_network_security_group.lab02b03.id
}

resource "azurerm_windows_virtual_machine" "lab02b03" {
  name                  = "${local.lab02b_name}-vm03-${local.random_str}"
  location              = "eastasia"
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02b03.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02b_name}-osdisk-03-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02b_name}-vm03-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02b03script" {
  name                       = "${local.lab02b_name}-script-03-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02b03.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
