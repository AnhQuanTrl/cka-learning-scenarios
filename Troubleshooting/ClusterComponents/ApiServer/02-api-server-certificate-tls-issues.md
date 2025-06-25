# API Server Certificate and TLS Issues

## Scenario Overview
- **Time Limit**: 50 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda kubeadm cluster

## Objective
Master API server certificate and TLS troubleshooting by systematically breaking and recovering from common certificate-related failures that cause complete cluster authentication breakdown.

## Context
You're the senior platform engineer when the security team reports that the Kubernetes cluster is completely inaccessible after a failed certificate rotation procedure. The junior engineer attempted to update expiring certificates but made several configuration errors, causing the API server to reject all authentication attempts. Critical production workloads are running, but no administrative access is possible. You must quickly identify and resolve the certificate issues to restore cluster access before the incident escalates.

## Prerequisites
- Running Killercoda kubeadm cluster with full control plane access
- Understanding of PKI infrastructure and X.509 certificates
- Familiarity with openssl commands for certificate inspection
- Knowledge of Kubernetes certificate authentication flow
- SSH access to control plane node

## Tasks

### Task 1: Establish Baseline and Certificate Inventory (8 minutes)
Create a comprehensive certificate baseline before introducing failures.

1a. Verify cluster health and document current certificate status:
```bash
kubectl get nodes
kubectl get pods -A | grep -E "(api|etcd|controller|scheduler)"
```

1b. Examine the API server certificate configuration and paths:
```bash
sudo grep -E "(tls-cert-file|tls-private-key-file|client-ca-file)" /etc/kubernetes/manifests/kube-apiserver.yaml
```

1c. Validate current API server certificate with openssl:
```bash
# Extract certificate details
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After|DNS:|IP Address)"

# Verify certificate chain
sudo openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt
```

1d. Test current TLS connectivity to API server:
```bash
# Test TLS handshake
openssl s_client -connect localhost:6443 -servername kubernetes -cert /etc/kubernetes/pki/apiserver-kubelet-client.crt -key /etc/kubernetes/pki/apiserver-kubelet-client.key -CAfile /etc/kubernetes/pki/ca.crt < /dev/null

# Verify kubectl authentication works
kubectl auth whoami
kubectl get componentstatuses
```

1e. Create backups of critical certificate files:
```bash
sudo mkdir -p /tmp/cert-backup
sudo cp -r /etc/kubernetes/pki/ /tmp/cert-backup/
sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/cert-backup/
```

1f. Deploy a test application to validate cluster functionality:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cert-test-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cert-test
  template:
    metadata:
      labels:
        app: cert-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```

### Task 2: Break 1 - Expired API Server Certificate (12 minutes)
Simulate certificate expiration by replacing with an expired certificate.

2a. Generate an expired certificate for testing:
```bash
# Create expired certificate (valid for 1 second in the past)
sudo openssl req -x509 -newkey rsa:2048 -keyout /tmp/expired-apiserver.key -out /tmp/expired-apiserver.crt -days -1 -nodes -subj "/CN=kube-apiserver/O=system:masters" -extensions v3_req -config <(
cat <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = $(kubectl get service kubernetes -o jsonpath='{.spec.clusterIP}')
EOF
)
```

2b. Replace the API server certificate with the expired one:
```bash
sudo cp /tmp/expired-apiserver.crt /etc/kubernetes/pki/apiserver.crt
sudo cp /tmp/expired-apiserver.key /etc/kubernetes/pki/apiserver.key
```

2c. Wait for the API server to restart and observe the failure symptoms:
```bash
# Monitor API server container restart
sudo crictl ps -a | grep kube-apiserver

# Attempt kubectl operations
kubectl get nodes
kubectl cluster-info
```

2d. Analyze the certificate expiration error using openssl:
```bash
# Verify certificate is indeed expired
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -dates -noout

# Test TLS connection and observe expiration error
echo | openssl s_client -connect localhost:6443 -servername kubernetes 2>&1 | grep -E "(verify error|certificate expired)"
```

2e. Examine API server logs for certificate-related errors:
```bash
sudo journalctl -u kubelet --since "2 minutes ago" | grep -i "certificate\|tls\|x509"
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -i "certificate\|expired"
```

2f. Restore the valid certificate and verify recovery:
```bash
sudo cp /tmp/cert-backup/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt
sudo cp /tmp/cert-backup/pki/apiserver.key /etc/kubernetes/pki/apiserver.key

# Verify recovery
kubectl get nodes
kubectl get pods -l app=cert-test
```

### Task 3: Break 2 - Invalid Certificate File Paths (10 minutes)
Break the API server by pointing to non-existent certificate files.

3a. Modify the API server manifest to use invalid certificate paths:
```bash
sudo sed -i 's|/etc/kubernetes/pki/apiserver.crt|/etc/kubernetes/pki/missing-apiserver.crt|' /etc/kubernetes/manifests/kube-apiserver.yaml
sudo sed -i 's|/etc/kubernetes/pki/apiserver.key|/etc/kubernetes/pki/missing-apiserver.key|' /etc/kubernetes/manifests/kube-apiserver.yaml
```

3b. Observe the API server failure to start:
```bash
# Monitor for API server container failures
kubectl get nodes
sudo crictl ps -a | grep kube-apiserver | head -5
```

3c. Analyze the file path error in container logs:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep -E "no such file|certificate|key"
```

3d. Check kubelet logs for static pod restart attempts:
```bash
sudo journalctl -u kubelet --since "1 minute ago" | grep -E "apiserver|certificate|file"
```

3e. Verify the missing files by checking filesystem:
```bash
ls -la /etc/kubernetes/pki/missing-apiserver.*
ls -la /etc/kubernetes/pki/apiserver.*
```

3f. Restore correct certificate file paths:
```bash
sudo cp /tmp/cert-backup/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify recovery
kubectl get componentstatuses
kubectl get deployment cert-test-app
```

### Task 4: Break 3 - Incompatible TLS Cipher Suites (10 minutes)
Configure the API server with TLS cipher suites that prevent secure connections.

4a. Add restrictive TLS cipher configuration to API server:
```bash
sudo sed -i '/- kube-apiserver/a\    - --tls-cipher-suites=TLS_RSA_WITH_RC4_128_SHA' /etc/kubernetes/manifests/kube-apiserver.yaml
```

4b. Monitor API server restart and connection failures:
```bash
kubectl get nodes
sudo crictl ps | grep kube-apiserver
```

4c. Test TLS handshake and identify cipher suite mismatch:
```bash
# Test connection with detailed TLS debugging
openssl s_client -connect localhost:6443 -cipher HIGH:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!SRP:!CAMELLIA 2>&1 | grep -E "(cipher|handshake|error)"
```

4d. Examine API server logs for TLS handshake errors:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | tail -20 | grep -E "tls|handshake|cipher"
```

4e. Check kubelet's ability to communicate with API server:
```bash
sudo journalctl -u kubelet --since "2 minutes ago" | grep -E "tls|handshake|certificate"
```

4f. Remove the problematic cipher suite configuration:
```bash
sudo sed -i '/--tls-cipher-suites/d' /etc/kubernetes/manifests/kube-apiserver.yaml

# Verify API server recovery
kubectl cluster-info
kubectl get pods -A --field-selector=status.phase!=Running
```

### Task 5: Break 4 - Wrong Client CA Bundle (10 minutes)
Replace the client CA file with an invalid CA bundle.

5a. Create a fake CA certificate for testing:
```bash
# Generate a new CA that doesn't match existing certificates
openssl req -x509 -newkey rsa:2048 -keyout /tmp/fake-ca.key -out /tmp/fake-ca.crt -days 365 -nodes -subj "/CN=fake-ca"
```

5b. Replace the client CA file with the fake CA:
```bash
sudo cp /tmp/fake-ca.crt /etc/kubernetes/pki/ca.crt
```

5c. Observe authentication failures after API server restart:
```bash
# Wait for restart and test authentication
sleep 30
kubectl get nodes
kubectl auth whoami
```

5d. Analyze client certificate authentication errors:
```bash
# Check API server logs for authentication failures
sudo crictl logs $(sudo crictl ps | grep kube-apiserver | awk '{print $1}') 2>&1 | tail -20 | grep -E "authentication|certificate|unauthorized"
```

5e. Test certificate chain validation:
```bash
# Verify client certificate against wrong CA
sudo openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver-kubelet-client.crt

# Compare with original CA
sudo openssl verify -CAfile /tmp/cert-backup/pki/ca.crt /etc/kubernetes/pki/apiserver-kubelet-client.crt
```

5f. Restore the correct CA certificate:
```bash
sudo cp /tmp/cert-backup/pki/ca.crt /etc/kubernetes/pki/ca.crt

# Verify authentication is restored
kubectl get nodes
kubectl get serviceaccounts
```

5g. Test end-to-end certificate authentication:
```bash
# Verify client certificate authentication works
kubectl auth can-i get pods --as=system:admin
kubectl get deployment cert-test-app -o yaml | grep -A 5 "status:"
```

## Verification Commands

### Task 1 Verification
```bash
# Verify cluster baseline
kubectl get nodes | grep Ready | wc -l  # Should show all nodes ready
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -checkend 0  # Should return 0 (not expired)
kubectl get deployment cert-test-app -o jsonpath='{.status.readyReplicas}'  # Should equal desired replicas

# Verify certificate chain
sudo openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt  # Should show OK
echo | openssl s_client -connect localhost:6443 -CAfile /etc/kubernetes/pki/ca.crt 2>&1 | grep "Verify return code: 0"  # Should show successful verification
```

### Task 2 Verification
```bash
# Verify expired certificate symptoms
kubectl get nodes 2>&1 | grep -E "Unable to connect|certificate|expired"  # Should show connection errors during break
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -checkend 0  # Should return 1 during break (expired)

# Verify recovery
kubectl get nodes | grep Ready  # Should show ready nodes after fix
kubectl cluster-info | grep "Kubernetes control plane"  # Should show successful connection
```

### Task 3 Verification
```bash
# Verify missing file symptoms
sudo crictl logs $(sudo crictl ps -a | grep kube-apiserver | awk '{print $1}' | head -1) 2>&1 | grep "no such file\|cannot load"  # Should show file errors during break
ls -la /etc/kubernetes/pki/missing-apiserver.* 2>&1 | grep "No such file"  # Should confirm missing files

# Verify recovery
kubectl get componentstatuses | grep Healthy  # Should show healthy components after fix
sudo grep "apiserver.crt" /etc/kubernetes/manifests/kube-apiserver.yaml  # Should show correct path
```

### Task 4 Verification
```bash
# Verify cipher suite issues
openssl s_client -connect localhost:6443 -cipher ALL 2>&1 | grep -E "handshake failure\|no cipher"  # Should show handshake errors during break
sudo grep "tls-cipher-suites" /etc/kubernetes/manifests/kube-apiserver.yaml  # Should show problematic configuration during break

# Verify recovery
kubectl cluster-info | grep "running at"  # Should show API server accessible after fix
sudo grep -c "tls-cipher-suites" /etc/kubernetes/manifests/kube-apiserver.yaml  # Should be 0 after fix
```

### Task 5 Verification
```bash
# Verify CA mismatch symptoms
kubectl auth whoami 2>&1 | grep -E "Unauthorized\|certificate"  # Should show auth errors during break
sudo openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver-kubelet-client.crt  # Should fail during break

# Verify recovery
kubectl auth whoami  # Should show authenticated user after fix
kubectl auth can-i get pods  # Should return "yes" after fix
kubectl get serviceaccounts | grep default  # Should show successful API access
```

## Expected Results
- **Initial Setup**: Healthy cluster with valid certificates and successful TLS authentication
- **Break 1**: API server inaccessible due to expired certificate, TLS handshake failures
- **Break 2**: API server fails to start due to missing certificate files
- **Break 3**: TLS connection failures due to incompatible cipher suite configuration
- **Break 4**: Authentication failures due to client certificate validation against wrong CA
- **Recovery**: All certificate issues resolved with systematic troubleshooting approach
- **Final State**: Fully functional cluster with restored certificate-based authentication

## Key Learning Points
- **Certificate Lifecycle Management**: Understanding certificate expiration monitoring, rotation procedures, and emergency renewal processes
- **TLS Troubleshooting**: Mastering openssl commands for certificate validation, chain verification, and connection testing
- **API Server Authentication Flow**: Deep understanding of client certificate authentication, CA trust chains, and TLS handshake process
- **Production Certificate Operations**: Skills for diagnosing and resolving certificate issues under time pressure in critical systems
- **Security Best Practices**: Knowledge of TLS configuration, cipher suite selection, and certificate security considerations

## Exam & Troubleshooting Tips
- **CKA Exam Strategy**: Certificate issues are high-frequency exam topics; practice openssl commands and certificate path troubleshooting
- **Common Error Patterns**: Memorize typical certificate error messages (expired, chain validation, file not found) for quick identification
- **Troubleshooting Workflow**: Always verify certificate validity with openssl before investigating complex networking or authentication issues
- **Time Management**: Certificate issues can often be resolved quickly with systematic verification; don't over-complicate the analysis
- **Recovery Procedures**: Practice certificate restoration from backups; kubeadm certificate renewal commands are essential for exam success
- **Prevention Strategies**: Implement certificate expiration monitoring and automated renewal to prevent production outages