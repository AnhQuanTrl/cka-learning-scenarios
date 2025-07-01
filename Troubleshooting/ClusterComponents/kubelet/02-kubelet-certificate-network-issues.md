# kubelet Certificate and Network Issues

## Scenario Overview
- **Time Limit**: 28 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Diagnose and resolve kubelet certificate authentication failures, network connectivity problems, and DNS configuration issues that prevent nodes from properly communicating with the API server and affect pod networking functionality.

## Context
You're the infrastructure engineer for a cloud-native startup that's experiencing critical network and authentication issues across their Kubernetes cluster. The monitoring team has reported that several worker nodes are intermittently failing authentication with the API server, causing pods to lose connectivity and DNS resolution to fail. The development team is unable to deploy new applications, and existing services are experiencing connectivity issues. Customer support is receiving complaints about application timeouts and service unavailability. You need to quickly identify and resolve these certificate and network-related kubelet issues to restore cluster stability and service availability.

## Prerequisites
- Killercoda Ubuntu Playground environment (or similar kubeadm cluster with worker nodes)
- Root access to both control plane and worker nodes
- Understanding of kubelet certificate management and network configuration
- Familiarity with DNS troubleshooting and CNI plugins
- Knowledge of certificate validation and OpenSSL commands

## Tasks

### Task 1: Deploy Network-Dependent Applications and Break kubelet Certificates (8 minutes)
Create applications that depend on network connectivity and DNS resolution, then simulate certificate authentication failures by using expired certificates in kubelet configuration.

Step 1a: Create a multi-tier application that requires network connectivity and DNS resolution:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: BACKEND_URL
          value: "http://backend-service:8080"
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: config
        configMap:
          name: frontend-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  default.conf: |
    server {
        listen 80;
        location / {
            proxy_pass http://backend-service:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        location /health {
            return 200 'healthy';
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Step 1b: Create a backend service that performs DNS lookups and API calls:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: httpd:2.4
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          value: "postgres://database-service:5432/app"
        - name: KUBERNETES_SERVICE_HOST
          value: "kubernetes.default.svc.cluster.local"
        resources:
          requests:
            cpu: 150m
            memory: 256Mi
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
```

Step 1c: Create a DNS debugging pod and simulate certificate authentication failure by using expired certificates in kubelet kubeconfig:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-debug
  namespace: default
spec:
  containers:
  - name: dns-tools
    image: busybox:1.35
    command: ["sh", "-c", "while true; do nslookup kubernetes.default.svc.cluster.local; sleep 60; done"]
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
```

Step 1d: Break kubelet certificate authentication by creating expired certificates:
```bash
# On worker node, backup original kubelet kubeconfig
sudo cp /etc/kubernetes/kubelet.conf /etc/kubernetes/kubelet.conf.backup

# Create an expired certificate for kubelet
openssl req -new -key /var/lib/kubelet/pki/kubelet.key -out /tmp/kubelet-expired.csr -subj "/CN=system:node:$(hostname)/O=system:nodes"
openssl x509 -req -in /tmp/kubelet-expired.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -out /tmp/kubelet-expired.crt -days -1 -CAcreateserial

# Replace the certificate data in kubelet kubeconfig
base64 -w 0 /tmp/kubelet-expired.crt > /tmp/kubelet-expired-b64.txt
```

### Task 2: Break kubelet Client Certificate Paths and Configuration (6 minutes)
Create certificate path and configuration issues that prevent kubelet from authenticating with the API server.

Step 2a: Modify kubelet client certificate paths to point to non-existent files. Edit the kubelet configuration to reference invalid certificate locations:
```bash
# Backup original kubelet config
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.backup

# Create invalid certificate paths in kubelet config
sudo sed -i 's|clientCAFile: /etc/kubernetes/pki/ca.crt|clientCAFile: /etc/kubernetes/pki/invalid-ca.crt|' /var/lib/kubelet/config.yaml
sudo sed -i 's|tlsCertFile: /var/lib/kubelet/pki/kubelet.crt|tlsCertFile: /var/lib/kubelet/pki/invalid-kubelet.crt|' /var/lib/kubelet/config.yaml
sudo sed -i 's|tlsPrivateKeyFile: /var/lib/kubelet/pki/kubelet.key|tlsPrivateKeyFile: /var/lib/kubelet/pki/invalid-kubelet.key|' /var/lib/kubelet/config.yaml
```

Step 2b: Create certificate permission issues by changing file permissions:
```bash
# Change certificate file permissions to prevent access
sudo chmod 000 /var/lib/kubelet/pki/kubelet.crt
sudo chmod 000 /var/lib/kubelet/pki/kubelet.key
```

Step 2c: Modify the kubelet kubeconfig to use the expired certificate by updating the client-certificate-data field with the content from `/tmp/kubelet-expired-b64.txt`.

### Task 3: Break kubelet DNS and Network Configuration (7 minutes)
Create DNS and network configuration problems that affect pod connectivity and service discovery.

Step 3a: Configure wrong cluster DNS settings in kubelet configuration:
```bash
# Replace cluster DNS with invalid IP addresses
sudo sed -i 's/clusterDNS:/clusterDNS:\n- 192.168.999.10\n- 10.96.0.254\n# Original DNS:/' /var/lib/kubelet/config.yaml
sudo sed -i '/^clusterDNS:$/,/^[^ ]/ s/^- 10\.96\.0\.10$/# - 10.96.0.10/' /var/lib/kubelet/config.yaml
```

Step 3b: Change kubelet network plugin configuration to create networking issues:
```bash
# Add invalid CNI configuration to kubelet config
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
# Network plugin configuration
hairpinMode: hairpin-veth
networkPluginName: "broken-cni"
networkPluginDir: "/opt/cni/invalid"
cniCacheDir: "/var/lib/cni/invalid"
EOF
```

Step 3c: Break the CNI plugin configuration by modifying CNI config files:
```bash
# Backup original CNI configuration
sudo cp /etc/cni/net.d/10-containerd-net.conflist /etc/cni/net.d/10-containerd-net.conflist.backup

# Create invalid CNI configuration with wrong subnet
sudo tee /etc/cni/net.d/10-containerd-net.conflist > /dev/null << 'EOF'
{
  "cniVersion": "0.4.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.999.0/24",
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
EOF
```

### Task 4: Diagnose Certificate and Network Issues (4 minutes)
Identify certificate authentication failures and network configuration problems through log analysis and certificate validation.

Step 4a: Analyze kubelet logs for certificate authentication errors. Examine kubelet service logs to identify certificate validation failures and authentication issues with the API server.

Step 4b: Validate certificate paths and permissions. Check if certificate files exist, have proper permissions, and contain valid certificate data.

Step 4c: Test DNS resolution from within pods. Use the dns-debug pod to test DNS resolution and identify DNS configuration problems.

Step 4d: Examine CNI plugin configuration and network connectivity. Verify CNI plugin installation and configuration for network-related issues.

### Task 5: Restore Certificate Authentication and Network Configuration (3 minutes)
Systematically fix certificate authentication problems and network configuration issues to restore kubelet functionality.

Step 5a: Restore valid certificate paths and permissions. Fix certificate file paths in kubelet configuration and restore proper file permissions.

Step 5b: Fix DNS configuration in kubelet. Restore correct cluster DNS settings and remove invalid network plugin configurations.

Step 5c: Repair CNI plugin configuration. Restore valid CNI configuration with proper network subnet and plugin settings.

Step 5d: Restart kubelet service to apply all configuration changes and verify node and pod connectivity.

## Verification Commands

### Task 1 Verification:
```bash
# Verify applications are deployed
kubectl get deployments,services,pods
kubectl get configmap frontend-config

# Check kubelet certificate authentication errors
ssh worker-node "sudo journalctl -u kubelet --no-pager --lines=20 | grep -i 'certificate\|auth\|tls'"

# Verify DNS debugging pod
kubectl logs dns-debug --tail=5
```
**Expected Output**: Applications deployed but may have connectivity issues, certificate validation errors in kubelet logs, DNS resolution failures in debug pod logs.

### Task 2 Verification:
```bash
# Check certificate file paths and permissions
ssh worker-node "ls -la /var/lib/kubelet/pki/kubelet.crt /var/lib/kubelet/pki/kubelet.key"
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep -A 3 -B 3 'CAFile\|tlsCert\|tlsPrivate'"

# Verify certificate validation errors
ssh worker-node "sudo journalctl -u kubelet | grep -i 'certificate.*not found\|permission denied\|invalid certificate'"

# Test certificate expiration
openssl x509 -in /tmp/kubelet-expired.crt -text -noout | grep -A 2 "Validity"
```
**Expected Output**: Certificate files with no permissions (000), invalid certificate paths in config, certificate not found errors in logs, expired certificate confirmation.

### Task 3 Verification:
```bash
# Check DNS configuration in kubelet
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep -A 5 clusterDNS"

# Verify CNI configuration issues
ssh worker-node "sudo cat /etc/cni/net.d/10-containerd-net.conflist | grep subnet"
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep -A 5 networkPlugin"

# Test pod DNS resolution
kubectl exec dns-debug -- nslookup kubernetes.default.svc.cluster.local
```
**Expected Output**: Invalid DNS IPs in kubelet config, wrong subnet in CNI config, DNS resolution failures from within pods.

### Task 4 Verification:
```bash
# Comprehensive certificate diagnostics
ssh worker-node "sudo systemctl status kubelet"
ssh worker-node "openssl x509 -in /var/lib/kubelet/pki/kubelet.crt -text -noout | grep -A 2 'Validity\|Subject'"

# Network connectivity testing
kubectl get nodes -o wide
kubectl get pods -o wide
kubectl exec frontend-app-<pod-name> -- wget -qO- http://backend-service:8080 --timeout=5

# CNI plugin verification
ssh worker-node "ls -la /opt/cni/bin/"
ssh worker-node "sudo crictl ps | grep -E 'frontend|backend'"
```
**Expected Output**: kubelet service issues, invalid/expired certificates, network connectivity failures between pods, CNI plugin present but config invalid.

### Task 5 Verification:
```bash
# Verify certificate authentication is working
ssh worker-node "sudo systemctl status kubelet"
kubectl get nodes

# Test DNS resolution functionality
kubectl exec dns-debug -- nslookup kubernetes.default.svc.cluster.local
kubectl exec dns-debug -- nslookup backend-service.default.svc.cluster.local

# Verify pod networking and connectivity
kubectl get pods -o wide
kubectl exec frontend-app-<pod-name> -- wget -qO- http://backend-service:8080 --timeout=5

# Check CNI and network configuration
ssh worker-node "sudo cat /etc/cni/net.d/10-containerd-net.conflist | grep subnet"
kubectl exec dns-debug -- ping backend-service
```
**Expected Output**: kubelet service running, all nodes Ready, DNS resolution working, pod-to-pod connectivity restored, valid CNI configuration.

## Expected Results
- All nodes showing "Ready" status in `kubectl get nodes`
- kubelet service running successfully with no authentication errors
- DNS resolution working correctly from within pods
- Pod-to-pod and pod-to-service connectivity restored
- Frontend application able to reach backend service
- Valid certificate paths and permissions in kubelet configuration
- Proper CNI plugin configuration with correct network subnet
- No certificate validation or network plugin errors in kubelet logs

## Key Learning Points
- **Certificate Authentication**: Understanding kubelet certificate management and validation
- **Network Configuration**: Configuring kubelet DNS and CNI plugin settings
- **DNS Troubleshooting**: Diagnosing and fixing DNS resolution issues in pods
- **Certificate Validation**: Using OpenSSL to inspect and validate certificates
- **CNI Plugin Management**: Understanding CNI configuration and network plugin integration
- **Network Connectivity**: Troubleshooting pod-to-pod and service connectivity issues

## Exam & Troubleshooting Tips
- **Real Exam Tips**:
  - Always check node status and kubelet logs when authentication issues occur
  - Use `kubectl exec` to test DNS resolution from within pods
  - Verify certificate paths and permissions when kubelet fails to authenticate
  - Check CNI plugin configuration when pod networking fails
- **Troubleshooting Tips**:
  - **Certificate Issues**: Use `openssl x509 -text -noout -in <cert>` to inspect certificate details
  - **DNS Problems**: Test DNS resolution from within pods using `nslookup` or `dig`
  - **Network Issues**: Check CNI plugin configuration in `/etc/cni/net.d/`
  - **Permission Errors**: Verify certificate file permissions with `ls -la`
  - **Connectivity Testing**: Use `kubectl exec` to test network connectivity between pods
  - **Log Analysis**: Look for "certificate", "DNS", and "network" keywords in kubelet logs
  - **Recovery Strategy**: Always backup original configurations before making changes
  - **Validation**: Test each fix incrementally to identify which issues have been resolved