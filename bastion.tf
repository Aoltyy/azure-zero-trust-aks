# ==============================================================================
# Azure Bastion Host Configuration (Standard SKU - Native Client SSH Tunneling)
# ==============================================================================

# Public IP for Azure Bastion (Standard SKU, Static allocation required)
resource "azurerm_public_ip" "bastion_pip" {
  name                = "pip-azure-bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Bastion Host with Native Client Tunneling Enabled
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-zerotrust-swec"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.bastion_sku

  # Feature flags for Standard SKU
  copy_paste_enabled     = true
  file_copy_enabled      = false
  shareable_link_enabled = false
  tunneling_enabled      = true # Enables 'az network bastion ssh' & native client tunneling

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }

  tags = var.tags
}
