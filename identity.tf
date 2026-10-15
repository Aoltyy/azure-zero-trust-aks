# User-Assigned Managed Identity for AKS Workload Identity
resource "azurerm_user_assigned_identity" "workload_identity" {
  name                = "uami-aks-workload-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Role Assignment: Key Vault Secrets User granted to the Managed Identity
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload_identity.principal_id
}

# Federated Identity Credential linking AKS OIDC Issuer & K8s ServiceAccount
resource "azurerm_federated_identity_credential" "workload_federation" {
  name                = "fed-cred-${var.k8s_service_account_name}"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.workload_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${var.k8s_service_account_namespace}:${var.k8s_service_account_name}"
}
