# CKA Learning Scenarios - Task Tracking

## Project Status Overview
This document tracks the progress of creating CKA exam preparation scenarios based on Kubernetes concepts.

## Completed Tasks ✅

### Storage/StorageClass
- [x] **Directory Structure**: Created `Storage/StorageClass/` folder structure
- [x] **Basic StorageClass Creation**: `01-basic-storageclass-creation.md`
  - Covers StorageClass creation, default StorageClass configuration
  - Focuses on reclaim policies and volume binding modes
  - Includes StatefulSet and Deployment consuming different StorageClasses
  - Comprehensive verification commands and expected results
  - Note: Volume expansion removed (not supported by rancher.io/local-path provisioner)
- [x] **Static vs Dynamic Provisioning**: `02-dynamic-provisioning.md`
  - Compares manual PV creation (static) vs StorageClass automation (dynamic)
  - Side-by-side workflow demonstration using Deployments
  - Shows PV naming patterns and creation order differences
  - Explains when to use each provisioning approach
- [x] **Reclaim Policy Scenario**: `03-reclaim-policy.md`
  - Compares Retain vs Delete reclaim policies with practical demonstration
  - Shows PV behavior when PVCs are deleted (Released vs automatic deletion)
  - Includes data persistence testing and manual cleanup procedures
  - Explains production vs development use cases for each policy
- [x] **Volume Binding Mode Scenario**: `04-volume-binding-mode.md`
  - Compares Immediate vs WaitForFirstConsumer binding modes
  - Demonstrates timing differences in PV creation and binding
  - Shows topology-aware volume placement concepts
  - Includes practical applications consuming different binding modes
- [x] **NFS Storage Comparison Scenario**: `05-nfs-storage-comparison.md`
  - Compares NFS CSI Driver vs NFS Subdir External Provisioner
  - Demonstrates volume isolation, security, and feature differences
  - Shows deployment of both provisioners with practical applications
  - Covers advanced CSI features like volume expansion and snapshots
  - Environment: k3s bare metal with homelab NFS server
- [x] **Digital Ocean CSI Scenario**: `06-digital-ocean-csi.md`
  - Cloud-specific StorageClass configuration and CSI basics
  - Volume expansion: StorageClass with expansion enabled, demonstrate expanding PVC size dynamically
  - Cost-effective DOKS cluster setup and teardown instructions for learning
  - CSI monitoring and observability features

### Storage/VolumeSnapshots
- [x] **Volume Snapshots Scenario**: `01-volume-snapshots.md`
  - VolumeSnapshot, VolumeSnapshotClass, and VolumeSnapshotContent concepts
  - Point-in-time snapshot creation and management
  - Snapshot-to-PVC restoration workflows with PostgreSQL application
  - Advanced snapshot lifecycle and troubleshooting
  - Environment: DigitalOcean Kubernetes (DOKS)
- [x] **Volume Cloning Scenario**: `02-volume-cloning.md`
  - CSI volume cloning using PVC dataSource
  - Direct PVC-to-PVC cloning without intermediate snapshots
  - Clone vs snapshot performance and use case comparison
  - Data independence and isolation testing with MySQL application
  - Environment: DigitalOcean Kubernetes (DOKS)

### Configuration/ConfigMaps
- [x] **Directory Structure**: Created `Configuration/ConfigMaps/` folder structure
- [x] **ConfigMap Creation Methods**: `01-configmap-creation-methods.md`
  - Imperative vs declarative creation (kubectl create vs YAML)
  - Different data sources (literals, files, directories, binary data)
  - Best practices for configuration organization and size management
  - Comprehensive creation method comparison and troubleshooting
  - Environment: k3s bare metal
- [x] **ConfigMap Consumption Patterns**: `02-configmap-consumption-patterns.md`
  - Environment variable injection (single keys, all keys, envFrom)
  - Volume mounting (full ConfigMap, specific keys, subPath)
  - Command line arguments and container startup configuration
  - Combined consumption methods with Nginx web server demonstration
  - Update propagation behavior and precedence rules
  - Environment: k3s bare metal
- [x] **ConfigMap Updates and Immutability**: `03-configmap-updates-and-immutability.md`
  - Live configuration updates and application reload behavior
  - Immutable ConfigMaps (Kubernetes 1.21+) and performance benefits
  - Rolling updates triggered by configuration changes
  - ConfigMap versioning strategies (name-based and hash-based)
  - Production-ready configuration management patterns
  - Environment: k3s bare metal

### Project Setup
- [x] **CLAUDE.md**: Created with project purpose and scenario quality standards
- [x] **Scenario Quality Standards**: Defined clear task instructions, practical applications, and verification requirements

### Configuration/Secrets
- [x] **Secret Types and Creation**: `01-secret-types-and-creation.md`
  - Opaque secrets (generic user-defined data)
  - ServiceAccount token secrets
  - Creation methods (imperative, declarative, from files)
  - Base64 encoding/decoding and data validation
  - Environment: k3s bare metal
- [x] **Secret Consumption and Security**: `02-secret-consumption-and-security.md`
  - Environment variable injection vs volume mounting
  - Security best practices and RBAC integration
  - Secret data exposure risks and mitigation
  - Practical application using secrets securely
  - Environment: k3s bare metal
- [x] **Docker Registry Secrets**: `03-docker-registry-secrets.md`
 - Creating docker-registry type secrets
 - ImagePullSecrets configuration in Pods and ServiceAccounts
 - Private registry authentication patterns
 - Testing with private container images
 - Environment: k3s bare metal with access to a private Docker registry

### Configuration/Probes
- [x] **Liveness Probes**: `01-liveness-probes.md`
  - HTTP, TCP, and exec probe types for liveness checking
  - Detecting and recovering from application deadlocks
  - Container restart behavior and restart policies
  - Practical applications with different liveness scenarios
  - Environment: k3s bare metal
- [x] **Readiness Probes**: `02-readiness-probes.md`
  - HTTP, TCP, and exec probe types for readiness checking
  - Service endpoint management and traffic routing
  - Slow-starting applications and initialization delays
  - Load balancer integration and service discovery
  - Environment: k3s bare metal

## Pending Tasks 📋

### Configuration Scenarios (Next Priority)

#### Configuration/Secrets (2 scenarios)

#### Configuration/Probes (4 scenarios)
- [ ] **Startup Probes**: `03-startup-probes.md`
  - Managing slow-starting containers (databases, large applications)
  - Startup probe interaction with liveness/readiness probes
  - Legacy application modernization patterns
  - Container initialization sequence management
  - Environment: k3s bare metal
- [ ] **Probe Types and Configuration**: `04-probe-types-and-configuration.md`
  - HTTP probes with custom headers and paths
  - TCP socket probes for network service checking
  - Exec probes with custom commands and scripts
  - gRPC probes for modern application protocols
  - Probe timing configuration (initialDelaySeconds, periodSeconds, timeoutSeconds)
  - Combined probe strategies and best practices
  - Environment: k3s bare metal

#### Configuration/ResourceManagement (3 scenarios)
- [ ] **Requests and Limits**: `01-requests-and-limits.md`
  - CPU and memory resource specification (units, syntax)
  - Resource requests for scheduling and guarantees
  - Resource limits for enforcement and protection
  - Practical applications with different resource patterns
  - Node resource allocation and capacity planning
  - Environment: k3s bare metal
- [ ] **Quality of Service Classes**: `02-quality-of-service-classes.md`
  - Guaranteed QoS (requests == limits for all resources)
  - Burstable QoS (requests < limits or partial resource specification)
  - BestEffort QoS (no requests or limits specified)
  - Pod eviction order during resource pressure
  - QoS impact on scheduling and node resource management
  - Environment: k3s bare metal
- [ ] **Resource Quotas and Limits**: `03-resource-quotas-and-limits.md`
  - Namespace-level ResourceQuota objects
  - LimitRange objects for default and maximum resource constraints
  - Resource quota enforcement and admission control
  - Multi-tenant cluster resource management
  - Resource monitoring and capacity planning
  - Environment: k3s bare metal

#### Configuration/ClusterAccess (2 scenarios)
- [ ] **Kubeconfig Management**: `01-kubeconfig-management.md`
  - Kubeconfig file structure (clusters, users, contexts)
  - Authentication methods (certificates, tokens, username/password)
  - Multiple kubeconfig file merging and precedence
  - kubectl config commands for configuration management
  - Environment: k3s bare metal
- [ ] **Multiple Cluster Contexts**: `02-multiple-cluster-contexts.md`
  - Managing development, staging, and production cluster access
  - Context switching and namespace configuration
  - User and cluster credential management
  - Kubeconfig troubleshooting and validation
  - Environment: k3s bare metal + DigitalOcean for multi-cluster scenarios

### Storage/StorageClass Scenarios

**All Storage/StorageClass scenarios completed! ✅**

## Future Scenario Categories (Not Started)

### Workloads & Scheduling (15%)
- [ ] Pod scheduling and affinity rules
- [ ] Resource limits and requests
- [ ] DaemonSets and StatefulSets
- [ ] Jobs and CronJobs

### Services & Networking (20%)
- [ ] Service types and endpoints
- [ ] Ingress controllers and rules
- [ ] Network policies
- [ ] DNS and service discovery

### Cluster Architecture (25%)
- [ ] RBAC and security contexts
- [ ] Cluster upgrades
- [ ] etcd backup and restore
- [ ] Node management

### Troubleshooting (30%)
- [ ] Pod and node troubleshooting
- [ ] Application debugging
- [ ] Cluster component issues
- [ ] Log analysis and monitoring

## Notes for Scenario Creation
- **Environment**: Primary focus on k3s bare metal, with Digital Ocean scenarios for cloud-specific features
- **Quality Standards**: Each scenario must include exact task specifications, practical applications, and comprehensive verification
- **Exam Relevance**: Avoid deprecated features, focus on current CKA exam topics
- **Time Management**: Include realistic time limits matching exam conditions

## Current Priority
**Storage domain completed!** ✅ 

**Storage/StorageClass scenarios**: 6 scenarios covering basic concepts through advanced CSI features
**Storage/VolumeSnapshots scenarios**: 2 scenarios covering snapshot and cloning functionality

**Next Priority: Configuration domain** 📋
- **Total scenarios planned**: 15 scenarios across 5 subdirectories
- **High Priority**: Probes (4 scenarios) - critical for application health and reliability
- **Core Topics**: ConfigMaps (3), Secrets (3), ResourceManagement (3), ClusterAccess (2)
- **Environment**: Primarily k3s bare metal, with DigitalOcean for multi-cluster scenarios
