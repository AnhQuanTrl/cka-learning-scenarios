# Advanced Probe Configuration

## Scenario Overview
-   **Time Limit**: 25 minutes
-   **Difficulty**: Advanced
-   **Environment**: k3s bare metal

## Objective
This scenario will teach you how to master advanced probe configurations, including custom HTTP headers, timeouts, success/failure thresholds, and the gRPC probe type, to create precise and reliable health checks.

## Context
As a senior engineer on the platform team, you need to implement highly specific health checks for a new suite of microservices. This requires going beyond basic setups and fine-tuning every parameter for maximum reliability and performance, ensuring that the Kubernetes health checks are as robust as the applications they monitor.

## Prerequisites
-   A running Kubernetes cluster (k3s is recommended).
-   `kubectl` installed and configured to connect to your cluster.

## Tasks

### Task 1: Customizing an HTTP Probe (5 mins)
Your first task is to configure a readiness probe that sends a custom HTTP header. This is often required to route health checks correctly through an internal API gateway or to signal to the application that the request is a health check.

1.  Create a pod manifest named `http-headers-pod.yaml`.
2.  The pod should be named **http-headers-app** and use the image **mendhak/http-https-echo**, which logs request details to standard output.
3.  Add a `readinessProbe` with an `httpGet` check on path **/** and port **8080**.
4.  In the `httpGet` definition, add a custom header with the name **X-Health-Check** and the value **k8s-probe**.

### Task 2: Fine-Tuning Probe Timing (10 mins)
Next, you'll handle two common timing issues: probes that time out and applications that flap between states.

**Part A: Handling Timeouts**
1.  Create a pod manifest named `timeout-pod.yaml`.
2.  The pod should be named **timeout-app** and use the **busybox:1.34** image.
3.  The pod needs a readiness probe that will time out. Use an `exec` probe with the following command, which takes 5 seconds to complete:
    ```bash
    ["/bin/sh", "-c", "sleep 5 && exit 0"]
    ```
4.  Configure the probe with a `timeoutSeconds` of **2**.
5.  Apply the manifest and observe that the probe fails due to the timeout.
6.  Fix the issue by deleting the pod and updating the manifest to set `timeoutSeconds` to **10**.

**Part B: Requiring Consecutive Successes**
1.  Create a pod manifest named `success-threshold-pod.yaml`.
2.  The pod should be named **flapping-app**. It will simulate an app that is unhealthy for 5 seconds, then healthy for 5 seconds. Use the image **busybox:1.34** with the following command:
    ```bash
    ["/bin/sh", "-c", "while true; do rm -f /tmp/healthy; sleep 5; touch /tmp/healthy; sleep 5; done"]
    ```
3.  Add a `readinessProbe` that checks for the file with `exec` and the command `cat /tmp/healthy`. Set `periodSeconds` to **2**.
4.  Configure the probe with a `successThreshold` of **3**. This means the pod will only be marked as ready after 3 consecutive successful checks.

### Task 3: Implementing a gRPC Probe (5 mins)
Now, you will configure a health check for a gRPC service using Kubernetes' native gRPC probe type.

1.  Create a pod manifest named `grpc-pod.yaml`.
2.  The pod should be named **grpc-app** and use the public image **agabani/grpc-health-server:1.0**, which runs a standard gRPC health check service on port 50051.
3.  Add a `readinessProbe` of type `grpc`.
4.  Configure the probe to check the service on port **50051**.

### Task 4: Creating a Combined Probe Strategy (5 mins)
For your final task, you will create a single, robust pod definition for a complex application, combining multiple probe types and configurations.

1.  Create a pod manifest named `complex-pod.yaml` for a pod named **complex-app**.
2.  The application is a web server that takes 45 seconds to start up. After starting, it creates a file at `/tmp/ready`. Use the image **nginx:1.21.6** with the following command:
    ```bash
    ["/bin/sh", "-c", "echo 'Starting up...'; sleep 45; touch /tmp/ready; echo 'Ready.'; nginx -g 'daemon off;'"]
    ```
3.  Configure three different probes to ensure maximum reliability:
    -   A `startupProbe` using `httpGet` on port **80**. Give it a budget of 60 seconds to succeed (`failureThreshold: 12`, `periodSeconds: 5`).
    -   A `readinessProbe` using `exec` to check for the existence of the file at `/tmp/ready`.
    -   A `livenessProbe` using `tcpSocket` on port **80** to ensure the web server is always listening after it has started.

## Verification Commands

### Task 1 Verification
-   After the pod is running, check its logs:
    ```bash
    kubectl logs http-headers-app
    ```
    **Expected Output**: You should see log entries for the probe requests. Inside the JSON payload of the logs, look for the `"X-Health-Check": "k8s-probe"` header.

### Task 2 Verification
-   **Part A**: Describe the first `timeout-app` pod:
    ```bash
    kubectl describe pod timeout-app
    ```
    **Expected Output**: In the `Events` section, you will see `Warning Unhealthy` messages with the reason "Probe timed out". After fixing the timeout, the pod will become ready.
-   **Part B**: Watch the `flapping-app` pod's status:
    ```bash
    kubectl get pod flapping-app -w
    ```
    **Expected Output**: The pod will start with status `0/1`. It will take at least 6 seconds (3 successful checks at 2s intervals) for the pod's status to change to `1/1`.

### Task 3 Verification
-   Check the pod's status.
    ```bash
    kubectl get pod grpc-app
    ```
    **Expected Output**: The pod should be `Running` and its `READY` status should be `1/1`.
-   Describe the pod to confirm the probe type.
    ```bash
    kubectl describe pod grpc-app
    ```
    **Expected Output**: You will see the `gRPC` probe configuration listed.

### Task 4 Verification
-   Describe the pod to see the full configuration and event log.
    ```bash
    kubectl describe pod complex-app
    ```
    **Expected Output**: You will see all three probes (`startupProbe`, `readinessProbe`, `livenessProbe`) listed in the container definition. The event log will show the startup probe running first, followed by the pod becoming ready.

## Key Learning Points
-   **Advanced HTTP Probes**: You can specify custom paths and headers (`httpHeaders`) for `httpGet` probes.
-   **Fine-Grained Timing**: `timeoutSeconds` controls how long to wait for a probe to return, while `successThreshold` requires multiple consecutive successes to mark a container as healthy, preventing "flapping."
-   **gRPC Probes**: Use the native `grpc` probe type for efficient health checking of gRPC services, which is better than using a generic `exec` probe.
-   **Combined Strategy**: Real-world applications often require a combination of startup, readiness, and liveness probes, each with the most appropriate type (`httpGet`, `tcpSocket`, `exec`, `grpc`) for the specific check.

## Exam & Troubleshooting Tips
-   **Exam Tip**: For the CKA exam, knowing how to quickly `describe` a pod and interpret the probe configuration and events is critical for debugging.
-   **Troubleshooting Tip**: If a probe is failing unexpectedly, check every parameter. A common mistake is a mismatched port, path, or a `timeoutSeconds` that is too short for the application's response time.
