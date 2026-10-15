# Private DNS Zone for Azure Key Vault
resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Link Private DNS Zone to the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "vault_link" {
  name                  = "vnet-link-vaultcore"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.tags
}
