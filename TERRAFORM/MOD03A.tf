## LAB-07-KEY-VALUT
resource "azurerm_key_vault" "lab03a" {
  name                        = "${local.lab03a_name}-key-vault-${local.random_str}"
  location                    = azurerm_resource_group.az500.location
  resource_group_name         = azurerm_resource_group.az500.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "b8e50bc5-6559-4643-a003-2807a8d707f7"

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [chomp(data.http.myip.response_body)]
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_user_assigned_identity" "lab03a" {
  name                = "${local.lab03a_name}-managed-id-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name

  tags = {
    environment = local.group_name
  }
}
