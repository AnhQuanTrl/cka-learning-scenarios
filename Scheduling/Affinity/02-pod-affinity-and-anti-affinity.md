# Pod Affinity and Anti-Affinity

## Scenario Overview
- **Time Limit**: 30 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal cluster

## Objective
Implement pod affinity and anti-affinity rules to control pod co-location and separation patterns for optimal application performance and availability.

## Context
Your microservices architecture requires specific pod placement strategies. Database pods need to be co-located with their corresponding application pods for low latency, while multiple replicas of the same service should be spread across different nodes for high availability. You need to implement both pod affinity for co-location and anti-affinity for distribution.

## Prerequisites
- Running Kubernetes cluster with at least 3 nodes
- `kubectl` access with cluster-admin privileges
- Completed node labeling from previous affinity scenarios
- Understanding of pod labels and selectors

## Tasks

### Task 1: Setup Base Applications and Labels (8 minutes)

Create the foundation applications and establish proper labeling for affinity relationships.

1a. Create a namespace called `pod-affinity-demo` for this exercise.

1b. Create a deployment called `database` in the `pod-affinity-demo` namespace with the following specifications:
- Use `mysql:8.0` image
- 1 replica
- Environment variable `MYSQL_ROOT_PASSWORD=secretpassword`
- Labels: `app=database`, `tier=data`, `service=mysql`

1c. Create a deployment called `cache` in the `pod-affinity-demo` namespace with the following specifications:
- Use `redis:7` image
- 2 replicas
- Labels: `app=cache`, `tier=data`, `service=redis`

1d. Verify all pods are running and note their current node placement.

### Task 2: Implement Pod Affinity for Co-location (7 minutes)

Create an application deployment that uses pod affinity to co-locate with database pods.

2a. Create a deployment called `web-backend` in the `pod-affinity-demo` namespace with the following specifications:
- Use `nginx:1.21` image
- 2 replicas
- Labels: `app=web-backend`, `tier=app`
- Required pod affinity: must be scheduled on the same node as pods with `app=database`
- Use topology key `kubernetes.io/hostname`

2b. Verify that the web-backend pods are co-located with the database pod.

### Task 3: Configure Pod Anti-Affinity for Distribution (8 minutes)

Create a deployment that uses pod anti-affinity to ensure replicas are distributed across different nodes.

3a. Create a deployment called `api-server` in the `pod-affinity-demo` namespace with the following specifications:
- Use `httpd:2.4` image
- 3 replicas
- Labels: `app=api-server`, `tier=app`
- Required pod anti-affinity: replicas must not be scheduled on the same node as other `api-server` pods
- Use topology key `kubernetes.io/hostname`

3b. If you have fewer than 3 nodes, observe the behavior and scale the deployment to match your node count.

### Task 4: Implement Mixed Affinity Patterns (7 minutes)

Create a complex deployment that combines both pod affinity and anti-affinity rules.

4a. Create a deployment called `worker-service` in the `pod-affinity-demo` namespace with the following specifications:
- Use `busybox:1.35` image with command `sleep 3600`
- 4 replicas
- Labels: `app=worker-service`, `tier=worker`
- Preferred pod affinity (weight 100): prefer nodes with pods labeled `tier=data`
- Required pod anti-affinity: must not be scheduled on the same node as other `worker-service` pods
- Use topology key `kubernetes.io/hostname` for both rules

4b. Scale the worker-service deployment to 6 replicas and observe the scheduling behavior.

## Verification Commands

### Task 1 Verification:
```bash
# Check namespace and deployments
kubectl get namespaces pod-affinity-demo
kubectl get deployments -n pod-affinity-demo

# Check pod placement and labels
kubectl get pods -n pod-affinity-demo -o wide --show-labels

# Verify database pod is running
kubectl get pods -n pod-affinity-demo -l app=database -o wide
```

**Expected Output**:
- Namespace `pod-affinity-demo` should exist
- All deployments should be ready (1/1, 2/2)
- All pods should be running with correct labels
- Database pod should be running on one node

### Task 2 Verification:
```bash
# Check pod affinity configuration
kubectl get deployment web-backend -n pod-affinity-demo -o jsonpath='{.spec.template.spec.affinity.podAffinity}'

# Verify co-location
kubectl get pods -n pod-affinity-demo -l app=web-backend -o wide
kubectl get pods -n pod-affinity-demo -l app=database -o wide

# Check if they're on the same node
kubectl get pods -n pod-affinity-demo -l 'app in (web-backend,database)' -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName
```

**Expected Output**:
- Pod affinity should show required scheduling terms with `app=database` selector
- All `web-backend` pods should be on the same node as the `database` pod
- Custom columns output should show same node name for database and web-backend pods

### Task 3 Verification:
```bash
# Check pod anti-affinity configuration
kubectl get deployment api-server -n pod-affinity-demo -o jsonpath='{.spec.template.spec.affinity.podAntiAffinity}'

# Verify distribution across nodes
kubectl get pods -n pod-affinity-demo -l app=api-server -o wide

# Check if any pods are pending due to anti-affinity constraints
kubectl get pods -n pod-affinity-demo -l app=api-server --field-selector=status.phase=Pending
```

**Expected Output**:
- Pod anti-affinity should show required scheduling terms with `app=api-server` selector
- `api-server` pods should be distributed across different nodes (up to your node count)
- If you have fewer nodes than replicas, some pods may be pending

### Task 4 Verification:
```bash
# Check combined affinity configuration
kubectl get deployment worker-service -n pod-affinity-demo -o jsonpath='{.spec.template.spec.affinity}'

# Verify worker pods placement
kubectl get pods -n pod-affinity-demo -l app=worker-service -o wide

# Check relationship with data tier pods
kubectl get pods -n pod-affinity-demo -l 'tier in (data,worker)' -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,TIER:.metadata.labels.tier
```

**Expected Output**:
- Affinity should show both podAffinity (preferred) and podAntiAffinity (required) rules
- Worker pods should be distributed across nodes (no two on same node)
- Worker pods should prefer nodes with data tier pods when possible

## Expected Results

After completing all tasks, your cluster should have:
- `database` deployment (1 replica) running on one node
- `cache` deployment (2 replicas) distributed as scheduled
- `web-backend` deployment (2 replicas) co-located with database pod
- `api-server` deployment (3 replicas) distributed across different nodes
- `worker-service` deployment (6 replicas) distributed across nodes, preferring nodes with data tier pods

## Key Learning Points

- **Pod Affinity**: Co-locating pods for performance benefits (reduced network latency)
- **Pod Anti-Affinity**: Distributing pods for high availability and fault tolerance
- **Topology Keys**: Using `kubernetes.io/hostname` for node-level constraints
- **Required vs Preferred**: Understanding when to use strict vs flexible rules
- **Label Selectors**: Matching pods based on labels for affinity relationships
- **Mixed Constraints**: Combining affinity and anti-affinity for complex placement logic
- **Scheduling Limitations**: Understanding how node count affects anti-affinity scheduling

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **Topology Keys**: Always specify appropriate topology keys (`kubernetes.io/hostname` for node-level)
- **Label Matching**: Double-check that label selectors match target pod labels exactly
- **Required vs Preferred**: Use required for critical constraints, preferred for optimization
- **YAML Structure**: Practice the nested structure of podAffinity and podAntiAffinity
- **Quick Testing**: Use `kubectl get pods -o wide` to quickly verify pod placement

### Troubleshooting Tips:
- **Pending Pods**: Check if anti-affinity constraints are too restrictive for available nodes
- **Unexpected Placement**: Verify label selectors match intended pods exactly
- **Topology Key Errors**: Ensure topology keys exist on target nodes
- **Affinity Not Working**: Check that referenced pods are actually running and labeled correctly
- **Resource Constraints**: Pod affinity/anti-affinity can't override resource constraints or node selectors
- **Multiple Rules**: When combining affinity types, ensure they don't create impossible scheduling scenarios