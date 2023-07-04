## LAB-04-VNET
resource "azurerm_virtual_network" "lab02a" {
  name                = "${local.lab02a_name}-vnet-${local.random_str}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab02a" {
  name                = "${local.lab02a_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab02a" {
  name                        = "RDP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "3389"
  destination_port_range      = "3389"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az500.name
  network_security_group_name = azurerm_network_security_group.lab02a.name
}

resource "azurerm_subnet" "lab02a" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02a.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "lab02afirewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab02a.name
  address_prefixes     = ["10.10.2.0/24"]
}

resource "azurerm_public_ip" "lab02a" {
  name                = "${local.lab02a_name}-pip-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.lab02a_name}-pip-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_firewall" "lab02a" {
  name                = "${local.lab02a_name}-fw-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.lab02afirewall.id
    public_ip_address_id = azurerm_public_ip.lab02a.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_firewall_application_rule_collection" "lab02a" {
  name                = "App-Coll01"
  azure_firewall_name = azurerm_firewall.lab02a.name
  resource_group_name = azurerm_resource_group.az500.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "Allow-Google-01"

    source_addresses = [
      "10.10.1.0/24",
    ]

    target_fqdns = [
      "*.google.com",
    ]

    protocol {
      port = 443
      type = "Https"
    }

    protocol {
      port = 80
      type = "Http"
    }
  }

  rule {
    name = "Allow-Google-02"

    source_addresses = [
      "10.10.1.0/24",
    ]

    target_fqdns = [
      "google.com",
    ]

    protocol {
      port = 443
      type = "Https"
    }

    protocol {
      port = 80
      type = "Http"
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "lab02a" {
  name                = "Net-Coll01"
  azure_firewall_name = azurerm_firewall.lab02a.name
  resource_group_name = azurerm_resource_group.az500.name
  priority            = 200
  action              = "Allow"

  rule {
    name = "Allow-DNS"

    source_addresses = [
      "10.10.1.0/24",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "8.8.8.8",
      "8.8.4.4",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

resource "azurerm_firewall_nat_rule_collection" "lab02a" {
  name                = "rdp"
  azure_firewall_name = azurerm_firewall.lab02a.name
  resource_group_name = azurerm_resource_group.az500.name
  priority            = 200
  action              = "Dnat"

  rule {
    name = "rdp-nat"

    source_addresses = [
      "*",
    ]

    destination_ports = [
      "3389",
    ]

    destination_addresses = [
      azurerm_public_ip.lab02a.ip_address
    ]

    translated_port = 3389

    translated_address = azurerm_network_interface.lab02a.private_ip_address

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

resource "azurerm_route_table" "lab02a" {
  name                          = "${local.lab02a_name}-routes-${local.random_str}"
  location                      = azurerm_resource_group.az500.location
  resource_group_name           = azurerm_resource_group.az500.name
  disable_bgp_route_propagation = true

  route {
    name                   = "fw-dg"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.lab02a.ip_configuration[0].private_ip_address
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet_route_table_association" "lab02a" {
  subnet_id      = azurerm_subnet.lab02a.id
  route_table_id = azurerm_route_table.lab02a.id
}

resource "azurerm_dns_zone" "lab02a" {
  name                = "${local.lab02a_name}-public-dns-${local.random_str}.com"
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone" "lab02a" {
  name                = "${local.lab02a_name}-private-dns-${local.random_str}.local"
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "lab02a" {
  name                  = "${local.lab02a_name}-zone-link-${local.random_str}"
  resource_group_name   = azurerm_resource_group.az500.name
  private_dns_zone_name = azurerm_private_dns_zone.lab02a.name
  virtual_network_id    = azurerm_virtual_network.lab02a.id
  registration_enabled  = true

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface" "lab02a" {
  name                = "${local.lab02a_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  dns_servers         = ["8.8.8.8", "8.8.4.4"]

  ip_configuration {
    name                          = "${local.lab02a_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab02a.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_windows_virtual_machine" "lab02a" {
  name                  = "${local.lab02a_name}-vm-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab02a.id]
  size                  = local.vm_size

  os_disk {
    name                 = "${local.lab02a_name}-osdisk-${local.random_str}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  computer_name  = "${local.lab02a_name}-vm-${local.random_str}"
  admin_username = local.user_name
  admin_password = local.user_passowrd

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_extension" "lab02ascript" {
  name                       = "${local.lab02a_name}-vm-script-${local.random_str}"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = true
  virtual_machine_id         = azurerm_windows_virtual_machine.lab02a.id

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value $('Hello World from ' + $env:computername)"
    }
  SETTINGS

  tags = {
    environment = local.group_name
  }
}
