## LAB-8-VM
resource "azurerm_virtual_network" "lab02d" {
  name                = "${local.lab02d_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab02d" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02d.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "lab02dbastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02d.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_public_ip" "lab02d" {
  name                = "${local.lab02d_name}-pip-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_bastion_host" "lab02d" {
  name                   = "${local.lab02d_name}-bastion-${local.random_str}"
  location               = azurerm_resource_group.az500.location
  resource_group_name    = azurerm_resource_group.az500.name
  sku                    = "Standard"
  file_copy_enabled      = true
  ip_connect_enabled     = true
  shareable_link_enabled = true
  tunneling_enabled      = true

  ip_configuration {
    name                 = "${local.lab02d_name}-bastion-ipconfig-${local.random_str}"
    subnet_id            = azurerm_subnet.lab02dbastion.id
    public_ip_address_id = azurerm_public_ip.lab02d.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab02d" {
  name                = "${local.lab02d_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab02d_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02d.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab02d" {
  name                  = "${local.lab02d_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02d.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02d_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02d_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02dscript" {
  name                       = "${local.lab02d_name}-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02d.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
