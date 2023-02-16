locals {
  apim_policy_path = format("%s%s", var.apim_policies_path, "apim_policy.xml")
}

resource "azurerm_resource_group" "apim" {
  name     = "${var.resource_group_name}-apim-${lower(var.environment)}"
  location = var.location
  tags     = var.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_application_insights" "apim" {
  name                = "apimappinsights${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.apim.name
  application_type    = "web"

  retention_in_days   = 90
  sampling_percentage = 0
  tags                = var.tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "azurerm_api_management" "apim" {
  name                = "apim-aisdemo-${lower(var.environment)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.apim.name

  notification_sender_email = "apimgmt-noreply@mail.windowsazure.com"
  policy {
    xml_content = file(local.apim_policy_path)
  }

  publisher_email      = "russell.smith@microsoft.com"
  publisher_name       = "Demo"
  sku_name             = "Developer_1"
  tags                 = var.tags
  virtual_network_type = "None"

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags, policy.0.xml_content, hostname_configuration,
    ]
  }
}

resource "azurerm_api_management_group" "apim-devs" {
  name                = "api-devs"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "API Developers Group"
  description         = "This is an example API management group for API developers."
}

resource "azurerm_api_management_group" "apim-external" {
  name                = "api-external"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name
  display_name        = "API External Group"
  description         = "This is an example API management group for API external callers."
}

resource "azurerm_api_management_product" "prod-free" {
  product_id            = "free-product"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.apim.name
  display_name          = "Free Product"
  subscription_required = false
  approval_required     = false
  published             = true
}

resource "azurerm_api_management_product" "prod-pay" {
  product_id            = "pay-product"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.apim.name
  display_name          = "Pay Product"
  subscription_required = true
  subscriptions_limit   = 10
  approval_required     = true
  published             = true
}

resource "azurerm_api_management_product_group" "api-dev" {
  product_id          = azurerm_api_management_product.prod-pay.product_id
  group_name          = azurerm_api_management_group.apim-devs.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_api_management.apim.resource_group_name
}

resource "azurerm_api_management_product_group" "api-ext" {
  product_id          = azurerm_api_management_product.prod-pay.product_id
  group_name          = azurerm_api_management_group.apim-external.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_api_management.apim.resource_group_name
}