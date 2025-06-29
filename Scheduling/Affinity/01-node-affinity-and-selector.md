# Node Affinity and Node Selector

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal cluster

## Objective
Master node affinity and node selector configurations to control pod placement based on node characteristics and labels.

## Context
Your development team needs to deploy applications with specific hardware requirements. Some applications require GPU nodes, others need high-memory nodes, and some should avoid certain node types. You need to implement various node selection strategies using both simple node selectors and advanced node affinity rules.

## Prerequisites
- Running Kubernetes cluster with at least 3 nodes
- `kubectl` access with cluster-admin privileges
- Basic understanding of pod and node concepts

## Tasks

### Task 1: Prepare Node Labels and Initial Workload (5 minutes)

Label your cluster nodes with hardware characteristics and create a base application deployment.

1a. Label your nodes with the following characteristics:
- Label one node with `hardware=gpu` and `zone=us-west-1a`
- Label another node with `hardware=high-memory` and `zone=us-west-1b`  
- Label the third node with `hardware=standard` and `zone=us-west-1c`

1b. Create a namespace called `affinity-demo` for this exercise.

1c. Create a deployment called `web-app` in the `affinity-demo` namespace with the following specifications:
- Use `nginx:1.21` image
- 3 replicas
- No node selection constraints initially

### Task 2: Implement Basic Node Selector (5 minutes)

Modify the web-app deployment to use node selector for targeting GPU nodes.

2a. Update the `web-app` deployment to include a node selector that targets nodes with `hardware=gpu`.

2b. Verify that all pods are scheduled on the GPU-labeled node.

### Task 3: Configure Required Node Affinity (7 minutes)

Create a new deployment using required node affinity with multiple matching criteria.

3a. Create a deployment called `memory-intensive-app` in the `affinity-demo` namespace with the following specifications:
- Use `redis:7` image
- 2 replicas
- Required node affinity that matches nodes with `hardware=high-memory` OR `hardware=gpu`
- Must be scheduled in `zone=us-west-1b`

3b. Verify the pods are scheduled only on nodes matching the affinity requirements.

### Task 4: Implement Preferred Node Affinity (8 minutes)

Create a deployment that uses preferred node affinity with weighted preferences.

4a. Create a deployment called `flexible-app` in the `affinity-demo` namespace with the following specifications:
- Use `busybox:1.35` image with command `sleep 3600`
- 4 replicas
- Preferred node affinity with the following weights:
  - Weight 100: prefer nodes with `hardware=high-memory`
  - Weight 50: prefer nodes with `zone=us-west-1a`
- Required node affinity: avoid nodes with `hardware=gpu`

4b. Scale the deployment to 6 replicas and observe the distribution pattern.

## Verification Commands

### Task 1 Verification:
```bash
# Check node labels
kubectl get nodes --show-labels

# Verify namespace creation
kubectl get namespaces affinity-demo

# Check initial deployment
kubectl get deployment web-app -n affinity-demo
kubectl get pods -n affinity-demo -o wide
```

**Expected Output**: 
- All nodes should have the assigned labels
- `affinity-demo` namespace should exist
- 3 `web-app` pods should be distributed across available nodes

### Task 2 Verification:
```bash
# Check deployment node selector
kubectl get deployment web-app -n affinity-demo -o jsonpath='{.spec.template.spec.nodeSelector}'

# Verify pod placement
kubectl get pods -n affinity-demo -l app=web-app -o wide
```

**Expected Output**:
- Node selector should show `{"hardware":"gpu"}`
- All `web-app` pods should be running on the GPU-labeled node

### Task 3 Verification:
```bash
# Check node affinity configuration
kubectl get deployment memory-intensive-app -n affinity-demo -o jsonpath='{.spec.template.spec.affinity.nodeAffinity}'

# Verify pod placement
kubectl get pods -n affinity-demo -l app=memory-intensive-app -o wide
```

**Expected Output**:
- Node affinity should show required scheduling terms with `hardware` and `zone` constraints
- All `memory-intensive-app` pods should be on nodes with `hardware=high-memory` or `hardware=gpu` AND `zone=us-west-1b`

### Task 4 Verification:
```bash
# Check preferred node affinity
kubectl get deployment flexible-app -n affinity-demo -o jsonpath='{.spec.template.spec.affinity.nodeAffinity.preferredDuringSchedulingIgnoredDuringExecution}'

# Check pod distribution
kubectl get pods -n affinity-demo -l app=flexible-app -o wide

# Verify no pods on GPU nodes
kubectl get pods -n affinity-demo -l app=flexible-app -o jsonpath='{range .items[*]}{.spec.nodeName}{"\n"}{end}' | xargs -I {} kubectl get node {} -o jsonpath='{.metadata.name}: {.metadata.labels.hardware}{"\n"}'
```

**Expected Output**:
- Preferred affinity should show two preference rules with weights 100 and 50
- No `flexible-app` pods should be scheduled on GPU nodes
- Pods should prefer high-memory nodes when available

## Expected Results

After completing all tasks, your cluster should have:
- 3 nodes labeled with hardware and zone characteristics
- `web-app` deployment (3 replicas) running only on GPU nodes
- `memory-intensive-app` deployment (2 replicas) running on high-memory or GPU nodes in zone us-west-1b
- `flexible-app` deployment (6 replicas) distributed according to preferences, avoiding GPU nodes

## Key Learning Points

- **Node Selector**: Simple key-value matching for basic pod placement control
- **Required Node Affinity**: Strict rules that must be satisfied for pod scheduling
- **Preferred Node Affinity**: Weighted preferences that influence but don't mandate placement
- **Affinity Operators**: Using `In`, `NotIn`, `Exists`, and `DoesNotExist` for flexible matching
- **Multiple Constraints**: Combining different affinity rules for complex scheduling logic
- **Scheduling Flexibility**: Understanding when to use required vs preferred constraints based on workload requirements

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **Time Management**: Practice writing node affinity YAML quickly - it's verbose
- **Label Strategy**: Always verify node labels before creating affinity rules
- **Testing Approach**: Use `kubectl get pods -o wide` to quickly verify pod placement
- **Syntax Precision**: Node affinity has nested structures - practice the exact YAML syntax

### Troubleshooting Tips:
- **Pending Pods**: If pods remain pending, check if any nodes match the affinity requirements
- **Label Mismatches**: Verify node labels match exactly with affinity selectors (case-sensitive)
- **Operator Errors**: Ensure correct operators (`In`, `NotIn`) are used with appropriate value arrays
- **Combined Rules**: When using both required and preferred affinity, ensure required rules don't conflict
- **Node Availability**: Check if target nodes are schedulable and not cordoned or drained