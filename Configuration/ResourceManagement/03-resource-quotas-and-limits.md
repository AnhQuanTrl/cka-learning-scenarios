# Resource Quotas and Limit Ranges

## Scenario Overview
- **Time Limit**: 35 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Learn how to use `ResourceQuota` and `LimitRange` objects to enforce resource constraints at the namespace and pod level, which is essential for managing multi-tenant clusters.

## Context
As a cluster administrator, you are responsible for managing a shared Kubernetes cluster used by multiple teams. To ensure fair resource distribution and prevent any single team from consuming all available resources, you need to implement namespace-level quotas and default resource limits. This scenario will guide you through setting up and verifying these constraints for two different teams.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with admin access.
- A text editor to create YAML manifests.

## Tasks

### Task 1: Create Namespaces for Teams
*Suggested time: 3 minutes*

First, create two separate namespaces to simulate a multi-tenant environment for a development team and a quality assurance team.

1.  Create a namespace named **dev-team-ns**.
2.  Create a namespace named **qa-team-ns**.

### Task 2: Apply a `ResourceQuota` to a Namespace
*Suggested time: 8 minutes*

The development team has a specific resource budget. You will create a `ResourceQuota` to enforce these limits within their namespace.

1.  Create a file named `dev-quota.yaml`.
2.  Define a `ResourceQuota` object named **dev-resource-quota** for the **dev-team-ns** namespace.
3.  Configure the quota with the following hard limits:
    *   **Pods**: `10`
    *   **Requests CPU**: `2` (2 cores)
    *   **Requests Memory**: `2Gi`
    *   **Limits CPU**: `4` (4 cores)
    *   **Limits Memory**: `4Gi`
    *   **PersistentVolumeClaims**: `5`
    *   **Services**: `10`

4.  Apply the manifest to the cluster.

### Task 3: Test the `ResourceQuota`
*Suggested time: 8 minutes*

Now, verify that the quota is being enforced by attempting to create a Deployment that exceeds the defined limits.

1.  Create a file named `large-deployment.yaml` that defines a Deployment named **large-app** in the **dev-team-ns** namespace.
2.  Configure the Deployment with **5 replicas**.
3.  Specify resource requests for the container that, when combined across all replicas, will violate the quota. For example:
    *   **Requests**:
        *   **CPU**: `500m` (0.5 core)
        *   **Memory**: `500Mi`
    > This would request a total of 2.5 cores, exceeding the 2-core limit.
4.  Attempt to apply the manifest. Observe that the Deployment is created, but the pods fail to schedule.
5.  After observing the failure, create a smaller Deployment named **small-app** with **2 replicas** and the same resource requests that fits within the quota.

### Task 4: Apply a `LimitRange` to a Namespace
*Suggested time: 8 minutes*

The QA team requires default resource constraints for their pods to ensure stability without manually setting them for every workload.

1.  Create a file named `qa-limitrange.yaml`.
2.  Define a `LimitRange` object named **qa-resource-limits** for the **qa-team-ns** namespace.
3.  Configure the `LimitRange` to enforce the following constraints on **Containers**:
    *   **Default Request**:
        *   **CPU**: `100m`
        *   **Memory**: `100Mi`
    *   **Default Limit**:
        *   **CPU**: `200m`
        *   **Memory**: `200Mi`
    *   **Max Limit**:
        *   **CPU**: `1` (1 core)
        *   **Memory**: `1Gi`
    *   **Min Request**:
        *   **CPU**: `50m`
        *   **Memory**: `50Mi`

4.  Apply the manifest to the cluster.

### Task 5: Test the `LimitRange`
*Suggested time: 8 minutes*

Verify that the `LimitRange` automatically applies default resource requests and limits to pods created without them.

1.  Create a file named `qa-pod.yaml` that defines a simple NGINX pod named **test-pod** in the **qa-team-ns** namespace. **Do not** specify any `resources` in the pod spec.
2.  Apply the manifest and wait for the pod to be running.
3.  Inspect the running pod's definition to confirm that the default requests and limits from the `LimitRange` have been automatically applied.
4.  Attempt to create another pod that violates the `LimitRange` (e.g., requests `2Gi` of memory). Observe that the API server rejects its creation.

## Verification Commands

### Task 1 Verification
-   Check that the namespaces were created:
    ```sh
    kubectl get namespaces
    ```
-   Expected Output: The list should include `dev-team-ns` and `qa-team-ns`.

### Task 2 Verification
-   Verify the `ResourceQuota` was created and check its status:
    ```sh
    kubectl describe resourcequota dev-resource-quota --namespace dev-team-ns
    ```
-   Expected Output: The `Used` column for all resources should be `0`. The `Hard` column should show the limits you configured.

### Task 3 Verification
-   After applying `large-deployment.yaml`, check the ReplicaSet events:
    ```sh
    kubectl describe rs -n dev-team-ns
    ```
-   Expected Output: You should see a `FailedCreate` event with a message indicating the quota was exceeded (e.g., `exceeded quota: dev-resource-quota, requested: requests.cpu=500m, used: requests.cpu=1500m, limited: requests.cpu=2`).
-   After applying the `small-app` deployment, check the pods:
    ```sh
    kubectl get pods -n dev-team-ns
    ```
-   Expected Output: The two `small-app` pods should be `Running`.

### Task 4 Verification
-   Verify the `LimitRange` was created:
    ```sh
    kubectl describe limitrange qa-resource-limits --namespace qa-team-ns
    ```
-   Expected Output: The description should show the default, max, and min values you configured.

### Task 5 Verification
-   Inspect the running `test-pod` for applied resource limits:
    ```sh
    kubectl get pod test-pod -n qa-team-ns -o yaml
    ```
-   Expected Output: In the pod's YAML definition under `spec.containers[0].resources`, you should see `requests` and `limits` matching the defaults from the `LimitRange`.
-   When you attempt to create a pod that violates the range, you should see an error message like: `Error from server (Forbidden): pods "violating-pod" is forbidden: memory resource limit is less than memory resource request`.

## Expected Results
-   The `dev-team-ns` has a `ResourceQuota` that prevents users from creating pods or other objects that exceed the total namespace budget.
-   The `qa-team-ns` has a `LimitRange` that automatically assigns default resource requests/limits to containers and rejects any that are too large or too small.
-   You have successfully demonstrated how to enforce resource boundaries in a multi-tenant cluster.

## Key Learning Points
-   **`ResourceQuota` vs. `LimitRange`**:
    *   `ResourceQuota` operates at the **namespace level**, setting aggregate limits on total resource consumption and object counts.
    *   `LimitRange` operates at the **pod/container level** within a namespace, setting default, min, and max constraints for individual objects.
-   **Admission Control**: Both `ResourceQuota` and `LimitRange` are enforced by admission controllers. If a resource creation request violates them, the API server will reject it immediately.
-   **Multi-tenancy**: These objects are fundamental tools for managing shared clusters, ensuring fairness, and preventing resource abuse.

## Exam & Troubleshooting Tips
-   **Exam Tip**: Be clear on the difference between `ResourceQuota` and `LimitRange`. A question might ask you to prevent a namespace from creating more than 5 services (`ResourceQuota`) or to ensure every pod in a namespace gets at least 100Mi of memory (`LimitRange`).
-   **Troubleshooting**: If a user complains they can't create a pod, and you see a `Forbidden` error, immediately check the namespace for a `ResourceQuota` or `LimitRange`. Use `kubectl describe` on the quota/range and the user's YAML to see why it was rejected.
-   **Scope**: Remember that `ResourceQuota` can also limit non-compute resources like the number of `PersistentVolumeClaims`, `Services`, `Secrets`, and `ConfigMaps`.
