# SSH Key Pair Generation for Jumpbox Access
resource "tls_private_key" "jumpbox_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally for operator access (excluded from Git via .gitignore)
resource "local_file" "jumpbox_private_key" {
  content         = tls_private_key.jumpbox_ssh.private_key_pem
  filename        = "${path.module}/jumpbox_key.pem"
  file_permission = "0600"
}

# Network Interface for Jumpbox VM in mgmt-subnet (100% Private - Zero Public IP)
resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "nic-jumpbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.jumpbox_private_ip
  }

  tags = var.tags
}

# Cloud-init configuration for Jumpbox: preinstalls az cli, kubectl, kubelogin, helm
locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    package_upgrade: true
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - gnupg
      - lsb-release
      - jq
      - unzip

    runcmd:
      # Install Azure CLI
      - mkdir -p /etc/apt/keyrings
      - curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null
      - chmod go+r /etc/apt/keyrings/microsoft.gpg
      - echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list
      - apt-get update
      - apt-get install -y azure-cli

      # Install kubectl
      - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      - chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
      - apt-get update
      - apt-get install -y kubectl

      # Install kubelogin
      - az aks install-cli

      # Install Helm
      - curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null
      - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
      - apt-get update
      - apt-get install -y helm

      - echo "Zero-Trust Jumpbox setup complete!" >> /etc/motd
  EOF
}

# User-Assigned Identity for Jumpbox Administration
resource "azurerm_user_assigned_identity" "jumpbox_identity" {
  name                = "uami-jumpbox-admin"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Role Assignment: AKS Cluster Admin Role for Jumpbox Operator
resource "azurerm_role_assignment" "jumpbox_aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azurerm_user_assigned_identity.jumpbox_identity.principal_id
}

# Role Assignment: Key Vault Secrets Officer for Jumpbox Operator to seed secrets
resource "azurerm_role_assignment" "jumpbox_kv_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.jumpbox_identity.principal_id
}

# Jumpbox Linux VM (Standard_B2s)
resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "vm-jumpbox"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.jumpbox_vm_size
  admin_username      = var.jumpbox_admin_username

  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  admin_ssh_key {
    username   = var.jumpbox_admin_username
    public_key = tls_private_key.jumpbox_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.jumpbox_identity.id]
  }

  custom_data = base64encode(local.cloud_init)

  tags = var.tags
}
