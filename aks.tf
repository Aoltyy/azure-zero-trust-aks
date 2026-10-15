# Private AKS Cluster with Azure CNI Overlay & Cilium eBPF
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-zt-${random_string.suffix.result}"
  kubernetes_version  = var.kubernetes_version

  # Zero-Trust Private API Server
  private_cluster_enabled = true
  private_dns_zone_id     = "System"

  # Workload Identity & OIDC Issuer
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Key Vault Secrets Store CSI Driver Addon
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Azure CNI Overlay with Cilium eBPF
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    pod_cidr            = var.aks_pod_cidr
    service_cidr        = var.aks_service_cidr
    dns_service_ip      = var.aks_dns_service_ip
  }

  # Default Node Pool
  default_node_pool {
    name           = "systempool"
    node_count     = var.aks_node_count
    vm_size        = var.aks_vm_size
    zones          = var.aks_availability_zones
    vnet_subnet_id = azurerm_subnet.aks_nodes.id

    os_disk_size_gb = 64
    os_disk_type    = "Managed"

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_subnet_network_security_group_association.aks_assoc
  ]
}

# Grant Network Contributor on VNet to AKS Cluster Identity
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
