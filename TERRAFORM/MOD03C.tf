## LAB-01-WEB-APP
resource "azurerm_storage_account" "lab03c" {
  name                     = "${local.lab03c_name}stor${local.random_str}"
  resource_group_name      = azurerm_resource_group.az500.name
  location                 = azurerm_resource_group.az500.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_storage_container" "lab03ccontainer" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.lab03c.name
  container_access_type = "blob"
}
