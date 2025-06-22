# etcd Encryption at Rest

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Implement and manage etcd encryption at rest using EncryptionConfiguration to secure sensitive data stored in the cluster's etcd database.

## Context
Your organization, DataSecure Enterprises, has strict compliance requirements mandating that all sensitive data must be encrypted at rest. The security audit team has identified that Kubernetes secrets, ConfigMaps, and other sensitive resources stored in etcd are currently unencrypted. You need to implement etcd encryption at rest, demonstrate the encryption is working, and establish key rotation procedures to meet enterprise security standards.

## Prerequisites
- Killercoda Ubuntu Playground environment
- Basic understanding of Kubernetes architecture and etcd
- Familiarity with kubectl, kubeadm, and etcdctl commands
- Understanding of encryption concepts (AES, key management)

## Tasks

### Task 1: Cluster Initialization and Environment Setup
**Time: 10 minutes**

Initialize a kubeadm Kubernetes cluster and prepare the environment for encryption configuration.

1. **Install and initialize kubeadm cluster**:
   - Install Docker, kubeadm, kubelet, and kubectl
   - Initialize cluster with kubeadm using pod network CIDR
   - Configure kubectl access with admin credentials

2. **Install CNI and verify cluster**:
   - Deploy Flannel or Calico CNI plugin
   - Verify node status and basic cluster functionality
   - Install etcdctl for direct etcd access

3. **Create test secret before encryption**:
   - Create a secret named **test-secret-before** in namespace **default**
   - Store key-value pair: **username=admin** and **password=secretpassword**
   - This will demonstrate the difference between encrypted and unencrypted data

**Hint**: Use `kubeadm init --pod-network-cidr=10.244.0.0/16` and remember to save the join command.

### Task 2: Create EncryptionConfiguration Resource
**Time: 8 minutes**

Create and configure the EncryptionConfiguration resource with multiple encryption providers.

1. **Create encryption configuration file**:
   - Create file `/etc/kubernetes/encryption-config.yaml`
   - Configure providers in priority order: **aescbc**, **aes-gcm**, and **identity**
   - Generate a 32-byte base64-encoded encryption key for AES-CBC
   - Generate a 32-byte base64-encoded encryption key for AES-GCM

2. **Configure encryption for multiple resource types**:
   - Include **secrets** resource encryption
   - Include **configmaps** resource encryption
   - Set proper resource versions and provider configurations

**Hint**: Use `head -c 32 /dev/urandom | base64` to generate encryption keys.

### Task 3: Apply Encryption Configuration to API Server
**Time: 8 minutes**

Configure the kube-apiserver to use the encryption configuration and restart the component.

1. **Update kube-apiserver manifest**:
   - Edit `/etc/kubernetes/manifests/kube-apiserver.yaml`
   - Add `--encryption-provider-config=/etc/kubernetes/encryption-config.yaml` flag
   - Mount the encryption config file into the container

2. **Restart and verify API server**:
   - Wait for kube-apiserver pod to restart automatically
   - Verify cluster connectivity with kubectl
   - Check API server logs for encryption configuration loading

3. **Create test secret after encryption**:
   - Create secret named **test-secret-after** with same credentials
   - This will be stored encrypted in etcd

**Hint**: The kubelet will automatically restart the static pod when the manifest changes.

### Task 4: Verify Encryption Implementation
**Time: 10 minutes**

Verify that new secrets are encrypted in etcd while old secrets remain unencrypted.

1. **Access etcd directly**:
   - Use etcdctl to connect to etcd with proper certificates
   - Set required environment variables for etcd access
   - List all keys in etcd under `/registry/secrets/`

2. **Compare encrypted vs unencrypted data**:
   - Examine **test-secret-before** data in etcd (should be plaintext)
   - Examine **test-secret-after** data in etcd (should be encrypted)
   - Verify the encryption prefix in the encrypted secret

3. **Test ConfigMap encryption**:
   - Create a ConfigMap named **test-config-encrypted**
   - Verify it's encrypted in etcd storage
   - Compare with kubectl output to ensure proper decryption

**Hint**: Use `ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key`

### Task 5: Encrypt Existing Secrets
**Time: 5 minutes**

Force encryption of existing unencrypted secrets using kubectl replace.

1. **Re-encrypt existing secrets**:
   - Use `kubectl get secrets --all-namespaces -o json | kubectl replace -f -`
   - Verify that **test-secret-before** is now encrypted in etcd
   - Confirm all secrets are properly encrypted

2. **Validate encryption coverage**:
   - Check system secrets in kube-system namespace
   - Ensure service account tokens are encrypted
   - Verify no plaintext secrets remain in etcd

**Hint**: The replace command re-writes all secrets through the API server, triggering encryption.

### Task 6: Implement Key Rotation
**Time: 4 minutes**

Demonstrate encryption key rotation procedures for security compliance.

1. **Add new encryption key**:
   - Generate a new AES-CBC key
   - Update encryption-config.yaml with new key as first provider
   - Keep old key as second provider for decryption

2. **Apply key rotation**:
   - Restart kube-apiserver with updated configuration
   - Force re-encryption of all secrets with new key
   - Remove old key from configuration after verification

**Hint**: Always keep the old key available during rotation to decrypt existing data.

## Verification Commands

### Task 1 Verification:
```bash
# Verify cluster status
kubectl get nodes
kubectl get pods -A

# Verify etcdctl installation
etcdctl version

# Check test secret creation
kubectl get secret test-secret-before -o yaml
```

### Task 2 Verification:
```bash
# Verify encryption config file
cat /etc/kubernetes/encryption-config.yaml

# Validate YAML syntax
kubectl --dry-run=client -f /etc/kubernetes/encryption-config.yaml validate
```

### Task 3 Verification:
```bash
# Check API server configuration
grep encryption-provider-config /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify API server is running
kubectl get pods -n kube-system | grep kube-apiserver

# Check encryption status in logs
journalctl -u kubelet | grep -i encryption
```

### Task 4 Verification:
```bash
# List etcd keys
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/test-secret-before

# Check for encryption prefix
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/test-secret-after
```

**Expected Output**: 
- `test-secret-before`: Raw JSON data visible (unencrypted)
- `test-secret-after`: Binary data with `k8s:enc:aescbc:v1:` prefix (encrypted)

### Task 5 Verification:
```bash
# Verify all secrets are encrypted
kubectl get secrets --all-namespaces --no-headers | wc -l

# Check specific secret encryption
ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/test-secret-before
```

**Expected Output**: All secrets should show encryption prefix in etcd.

### Task 6 Verification:
```bash
# Verify new encryption key is active
grep -A 5 "aescbc:" /etc/kubernetes/encryption-config.yaml

# Test secret decryption works
kubectl get secret test-secret-before -o jsonpath='{.data.password}' | base64 -d
```

**Expected Output**: Secret should decrypt properly with new key, showing `secretpassword`.

## Expected Results

After completing all tasks, you should have:

1. **Functioning kubeadm cluster** with etcd encryption enabled
2. **EncryptionConfiguration** with multiple providers (aescbc, aes-gcm, identity)
3. **Encrypted etcd storage** for secrets and ConfigMaps
4. **Verification method** to distinguish encrypted vs unencrypted data
5. **Key rotation procedure** implemented and tested
6. **All existing secrets** re-encrypted with current key

## Key Learning Points

- **etcd encryption at rest** protects sensitive data in cluster storage
- **EncryptionConfiguration** supports multiple encryption providers with priority order
- **kube-apiserver restart** is required to apply encryption configuration changes
- **Existing data** must be manually re-encrypted after enabling encryption
- **Key rotation** requires careful sequencing to avoid data loss
- **Direct etcd access** is necessary for encryption verification and troubleshooting

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **Practice encryption configuration** syntax and provider ordering
- **Memorize etcdctl commands** for certificate-based authentication
- **Know the API server restart process** for static pod manifests
- **Understand key rotation workflow** and the importance of keeping old keys during transition
- **Be familiar with encryption verification** using etcd direct access

### Troubleshooting Tips:
- **API server won't start**: Verify encryption config file syntax and path
- **Encryption not working**: Check provider configuration and key format
- **etcdctl access denied**: Verify certificate paths and ETCD_API version
- **Secrets not encrypting**: Ensure encryption is enabled for secrets resource type
- **Key rotation failed**: Always keep previous keys available during rotation
- **Performance issues**: Consider using AES-GCM for better performance over AES-CBC