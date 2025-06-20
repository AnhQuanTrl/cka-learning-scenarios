# Quality of Service (QoS) Classes

## Scenario Overview
- **Time Limit**: 30 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Understand how Kubernetes assigns Quality of Service (QoS) classes to Pods and how this impacts pod scheduling and eviction priority.

## Context
In your cluster, you host critical production workloads alongside less important batch jobs. When a node experiences resource pressure (e.g., runs out of memory), you need to ensure that the most critical applications are the last to be terminated. By correctly configuring resource requests and limits, you can influence the QoS class assigned to each pod and protect high-priority services.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured to interact with your cluster.
- A text editor to create YAML manifests.

## Tasks

### Task 1: Create a `BestEffort` Pod
*Suggested time: 5 minutes*

First, create a pod without any resource requests or limits. These pods have the lowest priority and are the first to be evicted during resource shortages.

1.  Create a file named `besteffort-pod.yaml` with the following content:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: qos-besteffort
    spec:
      containers:
      - name: nginx
        image: nginx:latest
    ```

2.  Apply the manifest to your cluster.

### Task 2: Create a `Burstable` Pod
*Suggested time: 7 minutes*

Next, create a pod with resource requests that are lower than its limits. These pods have a medium priority.

1.  Create a file named `burstable-pod.yaml` with the following content:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: qos-burstable
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            memory: "100Mi"
            cpu: "100m"
          limits:
            memory: "200Mi"
            cpu: "200m"
    ```

2.  Apply the manifest to your cluster.

### Task 3: Create a `Guaranteed` Pod
*Suggested time: 7 minutes*

Finally, create a pod where resource requests are explicitly set and are equal to the limits. These are the highest priority pods and are the last to be evicted.

1.  Create a file named `guaranteed-pod.yaml` with the following content:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: qos-guaranteed
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            memory: "100Mi"
            cpu: "100m"
          limits:
            memory: "100Mi"
            cpu: "100m"
    ```

2.  Apply the manifest to your cluster.

### Task 4: Verify QoS Classes
*Suggested time: 5 minutes*

Now, inspect the pods to confirm that Kubernetes has assigned the correct QoS class to each one based on your resource definitions.

1.  Use `kubectl` to get the `qosClass` from the status of each of the three pods you created.

### Task 5: Observe Eviction Priority (Advanced)
*Suggested time: 6 minutes*

This task demonstrates the practical impact of QoS classes. You will simulate memory pressure on a node and observe which pod gets evicted first.

1.  Create a pod that consumes a large amount of memory to starve the node. Create a file named `stress-pod.yaml`:
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: memory-stress
    spec:
      containers:
      - name: stress-container
        image: polinux/stress
        args:
        - --vm
        - "1"
        - --vm-bytes
        - "500M" 
        - --vm-hang
        - "0"
        resources:
          requests:
            memory: "100Mi"
          limits:
            memory: "1Gi"
    ```
    > **Note**: You may need to adjust the `--vm-bytes` value based on your node's available memory to trigger an eviction.

2.  In a separate terminal, watch the status of the pods:
    ```sh
    kubectl get pods -w
    ```
3.  Apply the `stress-pod.yaml` manifest. Observe the pod statuses in the watch terminal. The `qos-besteffort` pod should be the first to be terminated with the status `Evicted`.

## Verification Commands

### Task 1-3 Verification
-   Check that all three pods were created successfully:
    ```sh
    kubectl get pods
    ```
-   Expected Output: All three pods (`qos-besteffort`, `qos-burstable`, `qos-guaranteed`) should be in the `Running` state.

### Task 4 Verification
-   Check the QoS class for each pod:
    ```sh
    # BestEffort
    kubectl get pod qos-besteffort -o jsonpath='{.status.qosClass}'

    # Burstable
    kubectl get pod qos-burstable -o jsonpath='{.status.qosClass}'

    # Guaranteed
    kubectl get pod qos-guaranteed -o jsonpath='{.status.qosClass}'
    ```
-   Expected Output:
    *   `qos-besteffort`: **BestEffort**
    *   `qos-burstable`: **Burstable**
    *   `qos-guaranteed`: **Guaranteed**

### Task 5 Verification
-   After applying the stress pod, check the final status of the pods:
    ```sh
    kubectl get pods
    ```
-   Expected Output: The `qos-besteffort` pod should have a status of `Evicted`. The other pods should remain `Running`.
-   To see why it was evicted, describe the pod:
    ```sh
    kubectl describe pod qos-besteffort
    ```
-   Expected Output: You should see an event with the reason `Evicted` and a message indicating the node was under memory pressure.

## Expected Results
-   Three pods are running, each with a different QoS class (`BestEffort`, `Burstable`, `Guaranteed`).
-   When memory pressure is introduced, the `BestEffort` pod is evicted first to reclaim resources.
-   The `Burstable` and `Guaranteed` pods remain running, demonstrating their higher priority.

## Key Learning Points
-   **QoS Classes are not set directly**: They are determined by Kubernetes based on the `resources.requests` and `resources.limits` settings for all containers in a pod.
-   **Eviction Priority**: When a node runs out of resources, Kubernetes evicts pods in the following order:
    1.  **BestEffort**: Lowest priority.
    2.  **Burstable**: Medium priority. Evicted if no `BestEffort` pods are left.
    3.  **Guaranteed**: Highest priority. Only evicted if they exceed their own limits or if system daemons need resources.
-   Properly setting requests and limits is crucial for application stability and predictable performance in a shared cluster environment.

## Exam & Troubleshooting Tips
-   **Exam Tip**: You will almost certainly be asked to create a pod with a specific QoS class. Remember the rules: `Guaranteed` (requests = limits), `Burstable` (requests < limits), and `BestEffort` (no requests/limits).
-   **Troubleshooting**: If a critical pod is being evicted, use `kubectl describe pod <pod-name>` to check its QoS class and events. It likely has a lower-than-expected QoS class due to misconfigured resource settings.
-   **Node Allocatable**: Remember that pods can only use the "Allocatable" resources on a node, not the full "Capacity". System daemons reserve some resources. Use `kubectl describe node <node-name>` to see allocatable resources.
