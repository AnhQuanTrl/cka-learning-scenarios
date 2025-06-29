# Topology Spread Constraints

## Scenario Overview
- **Time Limit**: 35 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal cluster

## Objective
Master topology spread constraints to achieve fine-grained control over pod distribution across cluster topology domains for optimal availability and resource utilization.

## Context
Your production workloads need sophisticated distribution strategies that go beyond simple anti-affinity. You need to ensure workloads are evenly distributed across availability zones, nodes, and other topology domains while maintaining specific skew tolerances. This is critical for fault tolerance and load balancing in multi-zone deployments.

## Prerequisites
- Running Kubernetes cluster with at least 3 nodes
- `kubectl` access with cluster-admin privileges
- Nodes labeled with zone and rack information
- Understanding of pod scheduling concepts

## Tasks

### Task 1: Prepare Topology Labels and Test Environment (8 minutes)

Set up comprehensive topology labels across your cluster nodes to simulate a multi-zone, multi-rack environment.

1a. Create a namespace called `topology-demo` for this exercise.

1b. Label your nodes with topology information:
- Node 1: `topology.kubernetes.io/zone=zone-a`, `topology.kubernetes.io/rack=rack-1`
- Node 2: `topology.kubernetes.io/zone=zone-b`, `topology.kubernetes.io/rack=rack-2`  
- Node 3: `topology.kubernetes.io/zone=zone-c`, `topology.kubernetes.io/rack=rack-3`

1c. Create a simple deployment called `baseline-app` in the `topology-demo` namespace with the following specifications:
- Use `nginx:1.21` image
- 6 replicas
- Labels: `app=baseline-app`
- No topology constraints initially

1d. Observe the natural distribution of pods across nodes without constraints.

### Task 2: Implement Basic Zone-Level Topology Spread (8 minutes)

Create a deployment with topology spread constraints to ensure even distribution across zones.

2a. Create a deployment called `zone-distributed-app` in the `topology-demo` namespace with the following specifications:
- Use `httpd:2.4` image
- 9 replicas
- Labels: `app=zone-distributed-app`, `version=v1`
- Topology spread constraint:
  - `maxSkew: 1`
  - `topologyKey: topology.kubernetes.io/zone`
  - `whenUnsatisfiable: DoNotSchedule`
  - `labelSelector: app=zone-distributed-app`

2b. Verify the even distribution across zones and observe any pending pods if distribution cannot be achieved.

### Task 3: Configure Multi-Level Topology Constraints (10 minutes)

Create a deployment with multiple topology spread constraints operating at different topology levels.

3a. Create a deployment called `multi-level-app` in the `topology-demo` namespace with the following specifications:
- Use `busybox:1.35` image with command `sleep 3600`
- 12 replicas
- Labels: `app=multi-level-app`, `component=worker`
- Two topology spread constraints:
  1. Zone-level: `maxSkew: 2`, `topologyKey: topology.kubernetes.io/zone`, `whenUnsatisfiable: DoNotSchedule`
  2. Node-level: `maxSkew: 1`, `topologyKey: kubernetes.io/hostname`, `whenUnsatisfiable: ScheduleAnyway`
- Both constraints should use `labelSelector: app=multi-level-app`

3b. Analyze the distribution pattern across both zones and individual nodes.

### Task 4: Implement Flexible Topology Constraints (9 minutes)

Create a deployment that uses `ScheduleAnyway` policy for more flexible scheduling while still attempting optimal distribution.

4a. Create a deployment called `flexible-app` in the `topology-demo` namespace with the following specifications:
- Use `redis:7` image
- 8 replicas
- Labels: `app=flexible-app`, `tier=cache`
- Topology spread constraint:
  - `maxSkew: 3`
  - `topologyKey: topology.kubernetes.io/rack`
  - `whenUnsatisfiable: ScheduleAnyway`
  - `labelSelector: app=flexible-app`

4b. Scale the deployment to 15 replicas and observe how the scheduler handles the increased skew.

4c. Create a second deployment called `strict-app` with identical specifications except:
- Use `postgres:14` image
- Labels: `app=strict-app`, `tier=database`
- Change `whenUnsatisfiable: DoNotSchedule`
- Scale to 15 replicas and compare the behavior

## Verification Commands

### Task 1 Verification:
```bash
# Check topology labels on nodes
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.'topology\.kubernetes\.io/zone',RACK:.metadata.labels.'topology\.kubernetes\.io/rack'

# Verify namespace and baseline deployment
kubectl get namespace topology-demo
kubectl get deployment baseline-app -n topology-demo

# Check baseline pod distribution
kubectl get pods -n topology-demo -l app=baseline-app -o wide
```

**Expected Output**:
- All nodes should have zone and rack labels assigned
- `baseline-app` deployment should show 6/6 replicas ready
- Pods should be distributed naturally across available nodes

### Task 2 Verification:
```bash
# Check topology spread constraints configuration
kubectl get deployment zone-distributed-app -n topology-demo -o jsonpath='{.spec.template.spec.topologySpreadConstraints}'

# Verify zone distribution
kubectl get pods -n topology-demo -l app=zone-distributed-app -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,ZONE:.metadata.labels.'topology\.kubernetes\.io/zone' --sort-by=.spec.nodeName

# Check for pending pods
kubectl get pods -n topology-demo -l app=zone-distributed-app --field-selector=status.phase=Pending
```

**Expected Output**:
- Topology spread constraints should show maxSkew=1, zone topology key, DoNotSchedule policy
- Pods should be evenly distributed across zones (3 pods per zone for 9 replicas across 3 zones)
- No pods should be pending if even distribution is possible

### Task 3 Verification:
```bash
# Check multi-level constraints
kubectl get deployment multi-level-app -n topology-demo -o jsonpath='{.spec.template.spec.topologySpreadConstraints[*]}'

# Analyze distribution by zone
kubectl get pods -n topology-demo -l app=multi-level-app -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName | sort -k2 | uniq -c -f1

# Analyze distribution by node
kubectl get pods -n topology-demo -l app=multi-level-app -o wide --sort-by=.spec.nodeName
```

**Expected Output**:
- Should show two topology spread constraints with different topology keys
- Zone distribution should have maxSkew of 2 (e.g., 2-6 pods per zone)
- Node distribution should be as even as possible given the zone constraints

### Task 4 Verification:
```bash
# Check flexible app distribution across racks
kubectl get pods -n topology-demo -l app=flexible-app -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,RACK:.metadata.labels.'topology\.kubernetes\.io/rack' --sort-by=.spec.nodeName

# Check strict app behavior with same parameters
kubectl get pods -n topology-demo -l app=strict-app -o wide
kubectl get pods -n topology-demo -l app=strict-app --field-selector=status.phase=Pending

# Compare skew between flexible and strict deployments
kubectl get pods -n topology-demo -l 'app in (flexible-app,strict-app)' -o custom-columns=APP:.metadata.labels.app,NODE:.spec.nodeName,STATUS:.status.phase --sort-by=.metadata.labels.app
```

**Expected Output**:
- `flexible-app` should schedule all 15 pods even with high skew
- `strict-app` may have pending pods if maxSkew=3 cannot be maintained
- Flexible app will show higher rack distribution variance than strict app

## Expected Results

After completing all tasks, your cluster should have:
- All nodes labeled with zone and rack topology information
- `baseline-app` deployment (6 replicas) distributed naturally
- `zone-distributed-app` deployment (9 replicas) evenly distributed across zones
- `multi-level-app` deployment (12 replicas) balanced across both zones and nodes
- `flexible-app` deployment (15 replicas) distributed with tolerance for skew
- `strict-app` deployment showing pending pods or strict distribution enforcement

## Key Learning Points

- **Topology Spread Constraints**: Advanced scheduling feature for fine-grained pod distribution control
- **MaxSkew**: Maximum allowed difference in pod count between topology domains
- **Topology Keys**: Using standard labels like `topology.kubernetes.io/zone` and custom labels for distribution
- **WhenUnsatisfiable Policies**: 
  - `DoNotSchedule`: Strict enforcement, may leave pods pending
  - `ScheduleAnyway`: Flexible enforcement, always schedules pods
- **Multi-Level Constraints**: Combining multiple topology constraints for complex distribution requirements
- **Label Selectors**: Ensuring constraints apply to the correct pod set
- **Real-World Applications**: Implementing fault tolerance and load balancing strategies

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **YAML Complexity**: Topology spread constraints have complex YAML structure - practice writing it quickly
- **Label Consistency**: Ensure topology keys exist on all relevant nodes
- **Skew Calculation**: Understand how maxSkew is calculated (difference between domains with most and least pods)
- **Policy Selection**: Choose `DoNotSchedule` for strict requirements, `ScheduleAnyway` for flexibility
- **Testing Strategy**: Always verify distribution with `kubectl get pods -o wide` after deployment

### Troubleshooting Tips:
- **Pending Pods**: Often caused by impossible topology constraints or insufficient nodes
- **Label Mismatches**: Verify labelSelector matches target pods exactly
- **Topology Key Errors**: Ensure topology keys exist on all nodes where pods might be scheduled  
- **Skew Too Restrictive**: Consider increasing maxSkew or using `ScheduleAnyway` policy
- **Multiple Constraints Conflict**: Check that multiple topology constraints don't create impossible requirements
- **Node Availability**: Ensure target nodes are schedulable and not cordoned
- **Resource Constraints**: Topology constraints can't override resource limitations on nodes