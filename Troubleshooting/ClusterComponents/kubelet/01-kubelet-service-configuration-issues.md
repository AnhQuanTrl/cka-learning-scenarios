# kubelet Service and Configuration Issues

## Scenario Overview
- **Time Limit**: 30 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Diagnose and resolve kubelet service failures, configuration problems, and container runtime connectivity issues that prevent nodes from joining the cluster or cause pod scheduling failures.

## Context
You're the site reliability engineer for a financial services company that's experiencing critical infrastructure issues. The development team is reporting that their application deployments are failing, and monitoring alerts indicate that several worker nodes have dropped out of the cluster with "NotReady" status. Additionally, new pods aren't starting on the remaining nodes, and container runtime errors are appearing in the logs. The incident is affecting customer-facing services, so you need to quickly identify and resolve these kubelet-related issues to restore cluster functionality.

## Prerequisites
- Killercoda Ubuntu Playground environment (or similar kubeadm cluster with worker nodes)
- Root access to both control plane and worker nodes
- Understanding of kubelet service management and configuration
- Familiarity with systemd service troubleshooting
- Knowledge of container runtime (containerd/Docker) integration

## Tasks

### Task 1: Deploy Test Workloads and Break kubelet Service (8 minutes)
Create test applications to verify cluster functionality, then simulate kubelet service failures by stopping the kubelet service on worker nodes.

Step 1a: Create test workloads to demonstrate normal cluster operations:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment-api
        image: nginx:1.21
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        env:
        - name: SERVICE_TYPE
          value: "payment-processing"
---
apiVersion: v1
kind: Service
metadata:
  name: payment-service
spec:
  selector:
    app: payment-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Step 1b: Create a DaemonSet to test kubelet functionality across all nodes:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      containers:
      - name: monitor
        image: busybox:1.35
        command: ["sh", "-c", "while true; do echo 'Node monitoring active on' $(hostname); sleep 30; done"]
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      hostNetwork: true
      hostPID: true
```

Step 1c: Stop the kubelet service on worker nodes to simulate service failure:
```bash
# On worker node(s), stop kubelet service
sudo systemctl stop kubelet

# Verify kubelet service is stopped
sudo systemctl status kubelet
```

Step 1d: Create additional workload to test scheduling behavior with reduced node availability:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-authentication
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: user-auth
  template:
    metadata:
      labels:
        app: user-auth
    spec:
      containers:
      - name: auth-service
        image: httpd:2.4
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 150m
            memory: 256Mi
```

### Task 2: Create kubelet Configuration Issues (7 minutes)
Break kubelet configuration by modifying kubeconfig paths and container runtime endpoints to simulate common configuration failures.

Step 2a: Modify kubelet kubeconfig to point to wrong cluster endpoint. On a worker node, edit the kubelet configuration to use an invalid API server endpoint:
```bash
# Backup original kubelet kubeconfig
sudo cp /etc/kubernetes/kubelet.conf /etc/kubernetes/kubelet.conf.backup

# Modify the server endpoint to an invalid address
sudo sed -i 's/server: https:\/\/[0-9.]*:[0-9]*/server: https:\/\/192.168.999.999:6443/' /etc/kubernetes/kubelet.conf
```

Step 2b: Change kubelet configuration file path to non-existent location. Modify the kubelet service to reference a configuration file that doesn't exist:
```bash
# Backup kubelet systemd service file
sudo cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf.backup

# Modify the config file path to non-existent location
sudo sed -i 's/--config=\/var\/lib\/kubelet\/config\.yaml/--config=\/etc\/kubernetes\/invalid-kubelet-config.yaml/' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Reload systemd to pick up changes
sudo systemctl daemon-reload
```

Step 2c: Configure invalid container runtime endpoint. Modify the kubelet configuration to use a non-existent container runtime socket:
```bash
# Create an invalid kubelet config file with wrong container runtime endpoint
sudo tee /var/lib/kubelet/config.yaml.broken > /dev/null << 'EOF'
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
clusterDomain: cluster.local
clusterDNS:
- 10.96.0.10
containerRuntimeEndpoint: unix:///var/run/invalid-runtime.sock
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/pki/kubelet.crt"
tlsPrivateKeyFile: "/var/lib/kubelet/pki/kubelet.key"
EOF

# Replace the original config with the broken one
sudo mv /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.original
sudo mv /var/lib/kubelet/config.yaml.broken /var/lib/kubelet/config.yaml
```

### Task 3: Break kubelet Authentication and Network Configuration (6 minutes)
Create authentication failures and network configuration issues that prevent kubelet from communicating with the API server and container runtime.

Step 3a: Modify kubelet certificate paths to point to non-existent files:
```bash
# Create invalid certificate paths in kubelet config
sudo sed -i 's/tlsCertFile: "\/var\/lib\/kubelet\/pki\/kubelet\.crt"/tlsCertFile: "\/etc\/kubernetes\/invalid-kubelet.crt"/' /var/lib/kubelet/config.yaml
sudo sed -i 's/tlsPrivateKeyFile: "\/var\/lib\/kubelet\/pki\/kubelet\.key"/tlsPrivateKeyFile: "\/etc\/kubernetes\/invalid-kubelet.key"/' /var/lib/kubelet/config.yaml
```

Step 3b: Configure wrong cluster DNS settings that will cause DNS resolution failures:
```bash
# Modify cluster DNS to invalid IP addresses
sudo sed -i 's/clusterDNS:/clusterDNS:\n- 192.168.999.10\n- 192.168.999.11\n# Original:/' /var/lib/kubelet/config.yaml
```

Step 3c: Change kubelet network plugin configuration to cause networking issues:
```bash
# Add invalid network plugin configuration
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
# Invalid network configuration
networkPluginName: "invalid-cni"
networkPluginDir: "/opt/cni/invalid"
EOF
```

### Task 4: Diagnose kubelet Service and Configuration Problems (5 minutes)
Identify the various kubelet issues through service status analysis, log examination, and configuration validation.

Step 4a: Check kubelet service status and identify service-level failures. Examine systemd service status and recent logs to understand why kubelet isn't running.

Step 4b: Analyze kubelet logs to identify configuration and authentication errors. Look for kubeconfig issues, certificate problems, and container runtime connectivity failures.

Step 4c: Validate kubelet configuration files and paths. Check if configuration files exist and contain valid syntax, and verify certificate file locations.

Step 4d: Test container runtime connectivity. Verify that the container runtime (containerd/Docker) is running and accessible through the configured socket path.

### Task 5: Restore kubelet Service and Fix Configuration Issues (4 minutes)
Systematically resolve the kubelet service and configuration problems to restore node functionality and pod scheduling.

Step 5a: Restore kubelet service and fix systemd configuration. Start the kubelet service and correct any systemd unit file issues.

Step 5b: Fix kubeconfig and authentication problems. Restore valid API server endpoints and certificate paths in the kubelet configuration.

Step 5c: Correct container runtime endpoint configuration. Update the kubelet config to use the correct container runtime socket path.

Step 5d: Restore proper DNS and network configuration. Fix cluster DNS settings and remove invalid network plugin configurations.

## Verification Commands

### Task 1 Verification:
```bash
# Verify test workloads are created
kubectl get deployments,services
kubectl get daemonset -n kube-system node-monitor

# Check node status - should show worker nodes as NotReady
kubectl get nodes
kubectl describe nodes | grep -A 5 "Ready.*False"

# Verify kubelet service is stopped on worker nodes
ssh worker-node "sudo systemctl status kubelet"
```
**Expected Output**: Deployments created but pods may be pending, DaemonSet created, worker nodes showing "NotReady" status, kubelet service inactive/failed on worker nodes.

### Task 2 Verification:
```bash
# Check kubelet service status with configuration errors
ssh worker-node "sudo systemctl status kubelet"
ssh worker-node "sudo journalctl -u kubelet --no-pager --lines=20"

# Verify invalid configuration file references
ssh worker-node "ls -la /etc/kubernetes/invalid-kubelet-config.yaml"
ssh worker-node "cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | grep config"

# Check container runtime endpoint configuration
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep containerRuntimeEndpoint"
```
**Expected Output**: kubelet failing to start, configuration file not found errors, invalid container runtime socket path in config.

### Task 3 Verification:
```bash
# Check certificate path errors in kubelet logs
ssh worker-node "sudo journalctl -u kubelet | grep -i 'certificate\|cert\|tls'"

# Verify DNS configuration issues
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep -A 3 clusterDNS"

# Check for network plugin errors
ssh worker-node "sudo journalctl -u kubelet | grep -i 'network\|cni'"
```
**Expected Output**: Certificate file not found errors, invalid DNS server IPs in config, network plugin configuration errors in logs.

### Task 4 Verification:
```bash
# Comprehensive kubelet diagnostics
ssh worker-node "sudo systemctl is-active kubelet"
ssh worker-node "sudo systemctl is-enabled kubelet"

# Container runtime status check
ssh worker-node "sudo systemctl status containerd"
ssh worker-node "sudo crictl version"

# Configuration file validation
ssh worker-node "sudo kubelet --config=/var/lib/kubelet/config.yaml --dry-run"
```
**Expected Output**: kubelet inactive, containerd should be active, crictl should work, kubelet config validation should show errors.

### Task 5 Verification:
```bash
# Verify kubelet service is running
ssh worker-node "sudo systemctl status kubelet"
kubectl get nodes

# Check that pods can be scheduled on recovered nodes
kubectl get pods -o wide
kubectl get pods -n kube-system -o wide | grep node-monitor

# Verify container runtime connectivity
ssh worker-node "sudo crictl ps"
ssh worker-node "sudo crictl images"

# Test DNS resolution from within pods
kubectl run dns-test --image=busybox:1.35 --rm -it --restart=Never -- nslookup kubernetes.default
```
**Expected Output**: kubelet running successfully, all nodes showing "Ready" status, pods distributed across nodes, container runtime accessible, DNS resolution working.

## Expected Results
- All worker nodes showing "Ready" status in `kubectl get nodes`
- kubelet service running successfully on all nodes (`systemctl status kubelet`)
- Test workloads (payment-service, user-authentication, node-monitor DaemonSet) have pods in Running state
- Pods distributed across all available nodes
- Container runtime (containerd/Docker) accessible and functional
- DNS resolution working correctly from within pods
- No authentication or certificate errors in kubelet logs

## Key Learning Points
- **kubelet Service Management**: Understanding systemd service management and troubleshooting for kubelet
- **Configuration Troubleshooting**: Diagnosing kubelet configuration file issues and path problems
- **Container Runtime Integration**: Troubleshooting kubelet-to-container runtime communication
- **Authentication Debugging**: Resolving certificate and kubeconfig authentication failures
- **Network Configuration**: Fixing DNS and CNI plugin configuration issues in kubelet
- **Node Health Management**: Understanding how kubelet health affects node readiness and pod scheduling

## Exam & Troubleshooting Tips
- **Real Exam Tips**:
  - Always check node status first when pods aren't scheduling: `kubectl get nodes`
  - Use `systemctl status kubelet` and `journalctl -u kubelet` for service-level diagnostics
  - Verify container runtime is running before troubleshooting kubelet issues
  - Check `/var/lib/kubelet/config.yaml` for configuration problems
- **Troubleshooting Tips**:
  - **Service Issues**: Use `systemctl` commands to manage and diagnose kubelet service
  - **Configuration Problems**: Validate kubelet config with `kubelet --config=<file> --dry-run`
  - **Certificate Issues**: Check certificate paths and permissions in kubelet config
  - **Container Runtime**: Verify containerd/Docker socket accessibility with `crictl`
  - **DNS Problems**: Test cluster DNS from within pods using `nslookup` or `dig`
  - **Network Issues**: Check CNI plugin installation and configuration in `/opt/cni/bin/`
  - **Recovery Strategy**: Always backup original configuration files before making changes
  - **Node Readiness**: Monitor kubelet logs for "node ready" status changes during recovery