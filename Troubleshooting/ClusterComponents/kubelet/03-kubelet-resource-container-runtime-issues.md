# kubelet Resource and Container Runtime Issues

## Scenario Overview
- **Time Limit**: 26 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Diagnose and resolve kubelet container runtime connectivity failures, resource allocation conflicts, cgroup driver mismatches, and container logging configuration issues that prevent pods from starting and cause resource management problems.

## Context
You're the platform engineer for a rapidly growing e-commerce company experiencing critical infrastructure issues during peak traffic. The operations team has reported that new container deployments are failing with "container runtime not available" errors, and existing pods are being evicted due to resource conflicts. The development team cannot deploy their Black Friday sales applications, and the monitoring team has noticed that container logs are not being collected properly. Customer transactions are failing, and the business is losing revenue. You need to quickly identify and resolve these kubelet container runtime and resource management issues to restore platform stability and enable critical deployments.

## Prerequisites
- Killercoda Ubuntu Playground environment (or similar kubeadm cluster with worker nodes)
- Root access to both control plane and worker nodes
- Understanding of container runtime (containerd/Docker) management
- Familiarity with kubelet resource configuration and cgroup management
- Knowledge of container logging and crictl debugging tools

## Tasks

### Task 1: Deploy Resource-Intensive Applications and Break Container Runtime Configuration (7 minutes)
Create applications with high resource requirements, then simulate container runtime failures by configuring invalid container runtime socket paths.

Step 1a: Create a resource-intensive e-commerce application with database and caching components:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-database
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ecommerce-db
  template:
    metadata:
      labels:
        app: ecommerce-db
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: ecommerce
        - name: POSTGRES_USER
          value: app_user
        - name: POSTGRES_PASSWORD
          value: secure_password
        resources:
          requests:
            cpu: 1000m
            memory: 2Gi
          limits:
            cpu: 2000m
            memory: 4Gi
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: logs
          mountPath: /var/log/postgresql
      volumes:
      - name: data
        emptyDir: {}
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: database-service
spec:
  selector:
    app: ecommerce-db
  ports:
  - port: 5432
    targetPort: 5432
```

Step 1b: Create a high-memory caching application:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-cache
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redis-cache
  template:
    metadata:
      labels:
        app: redis-cache
    spec:
      containers:
      - name: redis
        image: redis:6.2
        args: ["redis-server", "--maxmemory", "1gb", "--maxmemory-policy", "allkeys-lru"]
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: redis-logs
          mountPath: /var/log/redis
      volumes:
      - name: redis-logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis-cache
  ports:
  - port: 6379
    targetPort: 6379
```

Step 1c: Break container runtime configuration by modifying kubelet to use invalid socket path:
```bash
# On worker node, backup kubelet configuration
sudo cp /var/lib/kubelet/config.yaml /var/lib/kubelet/config.yaml.backup

# Configure invalid container runtime endpoint
sudo sed -i 's|containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock|containerRuntimeEndpoint: unix:///var/run/invalid-runtime.sock|' /var/lib/kubelet/config.yaml
```

Step 1d: Create additional container runtime issues by corrupting the containerd configuration:
```bash
# Backup containerd configuration
sudo cp /etc/containerd/config.toml /etc/containerd/config.toml.backup

# Create invalid containerd configuration
sudo tee /etc/containerd/config.toml > /dev/null << 'EOF'
version = 2
# Broken configuration with invalid paths
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "invalid/pause:3.7"
  
[plugins."io.containerd.grpc.v1.cri".containerd]
  snapshotter = "invalid-snapshotter"
  default_runtime_name = "invalid-runtime"
  
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.invalid-runtime]
  runtime_type = "io.containerd.runtime.invalid"
EOF
```

### Task 2: Create kubelet Resource Conflicts and cgroup Driver Issues (6 minutes)
Simulate resource allocation problems and cgroup driver mismatches that prevent proper container management.

Step 2a: Configure kubelet with insufficient system resources causing allocation conflicts:
```bash
# Modify kubelet configuration with inadequate resource reservations
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
# Resource management configuration
systemReserved:
  cpu: "2000m"
  memory: "4Gi"
  ephemeral-storage: "10Gi"
kubeReserved:
  cpu: "1000m"
  memory: "2Gi"
  ephemeral-storage: "5Gi"
enforceNodeAllocatable: ["pods", "system-reserved", "kube-reserved"]
EOF
```

Step 2b: Create cgroup driver mismatch between kubelet and container runtime:
```bash
# Configure kubelet to use systemd cgroup driver while containerd uses cgroupfs
sudo sed -i '/cgroupDriver:/d' /var/lib/kubelet/config.yaml
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
cgroupDriver: systemd
EOF

# Configure containerd to use cgroupfs (creating mismatch)
sudo tee -a /etc/containerd/config.toml > /dev/null << 'EOF'

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = false
EOF
```

Step 2c: Configure eviction thresholds that are too aggressive, causing unnecessary pod evictions:
```bash
# Add aggressive eviction settings
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
evictionHard:
  memory.available: "500Mi"
  nodefs.available: "20%"
  imagefs.available: "20%"
evictionSoft:
  memory.available: "1Gi"
  nodefs.available: "25%"
evictionSoftGracePeriod:
  memory.available: "30s"
  nodefs.available: "1m"
EOF
```

### Task 3: Break Container Logging Configuration (5 minutes)
Create container logging issues by configuring read-only log paths and invalid logging drivers.

Step 3a: Configure read-only container log directory that prevents log collection:
```bash
# Change container log path to read-only location
sudo sed -i '/containerLogMaxSize:/d' /var/lib/kubelet/config.yaml
sudo sed -i '/containerLogMaxFiles:/d' /var/lib/kubelet/config.yaml
sudo tee -a /var/lib/kubelet/config.yaml > /dev/null << 'EOF'
containerLogMaxSize: "50Mi"
containerLogMaxFiles: 10
# Invalid log path
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
EOF

# Create read-only log directory
sudo mkdir -p /var/log/pods-readonly
sudo chmod 444 /var/log/pods-readonly
```

Step 3b: Break log rotation configuration and create disk space issues:
```bash
# Create large log files to simulate log rotation failures
sudo mkdir -p /var/log/containers-full
sudo dd if=/dev/zero of=/var/log/containers-full/large-log.log bs=1M count=100 2>/dev/null
sudo chmod 000 /var/log/containers-full/large-log.log
```

Step 3c: Configure invalid logging driver in containerd:
```bash
# Add invalid logging configuration to containerd
sudo tee -a /etc/containerd/config.toml > /dev/null << 'EOF'

[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."invalid-mirror.local"]
      endpoint = ["https://invalid-registry.example.com"]
EOF
```

### Task 4: Diagnose Container Runtime and Resource Issues (4 minutes)
Identify container runtime connectivity problems, resource allocation conflicts, and logging configuration issues through system analysis.

Step 4a: Analyze kubelet logs for container runtime connectivity errors. Look for socket connection failures and runtime initialization problems.

Step 4b: Use crictl commands to test container runtime connectivity and functionality. Verify if the container runtime is accessible and responding to API calls.

Step 4c: Examine resource allocation and cgroup configuration. Check system resource usage, kubelet resource reservations, and cgroup driver compatibility.

Step 4d: Investigate container logging issues and disk space problems. Verify log file permissions and storage availability for container logs.

### Task 5: Restore Container Runtime and Fix Resource Configuration (4 minutes)
Systematically resolve container runtime connectivity, resource allocation, and logging configuration problems.

Step 5a: Fix container runtime socket configuration and restore containerd settings. Correct the kubelet container runtime endpoint and containerd configuration.

Step 5b: Resolve resource allocation conflicts and cgroup driver compatibility. Update kubelet resource reservations and align cgroup drivers between kubelet and containerd.

Step 5c: Fix container logging configuration and permissions. Restore proper log directory permissions and logging configuration.

Step 5d: Restart kubelet and containerd services to apply all configuration changes and verify container operations.

## Verification Commands

### Task 1 Verification:
```bash
# Verify resource-intensive applications are created
kubectl get deployments,services
kubectl describe deployment ecommerce-database
kubectl describe deployment redis-cache

# Check kubelet container runtime errors
ssh worker-node "sudo journalctl -u kubelet --no-pager --lines=20 | grep -i 'container runtime\|runtime.*error\|socket'"

# Test container runtime connectivity
ssh worker-node "sudo crictl version"
ssh worker-node "sudo crictl ps"
```
**Expected Output**: Deployments created but pods may be in ContainerCreating state, container runtime connection errors in logs, crictl commands failing.

### Task 2 Verification:
```bash
# Check resource allocation and reservation issues
ssh worker-node "sudo journalctl -u kubelet | grep -i 'resource\|eviction\|allocatable'"
kubectl describe nodes | grep -A 10 "Allocatable\|Allocated resources"

# Verify cgroup driver configuration
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep cgroupDriver"
ssh worker-node "sudo cat /etc/containerd/config.toml | grep -i systemd"

# Check for pod evictions due to resource conflicts
kubectl get events --sort-by='.lastTimestamp' | grep -i evict
```
**Expected Output**: Resource allocation conflicts in logs, cgroup driver mismatch between kubelet and containerd, pod eviction events.

### Task 3 Verification:
```bash
# Check container logging configuration and permissions
ssh worker-node "ls -la /var/log/pods-readonly"
ssh worker-node "sudo cat /var/lib/kubelet/config.yaml | grep -A 5 -B 5 containerLog"

# Verify log directory space and permission issues
ssh worker-node "df -h /var/log"
ssh worker-node "ls -la /var/log/containers-full/"

# Check containerd logging configuration
ssh worker-node "sudo cat /etc/containerd/config.toml | grep -A 5 -B 5 registry"
```
**Expected Output**: Read-only log directories, disk space consumed by large log files, invalid registry configuration in containerd.

### Task 4 Verification:
```bash
# Comprehensive container runtime diagnostics
ssh worker-node "sudo systemctl status containerd"
ssh worker-node "sudo crictl info"
ssh worker-node "sudo crictl images | head -10"

# Resource and cgroup analysis
ssh worker-node "cat /proc/cgroups | grep memory"
ssh worker-node "systemctl show kubelet | grep -i cgroup"

# Logging and disk space analysis
ssh worker-node "sudo journalctl -u kubelet | grep -i 'log\|disk\|space' | tail -10"
```
**Expected Output**: containerd service issues, crictl commands failing or returning errors, cgroup configuration problems, logging-related errors.

### Task 5 Verification:
```bash
# Verify container runtime is working
ssh worker-node "sudo systemctl status kubelet containerd"
ssh worker-node "sudo crictl ps"
ssh worker-node "sudo crictl images"

# Check resource allocation is working correctly
kubectl get nodes -o wide
kubectl describe nodes | grep -A 15 "Allocated resources"

# Verify pods can start and run
kubectl get pods -o wide
kubectl logs ecommerce-database-<pod-name> --tail=10
kubectl logs redis-cache-<pod-name> --tail=10

# Test container logging functionality
ssh worker-node "ls -la /var/log/pods/"
kubectl exec redis-cache-<pod-name> -- redis-cli ping
```
**Expected Output**: Both services running, crictl working normally, nodes showing proper resource allocation, pods in Running state with accessible logs.

## Expected Results
- kubelet and containerd services running successfully without errors
- Container runtime accessible via crictl commands (ps, images, info)
- Resource-intensive applications (ecommerce-database, redis-cache) in Running state
- Proper resource allocation with resolved conflicts and appropriate reservations
- cgroup driver consistency between kubelet and containerd
- Container logging working with proper permissions and disk space management
- No pod evictions due to resource conflicts or runtime issues
- Container operations (start, stop, logs) functioning normally

## Key Learning Points
- **Container Runtime Management**: Understanding kubelet-to-container runtime communication and socket configuration
- **Resource Allocation**: Configuring kubelet resource reservations and handling allocation conflicts
- **cgroup Driver Compatibility**: Ensuring consistent cgroup drivers between kubelet and container runtime
- **Container Logging**: Managing container log configuration, permissions, and storage
- **crictl Tool Usage**: Using crictl for container runtime debugging and diagnostics
- **System Resource Management**: Understanding node resource allocation and eviction policies

## Exam & Troubleshooting Tips
- **Real Exam Tips**:
  - Always test container runtime connectivity with `crictl` when pods fail to start
  - Check kubelet and containerd service status when container operations fail
  - Verify cgroup driver consistency when experiencing resource management issues
  - Use `kubectl describe nodes` to check resource allocation and availability
- **Troubleshooting Tips**:
  - **Runtime Issues**: Use `crictl info` and `crictl version` to test container runtime connectivity
  - **Resource Problems**: Check `kubectl describe nodes` for resource allocation and pressure
  - **cgroup Issues**: Verify cgroup driver settings in both kubelet and containerd configs
  - **Logging Problems**: Check log directory permissions and disk space availability
  - **Service Issues**: Use `systemctl status kubelet containerd` to check service health
  - **Configuration Errors**: Validate YAML syntax in kubelet and containerd config files
  - **Recovery Strategy**: Always backup configurations before making changes
  - **Debugging**: Use `journalctl -u kubelet` and `journalctl -u containerd` for detailed error analysis