resource "azurerm_log_analytics_workspace" "lab04a" {
  name                = "${local.lab04a_name}-sentinel-${local.random_str}"
  location            = azurerm_resource_group.az500.location
  resource_group_name = azurerm_resource_group.az500.name
  sku                 = "PerGB2018"
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "lab04a" {
  workspace_id = azurerm_log_analytics_workspace.lab04a.id
}

resource "azurerm_sentinel_data_connector_azure_security_center" "lab04a" {
  name                       = "${local.lab04a_name}-sentinel-sc-conn-${local.random_str}"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.lab04a.workspace_id
}