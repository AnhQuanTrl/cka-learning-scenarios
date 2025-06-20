# Requests and Limits

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Understand and implement resource requests and limits to manage container resource consumption and ensure predictable performance.

## Context
A development team is deploying a new microservice, but they are reporting performance issues. The application sometimes becomes unresponsive, and other times it gets terminated unexpectedly. As the Kubernetes administrator, you suspect this is due to improper resource management. Your task is to configure appropriate resource requests and limits to stabilize the application and guarantee its quality of service.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured to interact with your cluster.
- A text editor to create YAML manifests.

## Tasks

### Task 1: Deploy a Pod without Resource Constraints
*Suggested time: 5 minutes*

First, deploy a simple NGINX pod without any resource requests or limits to observe its default behavior.

1.  Create a file named `no-resources-pod.yaml` with the following content:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: no-resources-pod
    spec:
      containers:
      - name: nginx
        image: nginx:latest
    ```

2.  Apply the manifest to your cluster.

### Task 2: Set Resource Requests
*Suggested time: 7 minutes*

The application needs a guaranteed amount of resources to start and run reliably. You will now create a new pod with resource requests.

1.  Create a file named `requests-pod.yaml`.
2.  Define a pod named **requests-pod** using the **nginx:latest** image.
3.  Specify the following resource requests for the container:
    *   **CPU**: **100m** (0.1 core)
    *   **Memory**: **128Mi**

4.  Apply the manifest and ensure the pod is scheduled and running.

### Task 3: Set Resource Limits
*Suggested time: 8 minutes*

To prevent the application from consuming excessive resources and impacting other workloads, you will now add resource limits.

1.  Create a file named `limits-pod.yaml`.
2.  Define a pod named **limits-pod** using the **nginx:latest** image.
3.  Specify the following resource requests and limits:
    *   **Requests**:
        *   **CPU**: **100m**
        *   **Memory**: **128Mi**
    *   **Limits**:
        *   **CPU**: **200m**
        *   **Memory**: **256Mi**

4.  Apply the manifest and observe the pod's status.

### Task 4: Observe QoS Classes
*Suggested time: 5 minutes*

Kubernetes assigns a Quality of Service (QoS) class to pods based on their resource requests and limits. Let's inspect the QoS classes of the pods you created.

1.  Inspect the QoS class for `no-resources-pod`, `requests-pod`, and `limits-pod`.
2.  Note the differences and understand why each pod received its specific QoS class.

## Verification Commands

### Task 1 Verification
-   Check that the pod was created successfully:
    ```sh
    kubectl get pod no-resources-pod
    ```
-   Expected Output: The pod should be in the `Running` state.

### Task 2 Verification
-   Verify the pod's creation and check its resource requests:
    ```sh
    kubectl describe pod requests-pod
    ```
-   Expected Output: Under the `Containers` section, you should see the specified CPU and Memory requests.

### Task 3 Verification
-   Verify the pod's creation and check its resource limits:
    ```sh
    kubectl describe pod limits-pod
    ```
-   Expected Output: Under the `Containers` section, you should see the specified CPU and Memory requests and limits.

### Task 4 Verification
-   Check the QoS class for each pod:
    ```sh
    # For no-resources-pod
    kubectl get pod no-resources-pod -o jsonpath='{.status.qosClass}'

    # For requests-pod
    kubectl get pod requests-pod -o jsonpath='{.status.qosClass}'

    # For limits-pod
    kubectl get pod limits-pod -o jsonpath='{.status.qosClass}'
    ```
-   Expected Output:
    *   `no-resources-pod`: **BestEffort**
    *   `requests-pod`: **Burstable**
    *   `limits-pod`: **Burstable**

## Expected Results
-   `no-resources-pod` is running with no resource constraints.
-   `requests-pod` is running with guaranteed CPU and memory.
-   `limits-pod` is running with both guaranteed resources and hard limits.
-   Each pod is assigned the correct QoS class based on its resource configuration.

## Key Learning Points
-   **Resource Requests**: Guarantee a minimum amount of resources for a container, which affects scheduling.
-   **Resource Limits**: Impose a hard cap on the amount of resources a container can use.
-   **QoS Classes**:
    *   **Guaranteed**: Pods where all containers have memory and CPU requests and limits set, and they are equal.
    *   **Burstable**: Pods that do not meet the criteria for Guaranteed but have at least one container with a CPU or memory request.
    *   **BestEffort**: Pods with no memory or CPU requests or limits.
-   Understanding CPU and memory units (`m` for CPU, `Mi` for memory).

## Exam & Troubleshooting Tips
-   **Exam Tip**: Be very comfortable with the syntax for `resources.requests` and `resources.limits` in pod specs. You will be asked to create or modify them under time pressure.
-   **Troubleshooting**: If a pod is stuck in the `Pending` state, use `kubectl describe pod <pod-name>` to check for events. A common issue is `FailedScheduling` due to insufficient resources on any available node.
-   **Troubleshooting**: If a container is terminated with an `OOMKilled` error, it means it exceeded its memory limit. You may need to increase the memory limit or debug the application for memory leaks.
-   **CPU Throttling**: Exceeding the CPU limit doesn't kill the container; it throttles it, leading to performance degradation.
