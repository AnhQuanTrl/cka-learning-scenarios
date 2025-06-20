# Startup Probes: Protecting Slow-Starting Applications

## Scenario Overview
-   **Time Limit**: 20 minutes
-   **Difficulty**: Intermediate
-   **Environment**: k3s bare metal

## Objective
This scenario teaches you how to use startup probes to give applications with very long initialization times a safe window to start before liveness and readiness probes take over.

## Context
You are tasked with containerizing a legacy monolithic application. This application is notorious for its slow startup time; it can take over a minute to warm up its internal cache and run database migrations. A standard liveness probe configuration is too aggressive and kills the pod before it can finish starting, leading to a `CrashLoopBackOff` state. Your task is to implement a startup probe to fix this, a classic pattern in legacy application modernization.

## Prerequisites
-   A running Kubernetes cluster (k3s is recommended).
-   `kubectl` installed and configured to connect to your cluster.

## Tasks

### Task 1: The Problem - A Liveness Probe Killing a Slow-Starting App (5 mins)
First, let's see how a standard liveness probe can fail a pod that is simply slow to initialize, not actually broken.

1.  Create a pod manifest file named `startup-pod.yaml`.
2.  The pod should be named **legacy-app**.
3.  The container should use the **busybox:1.34** image.
4.  The container's command needs to simulate a very slow startup (90 seconds) before it becomes healthy. It will create a file at `/tmp/healthy` only after this delay.
    ```bash
    ["/bin/sh", "-c", "echo 'Legacy app starting... this will take 90 seconds.'; sleep 90; touch /tmp/healthy; echo 'App started.'; sleep 600"]
    ```
5.  Add a `livenessProbe` to the container. This probe will be too aggressive for our slow app.
    -   Use an `exec` probe that checks for the health file with `cat /tmp/healthy`.
    -   Set `periodSeconds` to **5**.
    -   Set `failureThreshold` to **6**. This gives the app only `5 * 6 = 30` seconds to start, which is not enough.
6.  Apply the manifest and observe the pod's status.

### Task 2: Implementing a Startup Probe to Protect the Application (10 mins)
Now you will add a `startupProbe` to give the application a generous amount of time to start, disabling the liveness probe during this period.

1.  Modify the `startup-pod.yaml` manifest.
2.  Add a `startupProbe` section to the container definition.
    -   The probe check itself should be the same as the liveness probe: an `exec` probe running `cat /tmp/healthy`.
    -   The key is to configure its timing to be very generous. Set `periodSeconds` to **5** and `failureThreshold` to **20**. This gives the application a total of `5 * 20 = 100` seconds to start, which is enough to accommodate the 90-second delay.
3.  Leave the existing `livenessProbe` exactly as it is. The startup probe will automatically disable it until the initial check succeeds.
4.  Apply the updated manifest.

### Task 3: Verifying the Probe Interaction (5 mins)
The final step is to understand and confirm that the liveness probe is deferred until the startup probe succeeds.

1.  Delete and re-apply the manifest from Task 2 to get a clean start.
2.  Immediately after the pod is created, describe the pod and examine its events.
    ```bash
    kubectl describe pod legacy-app
    ```
3.  Pay close attention to the event log. You will see the startup probe failing for a while, then succeeding. You should see no events from the liveness probe during this time.

## Verification Commands

### Task 1 Verification
-   Watch the pod's status. It will eventually enter a `CrashLoopBackOff` state.
    ```bash
    kubectl get pod legacy-app -w
    ```
    **Expected Output**: The pod will go from `Running` to `Terminating`, and its `RESTARTS` count will increase. After a few restarts, its status will become `CrashLoopBackOff`.
-   Describe the pod to see why it's failing.
    ```bash
    kubectl describe pod legacy-app
    ```
    **Expected Output**: The `Events` section will be filled with `Warning Unhealthy` messages from the **Liveness probe**, indicating it failed.

### Task 2 & 3 Verification
-   Watch the pod's status.
    ```bash
    kubectl get pod legacy-app -w
    ```
    **Expected Output**: The pod will start and remain in the `Running` state. The `READY` column will show `1/1` after about 90-100 seconds. The `RESTARTS` count will remain `0`.
-   Describe the pod to see the event timeline.
    ```bash
    kubectl describe pod legacy-app
    ```
    **Expected Output**: The `Events` section will show a series of `Warning Unhealthy` events from the **Startup probe**. After about 90 seconds, these will stop. You will then see a `Normal` event indicating the startup probe succeeded. After this point, the liveness probe takes over, but you won't see any failure events from it because the app is now healthy.

## Expected Results
-   A pod named **legacy-app** that was previously stuck in `CrashLoopBackOff` now starts successfully after being protected by a `startupProbe`.
-   The pod's event log clearly shows the startup probe running first, and the liveness probe only becoming active after the startup probe succeeds.

## Key Learning Points
-   **Startup Probes**: Protect slow-starting applications by disabling liveness and readiness probes until the initial startup is complete.
-   **Probe Interaction**: The startup probe runs first. Once it succeeds, the kubelet hands off responsibility to the liveness and readiness probes.
-   **Calculating Startup Time**: The total startup budget is `failureThreshold * periodSeconds`. This must be longer than your application's worst-case startup time.
-   **Legacy Modernization**: Startup probes are a key tool for running older, monolithic applications in Kubernetes without having to re-architect them for fast startups.

## Exam & Troubleshooting Tips
-   **Exam Tip**: If you see a pod in `CrashLoopBackOff` and the events show liveness failures, but the scenario description mentions the application is just slow to start, `startupProbe` is the correct solution.
-   **Troubleshooting Tip**: Don't use a large `initialDelaySeconds` on a liveness probe as a workaround for slow startups. This is an anti-pattern because it means if the app crashes *after* starting, the liveness probe will still wait a long time before checking it. The startup probe is the correct and more precise tool for this job.
