## MOD-01
resource "azurerm_mssql_server" "lab03d" {
  name                         = "${local.lab03d_name}-azure-sql-${local.random_str}"
  resource_group_name          = azurerm_resource_group.az500.name
  location                     = azurerm_resource_group.az500.location
  version                      = "12.0"
  administrator_login          = var.user_name
  administrator_login_password = var.user_passowrd

  azuread_administrator {
    login_username = "Money Yu"
    object_id      = local.admin_oid
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_mssql_firewall_rule" "lab03d01" {
  name             = "FirewallRule-Money"
  server_id        = azurerm_mssql_server.lab03d.id
  start_ip_address = chomp(data.http.myip.response_body)
  end_ip_address   = chomp(data.http.myip.response_body)
}

resource "azurerm_mssql_firewall_rule" "lab03d02" {
  name             = "FirewallRule-Azure"
  server_id        = azurerm_mssql_server.lab03d.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_server_extended_auditing_policy" "lab03d" {
  server_id                               = azurerm_mssql_server.lab03d.id
  storage_endpoint                        = azurerm_storage_account.lab03d.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.lab03d.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 7
}

resource "azurerm_storage_account" "lab03d" {
  name                     = "${local.lab03d_name}stor${local.random_str}"
  resource_group_name      = azurerm_resource_group.az500.name
  location                 = azurerm_resource_group.az500.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.group_name
  }
}

## MOD-01-C-SQL-DATABASE
resource "azurerm_mssql_database" "lab03d" {
  name         = "${local.lab03d_name}-single-db-${local.random_str}"
  server_id    = azurerm_mssql_server.lab03d.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name     = "S1"
  license_type = "BasePrice"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_mssql_database_extended_auditing_policy" "lab03d" {
  database_id                             = azurerm_mssql_database.lab03d.id
  storage_endpoint                        = azurerm_storage_account.lab03d.primary_blob_endpoint
  storage_account_access_key              = azurerm_storage_account.lab03d.primary_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = 6
}

resource "azurerm_virtual_network" "lab03d" {
  name                = "${local.lab03d_name}-vnet-${local.random_str}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_subnet" "lab03d" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.az500.name
  virtual_network_name = azurerm_virtual_network.lab03d.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_public_ip" "lab03d" {
  name                = "${local.lab03d_name}-pip-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  allocation_method   = "Static"
  domain_name_label   = "${local.lab03d_name}-pip-${local.random_str}"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_group" "lab03d" {
  name                = "${local.lab03d_name}-nsg-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_security_rule" "lab03d01" {
  name                        = "RDP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "3389"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az500.name
  network_security_group_name = azurerm_network_security_group.lab03d.name
}

resource "azurerm_network_security_rule" "lab03d02" {
  name                        = "MSSQL"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = chomp(data.http.myip.response_body)
  destination_port_range      = "1433"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.az500.name
  network_security_group_name = azurerm_network_security_group.lab03d.name
}

resource "azurerm_network_interface" "lab03d" {
  name                = "${local.lab03d_name}-nic-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  ip_configuration {
    name                          = "${local.lab03d_name}-nic-ipconfig-${local.random_str}"
    subnet_id                     = azurerm_subnet.lab03d.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab03d.id
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_network_interface_security_group_association" "lab03d" {
  network_interface_id      = azurerm_network_interface.lab03d.id
  network_security_group_id = azurerm_network_security_group.lab03d.id
}

resource "azurerm_windows_virtual_machine" "lab03d" {
  name                  = "${local.lab03d_name}-sqlvm-${local.random_str}"
  location              = azurerm_resource_group.az500.location
  resource_group_name   = azurerm_resource_group.az500.name
  network_interface_ids = [azurerm_network_interface.lab03d.id]
  size                  = "Standard_B4ms"

  computer_name  = "${local.lab03d_name}-vm-${local.random_str}"
  admin_username = var.user_name
  admin_password = var.user_passowrd

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2019"
    sku       = "sqldev-gen2"
    version   = "latest"
  }

  provision_vm_agent       = true
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"
  timezone                 = "Taipei Standard Time"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_managed_disk" "lab03d_datadisk" {
  name                 = "${local.lab03d_name}-datadisk-${local.random_str}"
  location             = azurerm_resource_group.az500.location
  resource_group_name  = azurerm_resource_group.az500.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "lab03d_datadisk_attach" {
  managed_disk_id    = azurerm_managed_disk.lab03d_datadisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.lab03d.id
  lun                = 1
  caching            = "ReadWrite"
}

# add a log disk - we were going to iterate through a collection, but this is easier for now
resource "azurerm_managed_disk" "lab03d_logdisk" {
  name                 = "${local.lab03d_name}-logdisk-${local.random_str}"
  location             = azurerm_resource_group.az500.location
  resource_group_name  = azurerm_resource_group.az500.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "lab03d_logdisk_attach" {
  managed_disk_id    = azurerm_managed_disk.lab03d_logdisk.id
  virtual_machine_id = azurerm_windows_virtual_machine.lab03d.id
  lun                = 2
  caching            = "ReadWrite"
}

resource "azurerm_mssql_virtual_machine" "lab03d" {
  virtual_machine_id               = azurerm_windows_virtual_machine.lab03d.id
  sql_license_type                 = "PAYG"
  r_services_enabled               = true
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PUBLIC"
  sql_connectivity_update_username = var.user_name
  sql_connectivity_update_password = var.user_passowrd

  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }

  auto_backup {
    retention_period_in_days   = 7
    storage_blob_endpoint      = azurerm_storage_account.lab03d.primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.lab03d.primary_access_key
  }

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "OLTP"

    data_settings {
      default_file_path = "F:\\data"
      luns              = [azurerm_virtual_machine_data_disk_attachment.lab03d_datadisk_attach.lun]
    }

    log_settings {
      default_file_path = "G:\\log"
      luns              = [azurerm_virtual_machine_data_disk_attachment.lab03d_logdisk_attach.lun]
    }

    temp_db_settings {
      default_file_path = "D:\\TempDb"
      luns              = []
    }
  }

  tags = {
    environment = local.group_name
  }
}
