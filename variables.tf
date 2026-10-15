variable "location" {
  description = "Azure region where all resources will be deployed"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-zero-trust-aks-swec"
}

variable "vnet_address_space" {
  description = "Address space for the custom Virtual Network"
  type        = list(string)
  default     = ["10.240.0.0/16"]
}

variable "aks_nodes_subnet_prefix" {
  description = "Address prefix for the AKS worker nodes subnet"
  type        = string
  default     = "10.240.0.0/22"
}

variable "mgmt_subnet_prefix" {
  description = "Address prefix for the management / jumpbox subnet"
  type        = string
  default     = "10.240.4.0/24"
}

variable "private_endpoints_subnet_prefix" {
  description = "Address prefix for the private endpoints subnet"
  type        = string
  default     = "10.240.5.0/24"
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for AzureBastionSubnet (minimum /26 required by Azure)"
  type        = string
  default     = "10.240.6.0/26"
}

variable "bastion_sku" {
  description = "SKU for Azure Bastion (Standard required for native client tunneling/SSH)"
  type        = string
  default     = "Standard"
}

variable "jumpbox_vm_size" {
  description = "Size of the Jumpbox VM for cluster management (cost optimized)"
  type        = string
  default     = "Standard_B2s"
}

variable "jumpbox_admin_username" {
  description = "Administrator username for the Jumpbox VM"
  type        = string
  default     = "azureuser"
}

variable "jumpbox_private_ip" {
  description = "Private IP address assigned to the management Jumpbox NIC"
  type        = string
  default     = "10.240.4.4"
}

variable "cluster_name" {
  description = "Name of the Private AKS cluster"
  type        = string
  default     = "aks-zerotrust-swec"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster (null for Azure default)"
  type        = string
  default     = null
}

variable "aks_node_count" {
  description = "Number of worker nodes in the default node pool"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "VM SKU for the AKS default node pool (cost optimized, available across all zones in Sweden Central)"
  type        = string
  default     = "Standard_B2s_v2"
}

variable "aks_availability_zones" {
  description = "Availability zones for the AKS default node pool"
  type        = list(string)
  default     = ["1", "2", "3"]
}

variable "aks_pod_cidr" {
  description = "Pod CIDR range for Azure CNI Overlay"
  type        = string
  default     = "10.244.0.0/16"
}

variable "aks_service_cidr" {
  description = "Kubernetes Service CIDR range"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_dns_service_ip" {
  description = "IP address within aks_service_cidr for CoreDNS"
  type        = string
  default     = "10.0.0.10"
}

variable "k8s_service_account_namespace" {
  description = "Kubernetes namespace for the workload identity ServiceAccount"
  type        = string
  default     = "default"
}

variable "k8s_service_account_name" {
  description = "Kubernetes ServiceAccount name for federated identity"
  type        = string
  default     = "workload-identity-sa"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Zero-Trust-Private"
    Project     = "Zero-Trust-AKS"
    ManagedBy   = "Terraform"
  }
}
