# Security Policy & Zero-Trust Architecture

## 1. Zero-Trust Security Model

This repository implements a **Zero-Trust Private Architecture** on Azure adhering to the core principle: *"Never trust, always verify"*.

### Key Security Controls:
1. **Network Isolation**:
   - **100% Private AKS API Server**: Accessible exclusively from within the virtual network (via Jumpbox / Bastion); no public control plane endpoint.
   - **Private Azure Key Vault**: Public network access is disabled (`public_network_access_enabled = false`). All communication traverses Azure Private Link over a dedicated private endpoint.
   - **Microsegmentation with Cilium eBPF**: Default-deny pod egress policies enforced directly inside the Linux kernel via eBPF. Only authorized flows (CoreDNS, Key Vault Private Endpoint, and API server) are permitted.

2. **Identity & Secrets Governance**:
   - **Entra ID Workload Identity**: Eliminates hardcoded service principal credentials and secrets stored in Kubernetes Secrets. Pods obtain short-lived Microsoft Entra tokens via OIDC federation.
   - **Secrets Store CSI Driver**: Secrets are retrieved over TLS from Key Vault and mounted as ephemeral in-memory tmpfs volumes, preventing secret persistence on node storage disks.
   - **Least-Privilege Azure RBAC**: Fine-grained role assignments (`Key Vault Secrets User` for pods, `Key Vault Secrets Officer` and `Cluster Admin` for Jumpbox operations).

3. **Perimeter Defense**:
   - Network Security Groups (NSGs) with default-deny inbound rules.
   - **Zero Public Jumpbox Attack Surface**: Management Jumpbox has zero public IP and zero public SSH exposure; inbound SSH (port 22) is restricted strictly to `AzureBastionSubnet` (`10.240.6.0/26`) and accessible exclusively via Azure Bastion native tunneling (`az network bastion ssh`) or the Azure Portal over TLS 443.

---

## 2. Security Best Practices for Repository Consumers

Before applying this infrastructure in production:
- **Do NOT commit `.tfvars` files**: Keep your personal IP addresses, client secrets, and environment IDs in local `.tfvars` files ignored by Git.
- **Do NOT commit `.tfstate` files**: Store remote Terraform state in an Azure Storage Account with Private Endpoints, Customer-Managed Keys (CMK), and Azure AD authentication.
- **Rotate SSH Keys Regularly**: Discard and rotate generated SSH keys using your organizational key management policies.
- **Authenticate via Azure Bastion**: Access the Jumpbox VM exclusively via Azure Bastion native client tunneling with Microsoft Entra ID authorization; do not assign public IPs or create public SSH inbound rules.

---

## 3. Reporting a Vulnerability

If you discover a potential security vulnerability within this repository, please report it privately via GitHub Security Advisories or by contacting the project maintainers. Please do not open public issues for sensitive security vulnerabilities.
