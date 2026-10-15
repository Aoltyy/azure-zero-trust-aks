output "resource_group_name" {
  description = "Name of the deployed Resource Group"
  value       = azurerm_resource_group.rg.name
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "aks_nodes_subnet_id" {
  description = "ID of the AKS worker nodes subnet"
  value       = azurerm_subnet.aks_nodes.id
}

output "mgmt_subnet_id" {
  description = "ID of the management subnet"
  value       = azurerm_subnet.mgmt.id
}

output "private_endpoints_subnet_id" {
  description = "ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "Vault URI of the Azure Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "key_vault_private_endpoint_ip" {
  description = "Private IP address assigned to the Key Vault Private Endpoint"
  value       = azurerm_private_endpoint.kv_pe.private_service_connection[0].private_ip_address
}

output "aks_cluster_name" {
  description = "Name of the Private AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "Resource ID of the Private AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_oidc_issuer_url" {
  description = "OIDC Issuer URL of the AKS cluster for Workload Identity"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "workload_identity_client_id" {
  description = "Client ID of the User-Assigned Managed Identity for K8s ServiceAccount"
  value       = azurerm_user_assigned_identity.workload_identity.client_id
}

output "workload_identity_tenant_id" {
  description = "Tenant ID for Azure Workload Identity"
  value       = data.azurerm_client_config.current.tenant_id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion Subnet"
  value       = azurerm_subnet.bastion.id
}

output "bastion_host_name" {
  description = "Name of the Azure Bastion Host"
  value       = azurerm_bastion_host.bastion.name
}

output "bastion_public_ip" {
  description = "Public IP address of the Azure Bastion Host"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "jumpbox_vm_id" {
  description = "Resource ID of the Jumpbox Linux Virtual Machine"
  value       = azurerm_linux_virtual_machine.jumpbox.id
}

output "jumpbox_private_ip" {
  description = "Private IP address of the Jumpbox VM (100% private in mgmt-subnet)"
  value       = azurerm_network_interface.jumpbox_nic.ip_configuration[0].private_ip_address
}

output "bastion_ssh_command" {
  description = "Azure CLI Bastion tunneling command to connect securely to the private Jumpbox"
  value       = "az network bastion ssh --name ${azurerm_bastion_host.bastion.name} --resource-group ${azurerm_resource_group.rg.name} --target-resource-id ${azurerm_linux_virtual_machine.jumpbox.id} --auth-type ssh-key --username ${var.jumpbox_admin_username} --ssh-key jumpbox_key.pem"
}
