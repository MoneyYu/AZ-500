## LAB-01-WEB-APP
resource "azurerm_storage_account" "lab03b" {
  name                     = "${local.lab03b_name}stor${local.random_str}"
  resource_group_name      = azurerm_resource_group.az500.name
  location                 = azurerm_resource_group.az500.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_storage_container" "lab03bcontainer" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.lab03b.name
  container_access_type = "blob"
}

resource "azurerm_app_service_plan" "lab03b" {
  name                = "${local.lab03b_name}-app-plan-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S2"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_app_service" "lab03b" {
  name                = "${local.lab03b_name}-app-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  app_service_plan_id = azurerm_app_service_plan.lab03b.id

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
  }

  app_settings = {
    "WEBSITE_TIME_ZONE" = "Asia/Taipei"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_app_service_slot" "lab03bstage" {
  name                = "stage"
  app_service_name    = azurerm_app_service.lab03b.name
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  app_service_plan_id = azurerm_app_service_plan.lab03b.id

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
  }

  app_settings = {
    "WEBSITE_TIME_ZONE" = "Asia/Taipei"
  }

  tags = {
    environment = local.group_name
  }
}

resource "azurerm_app_service_slot" "lab03bdev" {
  name                = "dev"
  app_service_name    = azurerm_app_service.lab03b.name
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  app_service_plan_id = azurerm_app_service_plan.lab03b.id

  site_config {
    linux_fx_version = "DOTNETCORE|3.1"
  }

  app_settings = {
    "WEBSITE_TIME_ZONE" = "Asia/Taipei",
  }

  tags = {
    environment = local.group_name
  }
}
