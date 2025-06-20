# CKA Learning Scenarios - Task Tracking

## Project Status Overview
This document tracks the progress of creating CKA exam preparation scenarios based on Kubernetes concepts.

## CKA Exam 2025 Updates 🚀
**Effective Date**: February 18, 2025 (based on exam date, not purchase date)
**Kubernetes Version**: v1.32

### Domain Percentages (Updated 2025):
- **Cluster Architecture, Installation & Configuration**: 25%
- **Services & Networking**: 20%
- **Workloads & Scheduling**: 15%
- **Storage**: 10%
- **Troubleshooting**: 30%

### Key Changes:
- **REMOVED**: "Provision underlying infrastructure to deploy a Kubernetes cluster" (reflects managed platform reality)
- **ADDED**: Gateway API for Ingress traffic management
- **ADDED**: Helm and Kustomize for deployment management
- **ADDED**: Extension interfaces (CNI, CSI, CRI)
- **ENHANCED**: Dynamic volume provisioning focus in Storage domain
- **ENHANCED**: Network services and connectivity in Troubleshooting domain

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
- [x] **Startup Probes**: `03-startup-probes.md`
  - Managing slow-starting containers (databases, large applications)
  - Startup probe interaction with liveness/readiness probes
  - Legacy application modernization patterns
  - Container initialization sequence management
  - Environment: k3s bare metal
- [x] **Probe Types and Configuration**: `04-probe-types-and-configuration.md`
  - HTTP probes with custom headers and paths
  - TCP socket probes for network service checking
  - Exec probes with custom commands and scripts
  - gRPC probes for modern application protocols
  - Probe timing configuration (initialDelaySeconds, periodSeconds, timeoutSeconds)
  - Combined probe strategies and best practices
  - Environment: k3s bare metal

### Configuration/ResourceManagement
- [x] **Requests and Limits**: `01-requests-and-limits.md`
  - CPU and memory resource specification (units, syntax)
  - Resource requests for scheduling and guarantees
  - Resource limits for enforcement and protection
  - Practical applications with different resource patterns
  - Node resource allocation and capacity planning
  - Environment: k3s bare metal
- [x] **Quality of Service Classes**: `02-quality-of-service-classes.md`
  - Guaranteed QoS (requests == limits for all resources)
  - Burstable QoS (requests < limits or partial resource specification)
  - BestEffort QoS (no requests or limits specified)
  - Pod eviction order during resource pressure
  - QoS impact on scheduling and node resource management
  - Environment: k3s bare metal
- [x] **Resource Quotas and Limits**: `03-resource-quotas-and-limits.md`
  - Namespace-level ResourceQuota objects
  - LimitRange objects for default and maximum resource constraints
  - Resource quota enforcement and admission control
  - Multi-tenant cluster resource management
  - Resource monitoring and capacity planning
  - Environment: k3s bare metal

### Configuration/ClusterAccess
- [x] **Kubeconfig Management**: `01-kubeconfig-management.md`
  - Kubeconfig file structure (clusters, users, contexts)
  - Authentication methods (certificates, tokens, username/password)
  - Multiple kubeconfig file merging and precedence
  - kubectl config commands for configuration management
  - Environment: k3s bare metal
- [x] **Multiple Cluster Contexts**: `02-multiple-cluster-contexts.md`
  - Managing development, staging, and production cluster access
  - Context switching and namespace configuration
  - User and cluster credential management
  - Kubeconfig troubleshooting and validation
  - Environment: k3s and minikube

### Security/Authentication
- [x] **Directory Structure**: Create `Security/Authentication/` folder structure
- [x] **Service Account Authentication**: `01-service-account-authentication.md`
  - Service Account token authentication methods
  - Automatic vs manual token mounting
  - JWT token validation and TokenRequest API
  - Service Account token lifecycle management
  - Cross-namespace service account authentication
  - Environment: k3s bare metal
- [x] **Certificate-based Authentication**: `02-certificate-based-authentication.md`
  - X.509 client certificate authentication
  - Certificate Signing Request (CSR) workflow
  - User certificate creation and management
  - Certificate-based kubeconfig configuration
  - Certificate rotation and renewal processes
  - Environment: k3s bare metal

## Pending Tasks 📋

### Security/Authentication
- [ ] **Certificate-based Authentication**: `02-certificate-based-authentication.md`
  - X.509 client certificate authentication
  - Certificate Signing Request (CSR) workflow
  - User certificate creation and management
  - Certificate-based kubeconfig configuration
  - Certificate rotation and renewal processes
  - Environment: k3s bare metal

### Security/Authorization
- [ ] **Directory Structure**: Create `Security/Authorization/` folder structure
- [ ] **RBAC Fundamentals**: `01-rbac-fundamentals.md`
  - Role vs ClusterRole creation and scope
  - RoleBinding vs ClusterRoleBinding configuration
  - Subject types (User, Group, ServiceAccount)
  - Resource and verb permission mapping
  - Namespace-level vs cluster-level authorization
  - Environment: k3s bare metal
- [ ] **RBAC Advanced Patterns**: `02-rbac-advanced-patterns.md`
  - Aggregated ClusterRoles and permission inheritance
  - Built-in system roles and their usage
  - Multi-tenant RBAC design patterns
  - Permission escalation prevention
  - RBAC best practices and security considerations
  - Environment: k3s bare metal
- [ ] **Authorization Troubleshooting**: `03-authorization-troubleshooting.md`
  - kubectl auth can-i permission testing
  - RBAC decision flow and debugging
  - Common authorization failures and solutions
  - Audit logs for authorization events
  - Permission debugging workflows
  - Environment: k3s bare metal

### Security/AdmissionControl
- [ ] **Directory Structure**: Create `Security/AdmissionControl/` folder structure
- [ ] **Pod Security Standards**: `01-pod-security-standards.md`
  - Privileged, Baseline, Restricted security profiles
  - Pod Security Admission controller configuration
  - Namespace-level security policy enforcement
  - Security policy violations and remediation
  - Migration from deprecated PodSecurityPolicy
  - Environment: k3s bare metal
- [ ] **Security Contexts and Capabilities**: `02-security-contexts-capabilities.md`
  - Container and Pod security context configuration
  - runAsUser, runAsGroup, fsGroup settings
  - Linux capabilities management (add/drop)
  - Non-root container execution
  - Filesystem permissions and access control
  - Environment: k3s bare metal

### Security/NetworkSecurity
- [ ] **Directory Structure**: Create `Security/NetworkSecurity/` folder structure
- [ ] **Network Policy Fundamentals**: `01-network-policy-fundamentals.md`
  - Ingress and egress network policy rules
  - Pod selector and namespace selector usage
  - Port and protocol-specific traffic control
  - Default deny vs allow policy patterns
  - Network policy rule precedence and ordering
  - Environment: k3s bare metal with Calico CNI
- [ ] **Advanced Network Isolation**: `02-advanced-network-isolation.md`
  - Multi-tier application network segmentation
  - Namespace-based network isolation
  - External traffic control and internet access
  - Network policy troubleshooting and debugging
  - Service mesh integration considerations
  - Environment: k3s bare metal with Calico CNI

### Security/TLSAndCertificates
- [ ] **Directory Structure**: Create `Security/TLSAndCertificates/` folder structure
- [ ] **TLS Configuration and Management**: `01-tls-configuration-management.md`
  - Cluster TLS certificate management
  - API server TLS configuration
  - kubelet TLS bootstrapping
  - Certificate rotation and renewal
  - TLS troubleshooting and validation
  - Environment: k3s bare metal
- [ ] **Secret Management for TLS**: `02-secret-management-tls.md`
  - TLS Secret creation and management
  - Certificate and key storage patterns
  - Secret rotation for TLS certificates
  - Ingress TLS configuration with secrets
  - Certificate lifecycle automation
  - Environment: k3s bare metal

### Security/ControlPlane 
- [ ] **Directory Structure**: Create `Security/ControlPlane/` folder structure
- [ ] **etcd Encryption at Rest**: `01-etcd-encryption-at-rest.md`
  - EncryptionConfiguration resource creation
  - Encryption provider configuration (AES-CBC, AES-GCM, Secretbox)
  - API server encryption configuration and restart
  - Secret encryption verification and key rotation
  - etcd backup encryption and recovery scenarios
  - Environment: Killercoda kubeadm cluster
- [ ] **API Server Security Configuration**: `02-api-server-security-configuration.md`
  - API server secure configuration parameters
  - Authentication and authorization configuration
  - Admission controller configuration and custom policies
  - Audit logging configuration and policy management
  - API server TLS and certificate management
  - Environment: Killercoda kubeadm cluster
- [ ] **Control Plane Component Communication**: `03-control-plane-component-communication.md`
  - Component-to-component TLS communication
  - etcd client certificate authentication
  - Kubelet API server authentication and authorization
  - Control plane network security and firewall rules
  - Control plane backup and restore security considerations
  - Environment: Killercoda kubeadm cluster

## Future Scenario Categories (Not Started)

### Cluster Architecture, Installation & Configuration (25%)
- [ ] RBAC and security contexts
- [ ] Cluster upgrades
- [ ] Node management
- [ ] Helm and Kustomize for deployment management
- [ ] Extension interfaces (CNI, CSI, CRI)

### Services & Networking (20%)
- [ ] Service types and endpoints
- [ ] Ingress controllers and rules
- [ ] Gateway API for Ingress traffic management (NEW in 2025)
- [ ] Network policies
- [ ] DNS and service discovery

### Workloads & Scheduling (15%)
- [ ] Pod scheduling and affinity rules
- [ ] Resource limits and requests
- [ ] DaemonSets and StatefulSets
- [ ] Jobs and CronJobs

### Storage (10%)
- [x] StorageClass scenarios (6 scenarios completed)
- [x] VolumeSnapshots scenarios (2 scenarios completed)
- [ ] Dynamic volume provisioning (enhanced focus in 2025)
- [ ] Volume types, access modes, and reclaim policies

### Troubleshooting (30%)
- [ ] Pod and node troubleshooting
- [ ] Application debugging
- [ ] Cluster component issues
- [ ] Network services and connectivity (enhanced focus in 2025)
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
