data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group for Zero-Trust AKS Architecture
# (If using a pre-existing Resource Group, change 'resource' to 'data' and remove 'location' and 'tags')
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
