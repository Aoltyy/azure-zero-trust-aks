# Zero-Trust Private AKS Platform on Azure

Production-ready Terraform repository deploying a **Zero-Trust Private AKS Platform** on Azure featuring **Azure CNI with Cilium (eBPF Data Plane)**, **Microsoft Entra ID Workload Identity**, and **Azure Key Vault Secrets Store CSI Driver**.

---

## Architecture Overview

```text
                               +-------------------------------------------------------------+
                               |                 Virtual Network (10.240.0.0/16)             |
                               |                                                             |
+---------------------+        |  +---------------------+        +------------------------+  |
|  External Operator  |=======>|  | AzureBastionSubnet  |        | aks-nodes-subnet       |  |
| (az bastion ssh)    | TLS 443|  | (10.240.6.0/26)     |        | (10.240.0.0/22)        |  |
+---------------------+        |  | [Azure Bastion Host]|        |                        |  |
                               |  +----------+----------+        |                        |  |
                               |             | (Private SSH 22)  |                        |  |
                               |             v                   |                        |  |
                               |  +---------------------+        | [Private AKS API]      |  |
                               |  | mgmt-subnet         |=======>| (No Public IP)         |  |
                               |  | (10.240.4.0/24)     | TCP 443|                        |  |
                               |  | [Private Jumpbox VM]|        |                        |  |
                               |  | (Zero Public IP)    |        | [AKS Worker Nodes]     |  |
                               |  +---------------------+        |  - Azure CNI Overlay   |  |
                               |                                 |  - Cilium eBPF Engine  |  |
                               |  +---------------------+        |  - Secrets CSI Driver  |  |
                               |  | private-endpoints   |        +-----------+------------+  |
                               |  | subnet              |                    |               |
                               |  | (10.240.5.4)        |<===================|               |
                               |  | [Key Vault PE NIC]  |  Private Link (443)                |
                               |  +----------+----------+                                    |
                               +-------------|-----------------------------------------------+
                                             |                               |
                                             v                               v
                              +------------------------------+  +----------------------------+
                              | Azure Key Vault (Private)    |  | Microsoft Entra ID         |
                              | - Public Access: Disabled    |  | - Workload Identity (OIDC) |
                              | - RBAC Authorization         |  | - Federated Credentials    |
                              +------------------------------+  +----------------------------+
```

### Key Capabilities
- **Strict Network Isolation**: 4-tier VNet subnet architecture (`AzureBastionSubnet`, `aks-nodes-subnet`, `mgmt-subnet`, `private-endpoints-subnet`) with default-deny NSGs.
- **Azure Bastion Native Client Access**: Fully managed Azure Bastion (Standard SKU) providing TLS 443 tunneling to the Jumpbox VM without exposing port 22 or any public IP on the VM.
- **Private Kubernetes Control Plane**: Fully private AKS API server endpoint with system-managed private DNS resolution.
- **Azure CNI Overlay + Cilium eBPF**: High-performance container networking with kernel-level eBPF pod isolation and network policy enforcement.
- **Zero-Trust Secrets Management**: Azure Key Vault with 100% private access over Private Link (`privatelink.vaultcore.azure.net`). Ephemeral secret mounting into pod tmpfs memory volumes via the Secrets Store CSI Driver.
- **Entra ID Workload Identity**: Passwordless, credential-free token exchange between Kubernetes ServiceAccounts and Azure Managed Identities.
- **Dedicated Private Management Jumpbox**: Preconfigured with `azure-cli`, `kubectl`, `kubelogin`, and `helm` for out-of-the-box private cluster operations.

---

## Repository Structure

```text
├── .gitignore                    # Comprehensive Terraform & Azure secret exclusion rules
├── SECURITY.md                   # Zero-Trust security model and disclosure policy
├── versions.tf                   # Terraform version (>= 1.5.0) and AzureRM provider constraints
├── main.tf                       # Client config, resource group, and naming suffix
├── variables.tf                  # Input variables with production-ready defaults
├── terraform.tfvars.example      # Sanitized template configuration
├── network.tf                    # VNet, 4 Subnets, NSGs, and associations
├── bastion.tf                    # Azure Bastion Host (Standard SKU) & dedicated Public IP
├── private_dns.tf                # Private DNS zone for Key Vault Private Endpoint
├── keyvault.tf                   # Zero-trust Key Vault and Private Endpoint
├── aks.tf                        # Private AKS cluster, Azure CNI Overlay, Cilium eBPF
├── identity.tf                   # User-Assigned Managed Identity & Federated Credentials
├── jumpbox.tf                    # 100% Private Jumpbox VM (Standard_B2ats_v2), SSH key, and cloud-init
├── outputs.tf                    # Infrastructure outputs (IPs, URIs, Bastion connection strings)
└── k8s/
    ├── secretproviderclass.yaml  # SecretProviderClass template targeting Azure Key Vault
    ├── workload-identity-demo.yaml # Workload Identity ServiceAccount & Consumer Pod
    └── cilium-network-policy.yaml  # Cilium eBPF zero-trust egress network policy
```

---

## Quickstart Deployment

### 1. Prerequisites
- [Terraform >= 1.5.0](https://developer.hashicorp.com/terraform/downloads)
- [Azure CLI >= 2.50.0](https://learn.microsoft.com/cli/azure/install-azure-cli)
- Authenticated Azure subscription (`az login`)

### 2. Configure Environment
Clone the repository and prepare your configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan -out=tfplan
terraform apply "tfplan"
```

Upon successful apply, Terraform outputs the connection details and saves `jumpbox_key.pem` locally.

---

## Post-Deployment Verification (via Azure Bastion)

Because public network access is completely disabled, all administrative interactions occur securely through Azure Bastion to the private Jumpbox VM.

### Step 1: Connect to Jumpbox VM via Azure Bastion
Execute the output command generated by Terraform:
```bash
chmod 600 jumpbox_key.pem

az network bastion ssh \
  --name "bastion-zerotrust-swec" \
  --resource-group "<RESOURCE_GROUP_NAME>" \
  --target-resource-id "<JUMPBOX_VM_ID>" \
  --auth-type "ssh-key" \
  --username "azureuser" \
  --ssh-key "jumpbox_key.pem"
```

### Step 2: Authenticate on Jumpbox
The Jumpbox has an assigned Managed Identity with `Key Vault Secrets Officer` and `AKS Cluster Admin`:
```bash
az login --identity
```

### Step 3: Seed Secret in Private Key Vault
```bash
export KEY_VAULT_NAME="<OUTPUT_KEY_VAULT_NAME>"

az keyvault secret set \
  --vault-name "$KEY_VAULT_NAME" \
  --name "demo-app-secret" \
  --value "<YOUR_SECRET_VALUE_HERE>"
```

### Step 4: Obtain Private AKS Credentials
```bash
export RESOURCE_GROUP="<OUTPUT_RESOURCE_GROUP>"
export CLUSTER_NAME="aks-zerotrust-swec"

az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --admin --overwrite-existing
kubectl get nodes -o wide
```

### Step 5: Deploy Workload Identity & CSI Consumer
Apply the manifests located in the `k8s/` folder:

```bash
# Apply SecretProviderClass
kubectl apply -f k8s/secretproviderclass.yaml

# Apply ServiceAccount & Application
kubectl apply -f k8s/workload-identity-demo.yaml
```

### Step 6: Verify In-Memory Secret Retrieval
Inspect the pod filesystem to confirm the secret is mounted in memory:

```bash
# Check pod status
kubectl get pods -l app=zero-trust-secret-consumer

# Inspect the CSI volume mount directory
kubectl exec -it deployment/zero-trust-secret-consumer -- ls -la /mnt/secrets-store/

# Read the secret directly from the in-memory mount
kubectl exec -it deployment/zero-trust-secret-consumer -- cat /mnt/secrets-store/demo-app-secret
```

### Step 7: Enforce & Test Cilium eBPF Network Policies
Apply the zero-trust Cilium policy:

```bash
kubectl apply -f k8s/cilium-network-policy.yaml
kubectl get cnp -A
```

Verify that unauthorized outbound traffic is dropped by the eBPF kernel layer:

```bash
POD_NAME=$(kubectl get pod -l app=zero-trust-secret-consumer -o jsonpath='{.items[0].metadata.name}')

# 1. ALLOWED: CoreDNS resolution (Port 53)
kubectl exec -it "$POD_NAME" -- python3 -c "import socket; print('RESOLVED:', socket.gethostbyname('kubernetes.default.svc.cluster.local'))"

# 2. ALLOWED: Key Vault Private Endpoint (10.240.5.4:443)
kubectl exec -it "$POD_NAME" -- python3 -c "import socket; s = socket.socket(); s.settimeout(3); s.connect(('10.240.5.4', 443)); print('CONNECTED to Key Vault!')"

# 3. BLOCKED: Outbound Internet Egress (google.com:443)
kubectl exec -it "$POD_NAME" -- curl -m 4 -s https://google.com || echo "BLOCKED by Cilium eBPF as expected!"

# 4. BLOCKED: Outbound Direct Public IP (1.1.1.1:443)
kubectl exec -it "$POD_NAME" -- python3 -c "import socket; s = socket.socket(); s.settimeout(3); s.connect(('1.1.1.1', 443))" || echo "BLOCKED by Cilium eBPF as expected!"
```

---

## Cost Optimization & Power Management

To avoid incurring cloud compute charges when not actively in use:

### Suspend Compute Billing
```bash
az vm deallocate --resource-group "<RESOURCE_GROUP>" --name vm-jumpbox --no-wait
az aks stop --resource-group "<RESOURCE_GROUP>" --name aks-zerotrust-swec --no-wait
```

### Resume Compute
```bash
az vm start --resource-group "<RESOURCE_GROUP>" --name vm-jumpbox --no-wait
az aks start --resource-group "<RESOURCE_GROUP>" --name aks-zerotrust-swec --no-wait
```

---

## Teardown

To permanently destroy all infrastructure:

```bash
terraform destroy -auto-approve
```

---

## License

This project is licensed under the Apache 2.0 License.
