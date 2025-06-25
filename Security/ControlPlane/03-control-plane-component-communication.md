# Control Plane Component Communication

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Understand and secure communication between Kubernetes control plane components using TLS certificates, authentication, and proper network configuration.

## Context
As a senior Kubernetes administrator for SecureBank, you've been tasked with hardening the control plane communication security. The compliance team has identified that all control plane components must use secure TLS communication with proper certificate validation. You need to examine the current configuration, validate certificate chains, and implement security improvements to meet SOC 2 compliance requirements.

## Prerequisites
- Access to a kubeadm-managed Kubernetes cluster with root privileges
- Understanding of TLS/SSL certificate concepts
- Basic knowledge of Kubernetes control plane architecture
- Familiarity with kubeadm certificate management

## Tasks

### Task 1: Initial Cluster Setup and Component Analysis
**Time**: 8 minutes

Create a fresh kubeadm cluster and analyze the current control plane component communication configuration.

**Step 1a**: Initialize a new kubeadm cluster with specific networking configuration:
```bash
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -i)
```

**Step 1b**: Configure kubectl access for the root user:
```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

**Step 1c**: Install a CNI network plugin (Flannel) to enable pod networking:
```bash
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

**Step 1d**: Examine the static pod manifests for all control plane components:
- Review `/etc/kubernetes/manifests/kube-apiserver.yaml`
- Review `/etc/kubernetes/manifests/kube-controller-manager.yaml`
- Review `/etc/kubernetes/manifests/kube-scheduler.yaml`
- Review `/etc/kubernetes/manifests/etcd.yaml`

Document the TLS-related configuration parameters in each manifest.

### Task 2: API Server Certificate Configuration Analysis
**Time**: 10 minutes

Analyze the API server's TLS certificate configuration and validate certificate chains.

**Step 2a**: Create a comprehensive certificate analysis script:
```bash
#!/bin/bash
# Certificate Analysis Script
CERT_DIR="/etc/kubernetes/pki"

echo "=== API Server Certificate Analysis ==="
echo "Server Certificate:"
openssl x509 -in $CERT_DIR/apiserver.crt -text -noout | grep -A 2 "Subject:\|Issuer:\|Not Before:\|Not After:\|DNS:\|IP:"

echo -e "\n=== Certificate Chain Validation ==="
openssl verify -CAfile $CERT_DIR/ca.crt $CERT_DIR/apiserver.crt

echo -e "\n=== Client Certificate for etcd ==="
openssl x509 -in $CERT_DIR/apiserver-etcd-client.crt -text -noout | grep -A 2 "Subject:\|Issuer:"

echo -e "\n=== Kubelet Client Certificate ==="
openssl x509 -in $CERT_DIR/apiserver-kubelet-client.crt -text -noout | grep -A 2 "Subject:\|Issuer:"
```

**Step 2b**: Execute the certificate analysis script and document the certificate purposes, validity periods, and Subject Alternative Names (SANs).

**Step 2c**: Test API server TLS connectivity using openssl:
```bash
openssl s_client -connect localhost:6443 -servername kubernetes -cert /etc/kubernetes/pki/apiserver-kubelet-client.crt -key /etc/kubernetes/pki/apiserver-kubelet-client.key -CAfile /etc/kubernetes/pki/ca.crt
```

### Task 3: etcd Communication Security Validation
**Time**: 8 minutes

Examine and validate the secure communication between API server and etcd.

**Step 3a**: Analyze etcd certificate configuration:
```bash
#!/bin/bash
ETCD_CERT_DIR="/etc/kubernetes/pki/etcd"

echo "=== etcd Server Certificate ==="
openssl x509 -in $ETCD_CERT_DIR/server.crt -text -noout | grep -A 2 "Subject:\|Issuer:\|DNS:\|IP:"

echo -e "\n=== etcd Peer Certificate ==="
openssl x509 -in $ETCD_CERT_DIR/peer.crt -text -noout | grep -A 2 "Subject:\|Issuer:"

echo -e "\n=== etcd Certificate Chain Validation ==="
openssl verify -CAfile $ETCD_CERT_DIR/ca.crt $ETCD_CERT_DIR/server.crt
openssl verify -CAfile $ETCD_CERT_DIR/ca.crt $ETCD_CERT_DIR/peer.crt
```

**Step 3b**: Test etcd TLS connectivity using etcdctl:
```bash
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  endpoint health
```

**Step 3c**: Verify that etcd is only listening on secure ports by checking the process and network bindings.

### Task 4: Controller Manager and Scheduler Authentication
**Time**: 7 minutes

Examine the authentication mechanisms used by controller manager and scheduler to communicate with the API server.

**Step 4a**: Analyze the controller manager's kubeconfig file:
```bash
cat /etc/kubernetes/controller-manager.conf
```

**Step 4b**: Examine the certificate used by the controller manager:
```bash
# Extract the client certificate data from kubeconfig
grep client-certificate-data /etc/kubernetes/controller-manager.conf | cut -d' ' -f6 | base64 -d > /tmp/controller-manager-client.crt

# Analyze the certificate
openssl x509 -in /tmp/controller-manager-client.crt -text -noout | grep -A 2 "Subject:\|Issuer:"
```

**Step 4c**: Perform the same analysis for the scheduler:
```bash
# Extract and analyze scheduler certificate
grep client-certificate-data /etc/kubernetes/scheduler.conf | cut -d' ' -f6 | base64 -d > /tmp/scheduler-client.crt
openssl x509 -in /tmp/scheduler-client.crt -text -noout | grep -A 2 "Subject:\|Issuer:"
```

**Step 4d**: Verify that both components can successfully authenticate with the API server by checking their system ClusterRoleBindings.

### Task 5: Kubelet API Server Communication
**Time**: 7 minutes

Configure and validate secure communication between the kubelet and API server.

**Step 5a**: Examine the kubelet configuration file:
```bash
cat /var/lib/kubelet/config.yaml
```

**Step 5b**: Check the kubelet's kubeconfig file:
```bash
cat /etc/kubernetes/kubelet.conf
```

**Step 5c**: Test the kubelet's TLS server certificate:
```bash
# Get the kubelet's serving certificate
openssl s_client -connect $(hostname -i):10250 -servername $(hostname) -cert /etc/kubernetes/pki/apiserver-kubelet-client.crt -key /etc/kubernetes/pki/apiserver-kubelet-client.key -CAfile /var/lib/kubelet/pki/kubelet-ca.crt
```

**Step 5d**: Verify that the API server can successfully connect to the kubelet by checking node status and retrieving kubelet metrics.

### Task 6: Network Security and Firewall Configuration
**Time**: 5 minutes

Implement network security measures and validate control plane network isolation.

**Step 6a**: Document the current network ports used by each control plane component:
- API server: 6443 (secure), 8080 (insecure - should be disabled)
- etcd: 2379 (client), 2380 (peer)
- Controller manager: 10257 (secure metrics), 10252 (insecure - should be disabled)
- Scheduler: 10259 (secure metrics), 10251 (insecure - should be disabled)
- Kubelet: 10250 (API), 10255 (read-only - should be disabled)

**Step 6b**: Verify that insecure ports are disabled by checking process arguments and attempting connections.

**Step 6c**: Create a network security validation script:
```bash
#!/bin/bash
echo "=== Control Plane Network Security Validation ==="

# Check if insecure ports are disabled
echo "Checking for insecure port configurations..."
if ps aux | grep kube-apiserver | grep -q -- "--insecure-port=0"; then
    echo "✓ API server insecure port is disabled"
else
    echo "✗ API server insecure port may be enabled"
fi

# Test secure port connectivity
echo "Testing secure port connectivity..."
nc -zv localhost 6443 && echo "✓ API server secure port is accessible"
nc -zv localhost 2379 && echo "✓ etcd client port is accessible"
nc -zv localhost 10250 && echo "✓ kubelet API port is accessible"
```

## Verification Commands

### Task 1 Verification
```bash
# Verify cluster initialization
kubectl cluster-info
kubectl get nodes -o wide

# Verify static pod manifests exist
ls -la /etc/kubernetes/manifests/

# Check control plane pods are running
kubectl get pods -n kube-system | grep -E "(kube-apiserver|kube-controller-manager|kube-scheduler|etcd)"
```

**Expected Output**: Cluster should be initialized successfully with all control plane pods in Running status.

### Task 2 Verification
```bash
# Verify API server certificate validity
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 2 "Not After"

# Verify certificate chain
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt

# Test TLS connectivity
echo "Q" | openssl s_client -connect localhost:6443 -servername kubernetes 2>/dev/null | grep "Verify return code"
```

**Expected Output**: Certificates should be valid with successful chain verification and TLS connectivity returning "Verify return code: 0 (ok)".

### Task 3 Verification
```bash
# Verify etcd health via secure connection
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  endpoint health

# Verify etcd is only listening on secure ports
netstat -tlnp | grep :2379
```

**Expected Output**: etcd should report healthy status and only listen on secure ports with TLS enabled.

### Task 4 Verification
```bash
# Verify controller manager authentication
kubectl auth can-i "*" "*" --as=system:kube-controller-manager

# Verify scheduler authentication  
kubectl auth can-i "*" "*" --as=system:kube-scheduler

# Check system ClusterRoleBindings
kubectl get clusterrolebindings | grep -E "(system:kube-controller-manager|system:kube-scheduler)"
```

**Expected Output**: Both components should have appropriate permissions and valid ClusterRoleBindings.

### Task 5 Verification
```bash
# Verify kubelet certificate rotation is enabled
grep -i rotatecert /var/lib/kubelet/config.yaml

# Test kubelet metrics endpoint (requires authentication)
curl -k --cert /etc/kubernetes/pki/apiserver-kubelet-client.crt --key /etc/kubernetes/pki/apiserver-kubelet-client.key https://$(hostname -i):10250/metrics | head -5

# Verify node status
kubectl get nodes -o json | jq '.items[0].status.conditions[] | select(.type=="Ready")'
```

**Expected Output**: Certificate rotation should be enabled, metrics endpoint should be accessible with proper authentication, and node should be in Ready status.

### Task 6 Verification
```bash
# Verify insecure ports are disabled
ss -tlnp | grep -E ":8080|:10252|:10251|:10255"

# Verify secure ports are accessible
nc -zv localhost 6443 && echo "API server secure port OK"
nc -zv localhost 2379 && echo "etcd client port OK"
nc -zv localhost 10250 && echo "kubelet API port OK"

# Check TLS cipher suites
nmap --script ssl-enum-ciphers -p 6443 localhost
```

**Expected Output**: No insecure ports should be listening, secure ports should be accessible, and only strong TLS cipher suites should be enabled.

## Expected Results

After completing this scenario, you should have:

1. **Secure Control Plane Communication**: All control plane components communicating via TLS with proper certificate validation
2. **Certificate Chain Validation**: Complete understanding of certificate hierarchies and trust relationships
3. **Authentication Mechanisms**: Proper client certificate authentication for all control plane components
4. **Network Security**: Disabled insecure ports and validated secure network communication
5. **Monitoring Capabilities**: Ability to verify and monitor control plane communication security
6. **Compliance Documentation**: Comprehensive analysis of security configurations for compliance reporting

## Key Learning Points

- **TLS Certificate Management**: Understanding certificate purposes, validity periods, and Subject Alternative Names in Kubernetes
- **Component Authentication**: How each control plane component authenticates with the API server using client certificates
- **Network Security**: Importance of disabling insecure ports and validating secure communication channels
- **Certificate Chain Validation**: Techniques for verifying certificate trust chains and detecting potential security issues
- **Monitoring and Compliance**: Methods for continuously validating control plane security configuration
- **kubeadm Certificate Lifecycle**: Understanding how kubeadm manages certificates and their rotation

## Exam & Troubleshooting Tips

**Real Exam Tips**:
- Know the default certificate locations: `/etc/kubernetes/pki/` for most certificates, `/etc/kubernetes/pki/etcd/` for etcd-specific certificates
- Understand the relationship between different certificate types: server certificates, client certificates, and CA certificates
- Be familiar with kubeadm certificate management commands: `kubeadm certs check-expiration`, `kubeadm certs renew`
- Know how to validate certificate chains using openssl commands
- Understand the security implications of insecure ports and how to verify they're disabled

**Troubleshooting Tips**:
- **Certificate Expiration**: Use `kubeadm certs check-expiration` to check all certificate validity periods
- **TLS Handshake Failures**: Verify certificate Subject Alternative Names match the connection hostname/IP
- **Component Authentication Issues**: Check kubeconfig files and ensure client certificates are valid and properly configured
- **Network Connectivity Problems**: Verify firewall rules and ensure secure ports are accessible while insecure ports are disabled
- **Certificate Chain Issues**: Use `openssl verify` to validate certificate chains and identify trust relationship problems
- **etcd Communication Failures**: Ensure API server has proper client certificates for etcd authentication and that etcd is listening on secure ports only