# Readiness Probes: Managing Application Availability

## Scenario Overview
-   **Time Limit**: 20 minutes
-   **Difficulty**: Intermediate
-   **Environment**: k3s bare metal

## Objective
This scenario teaches you how to use readiness probes to control whether a pod is included in service load balancing, which is crucial for managing application startup and achieving zero-downtime deployments.

## Context
You are deploying a new version of a critical microservice. This version needs to load a large amount of data into its cache on startup, a process that takes about 30 seconds. You must prevent the Kubernetes service from sending traffic to new pods until they are fully initialized and ready to serve requests.

## Prerequisites
-   A running Kubernetes cluster (k3s is recommended).
-   `kubectl` installed and configured to connect to your cluster.

## Tasks

### Task 1: Deploy a Slow-Starting App Without a Readiness Probe (5 mins)
First, let's observe the problem. You will create a Deployment and a Service. The pods in the Deployment will have a simulated startup delay.

1.  Create a file named `readiness-deployment.yaml` to define a Deployment and a Service.
2.  **Service Definition**:
    -   Name the service **readiness-svc**.
    -   It should select pods with the label `app: readiness-app`.
    -   It should expose port **80**.
3.  **Deployment Definition**:
    -   Name the deployment **readiness-app-deployment**.
    -   Request **2 replicas**.
    -   The pod template should have the label `app: readiness-app`.
    -   The container should be named **readiness-container**, use the image **nginx:1.21.6**, and have the following command to simulate a 30-second startup delay:
        ```bash
        ["/bin/sh", "-c", "echo 'Simulating slow startup...'; sleep 30; echo 'Application started!'; nginx -g 'daemon off;'"]
        ```
4.  Apply the manifest. Immediately after, check the endpoints of the **readiness-svc**.

### Task 2: Implement a Readiness Probe (10 mins)
Now, you will add a readiness probe to the Deployment. This will ensure pods are only added to the service's endpoints *after* they are fully initialized.

1.  Modify the `readiness-deployment.yaml` file.
2.  Update the container's command to create a file after the startup delay, which the probe can check for:
    ```bash
    ["/bin/sh", "-c", "echo 'Starting up...'; sleep 30; touch /tmp/ready; echo 'Application ready.'; nginx -g 'daemon off;'"]
    ```
3.  Add a `readinessProbe` to the container definition.
    -   Use an `exec` probe that runs the command `cat /tmp/ready`.
    -   Set `initialDelaySeconds` to **5** and `periodSeconds` to **5**.
4.  Apply the updated manifest. Watch the status of the pods and the service's endpoints this time.

### Task 3: Observe a Zero-Downtime Rolling Update (5 mins)
The true power of readiness probes shines during deployments. Let's trigger a rolling update and see how it ensures zero downtime.

1.  In a separate terminal, start watching the service endpoints:
    ```bash
    kubectl get endpoints readiness-svc -w
    ```
2.  In your main terminal, trigger a rolling update by setting a new annotation on the deployment. This is a common way to force a rollout without changing the image.
    ```bash
    kubectl annotate deployment readiness-app-deployment kubernetes.io/restartedAt=$(date +'%Y-%m-%dT%H:%M:%S%z') --overwrite
    ```
3.  Observe the output in both terminals. Pay close attention to how new pods are added to the endpoints and old ones are removed.

## Verification Commands

### Task 1 Verification
-   Get the service endpoints immediately after applying the manifest:
    ```bash
    kubectl get endpoints readiness-svc
    ```
    **Expected Output**: You will see IP addresses listed in the `ENDPOINTS` column almost immediately, even though the Nginx application inside the pods hasn't started yet. Any traffic sent now would fail.

### Task 2 Verification
-   Watch the pods' status:
    ```bash
    kubectl get pods -l app=readiness-app -w
    ```
    **Expected Output**: You will see the pods start, but their `READY` status will be `0/1`. After about 30 seconds, the status will change to `1/1`.
-   Watch the service endpoints:
    ```bash
    kubectl get endpoints readiness-svc -w
    ```
    **Expected Output**: The `ENDPOINTS` list will be empty at first. The pod IPs will only be added *after* their `READY` status becomes `1/1`.

### Task 3 Verification
-   Observe the rolling update process.
    **Expected Output**: In the endpoint watch terminal, you will see a graceful transition. A new pod IP will be added first. Only then will an old pod IP be removed. This continues until all old pods are replaced by new, ready pods, ensuring there are always ready endpoints to handle traffic.

## Expected Results
-   A Deployment named **readiness-app-deployment** is running with 2 replicas.
-   Each pod in the deployment has a readiness probe configured.
-   A Service named **readiness-svc** that only routes traffic to pods that have passed their readiness probe check.

## Key Learning Points
-   **Readiness vs. Liveness**: A liveness probe restarts a broken container, while a readiness probe temporarily removes a container from service load balancing. A container can be alive but not ready (e.g., during startup).
-   **Service Endpoints**: Readiness probes directly control whether a pod's IP address is included in a Service's list of endpoints.
-   **Zero-Downtime Deployments**: Readiness probes are essential for rolling updates. They ensure that Kubernetes waits for new pods to be fully ready before terminating the old ones, preventing service interruptions.

## Exam & Troubleshooting Tips
-   **Exam Tip**: If a service isn't working, one of the first things to check is `kubectl get endpoints <service-name>`. If the list is empty, it's very likely that the pods selected by the service are failing their readiness probes.
-   **Troubleshooting Tip**: Use `kubectl describe pod <pod-name>` to see readiness probe events. If a pod is stuck in a `0/1` ready state, the events section will tell you why the probe is failing.
