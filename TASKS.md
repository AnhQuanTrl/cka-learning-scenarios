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

### Configuration/Kustomize
- [x] **Kustomize Bases and Overlays**: `01-kustomize-bases-and-overlays.md`
  - Kustomize structure with bases and environment-specific overlays
  - Patch strategies using strategic merge and JSON patches
  - ConfigMap generation with literals and files
  - Resource transformations (labels, annotations, prefixes, namespaces)
  - Multi-environment deployment patterns (dev, staging, production)
  - Environment: k3s bare metal
- [x] **Kustomize Components and Advanced Transformations**: `02-kustomize-components-and-transformations.md`
  - Reusable component creation with kind: Component
  - Modular configuration packages for multi-tenant SaaS platform
  - Selective feature enablement (external database, LDAP, monitoring, premium features)
  - Advanced transformations and multi-base compositions
  - Component patches and resource generation patterns
  - Environment: k3s bare metal

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

### Security/Authorization
- [x] **Directory Structure**: Create `Security/Authorization/` folder structure
- [x] **RBAC Fundamentals**: `01-rbac-fundamentals.md`
  - Role vs ClusterRole creation and scope
  - RoleBinding vs ClusterRoleBinding configuration
  - Subject types (User, Group, ServiceAccount)
  - Resource and verb permission mapping
  - Namespace-level vs cluster-level authorization
  - Environment: k3s bare metal
- [x] **RBAC Advanced Patterns**: `02-rbac-advanced-patterns.md`
  - Aggregated ClusterRoles and permission inheritance
  - Built-in system roles and their usage
  - Multi-tenant RBAC design patterns
  - Permission escalation prevention
  - RBAC best practices and security considerations
  - Environment: k3s bare metal
- [x] **Authorization Troubleshooting**: `03-authorization-troubleshooting.md`
  - kubectl auth can-i permission testing
  - RBAC decision flow and debugging
  - Common authorization failures and solutions
  - ServiceAccount impersonation and testing
  - Permission debugging workflows
  - Environment: k3s bare metal

## Completed Tasks ✅

### Security/AdmissionControl
- [x] **Directory Structure**: Created `Security/AdmissionControl/` folder structure
- [x] **Pod Security Standards**: `01-pod-security-standards.md`
  - Privileged, Baseline, Restricted security profiles
  - Pod Security Admission controller configuration
  - Namespace-level security policy enforcement
  - Security policy violations and remediation
  - Migration from deprecated PodSecurityPolicy
  - Environment: k3s bare metal
- [x] **Security Contexts and Capabilities**: `02-security-contexts-capabilities.md`
  - Container and Pod security context configuration
  - runAsUser, runAsGroup, fsGroup settings
  - Linux capabilities management (add/drop)
  - Non-root container execution
  - Filesystem permissions and access control
  - Environment: k3s bare metal

## Pending Tasks ⏳

### Security/NetworkSecurity
- [x] **Directory Structure**: Created `Security/NetworkSecurity/` folder structure
- [x] **Network Policy Fundamentals**: `01-network-policy-fundamentals.md`
  - Ingress and egress network policy rules
  - Pod selector and namespace selector usage
  - Port and protocol-specific traffic control
  - Default deny vs allow policy patterns
  - Multi-tier application with frontend, backend, and database layers
  - Environment: k3s bare metal with Calico CNI
- [x] **Advanced Network Isolation**: `02-advanced-network-isolation.md`
  - Multi-environment isolation (dev, staging, prod)
  - Complex microservices communication patterns
  - External API access control and security
  - NetworkPolicy troubleshooting and debugging techniques
  - Environment: k3s bare metal with Calico CNI

### Security/TLSAndCertificates
- [x] **Directory Structure**: Created `Security/TLSAndCertificates/` folder structure
- [x] **TLS Configuration and Management**: `01-tls-configuration-management.md`
  - Cluster TLS certificate management and examination using OpenSSL
  - API server TLS configuration inspection and validation
  - kubeadm certificate lifecycle management and expiration monitoring
  - Certificate rotation procedures with backup and recovery
  - TLS troubleshooting and debugging techniques
  - Environment: Killercoda Ubuntu Playground with kubeadm cluster
- [x] **Secret Management for TLS**: `02-secret-management-tls.md`
  - TLS Secret creation methods (kubectl, files, YAML manifests)
  - Certificate consumption patterns (volume mounts, environment variables)
  - Secret rotation with zero-downtime rolling deployments
  - Ingress TLS termination with Traefik integration
  - Certificate lifecycle automation using Jobs and CronJobs
  - Environment: k3s bare metal

### Security/ControlPlane 
- [x] **Directory Structure**: Created `Security/ControlPlane/` folder structure
- [x] **etcd Encryption at Rest**: `01-etcd-encryption-at-rest.md`
  - EncryptionConfiguration resource with multiple providers (AES-CBC, AES-GCM, identity)
  - API server encryption configuration and restart procedures
  - Secret and ConfigMap encryption verification using etcdctl
  - Encryption key rotation workflow with zero-downtime procedures
  - Direct etcd access for encryption validation and troubleshooting
  - Environment: Killercoda Ubuntu Playground with kubeadm cluster
- [x] **API Server Security Configuration**: `02-api-server-security-configuration.md`
  - Multi-layered authentication methods (certificates, tokens) and security parameters
  - RBAC authorization hardening with least-privilege access patterns
  - Security-focused admission controllers (NodeRestriction, PodSecurity, ResourceQuota)
  - Comprehensive audit logging with policy configuration for compliance
  - TLS hardening, cipher suite configuration, and network security parameters
  - Environment: Killercoda Ubuntu Playground with kubeadm cluster
- [x] **Control Plane Component Communication**: `03-control-plane-component-communication.md`
  - Component-to-component TLS communication
  - etcd client certificate authentication
  - Kubelet API server authentication and authorization
  - Control plane network security and firewall rules
  - Control plane backup and restore security considerations
  - Environment: Killercoda kubeadm cluster

### Services/DNS
- [x] **Directory Structure**: Created `Services/DNS/` folder structure
- [x] **CoreDNS Configuration and Management**: `01-coredns-configuration-management.md`
  - CoreDNS deployment architecture and components
  - ConfigMap customization and Corefile configuration
  - Upstream DNS forwarding (8.8.8.8, custom nameservers)
  - Plugin configuration (errors, health, kubernetes, forward, cache)
  - CoreDNS scaling and resource management
  - Environment: k3s bare metal
- [x] **DNS Service Discovery and Resolution**: `02-dns-service-discovery-resolution.md`
  - Service DNS naming conventions (my-svc.my-namespace.svc.cluster.local)
  - Cross-namespace service resolution patterns
  - Headless services and pod DNS records
  - DNS policies (Default, ClusterFirst, ClusterFirstWithHostNet, None)
  - Custom DNS configuration with dnsConfig
  - Environment: k3s bare metal
- [x] **DNS Troubleshooting and Debugging**: `03-dns-troubleshooting-debugging.md`
  - DNS resolution failure diagnosis and repair
  - CoreDNS pod status and log analysis
  - nslookup and dig testing from pods
  - /etc/resolv.conf validation and configuration
  - DNS loop detection and resolution
  - Common DNS issues (systemd-resolved conflicts, search domain limits)
  - Environment: k3s bare metal

### Troubleshooting/ClusterComponents - API Server
- [x] **API Server Configuration Failures**: `01-api-server-configuration-failures.md`
  - Break: Change `--etcd-servers` to `--etcd-server` in kube-apiserver manifest
  - Break: Use wrong etcd endpoints or invalid URLs
  - Break: Modify service account key file path to non-existent location
  - Break: Change API server bind address to invalid IP
  - Symptoms: API server crash loops, kubectl commands fail, cluster inaccessible
  - Recovery: Static pod manifest troubleshooting and configuration validation
  - Environment: Killercoda kubeadm cluster
- [x] **API Server Certificate and TLS Issues**: `02-api-server-certificate-tls-issues.md`
  - Break: Replace API server certificate with expired or invalid cert
  - Break: Modify certificate file paths in kube-apiserver manifest
  - Break: Change TLS cipher suites to incompatible values
  - Break: Modify client CA file path or use wrong CA bundle
  - Symptoms: TLS handshake failures, certificate validation errors, kubectl auth issues
  - Recovery: Certificate validation, regeneration, and path correction
  - Environment: Killercoda kubeadm cluster
- [x] **API Server Storage and Encryption Issues**: `03-api-server-storage-encryption-issues.md`
  - Break: Configure invalid encryption provider in EncryptionConfiguration
  - Break: Use non-existent encryption key file path
  - Break: Modify audit log path to read-only location
  - Break: Configure invalid admission controllers
  - Symptoms: API server startup failures, resource creation errors, encryption failures
  - Recovery: Configuration validation and encryption troubleshooting
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - etcd
- [x] **etcd Service and Connectivity Issues**: `01-etcd-service-connectivity-issues.md`
  - Break: Stop etcd service using systemctl
  - Break: Modify etcd data directory to non-existent path
  - Break: Change etcd listen addresses to invalid IPs
  - Break: Modify etcd cluster member URLs incorrectly
  - Symptoms: API server cannot connect to etcd, cluster operations fail
  - Recovery: etcd service restoration and configuration validation
  - Environment: Killercoda kubeadm cluster
- [x] **etcd Certificate and Authentication Issues**: `02-etcd-certificate-authentication-issues.md`
  - Break: Replace etcd server certificate with invalid cert
  - Break: Modify etcd client certificate paths in API server config
  - Break: Change etcd peer certificate configuration
  - Break: Use wrong CA bundle for etcd client authentication
  - Symptoms: TLS handshake failures, authentication errors, cluster communication breakdown
  - Recovery: Certificate troubleshooting and etcd client configuration
  - Environment: Killercoda kubeadm cluster
- [x] **etcd Data Corruption and Recovery**: `03-etcd-data-corruption-recovery.md`
  - Break: Simulate disk full scenario for etcd data directory
  - Break: Manually corrupt etcd database files
  - Break: Delete etcd member from cluster configuration
  - Break: Modify etcd cluster token causing member mismatch
  - Symptoms: Data inconsistency, cluster split-brain, member join failures
  - Recovery: etcd backup restoration and cluster rebuild procedures
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - Controller Manager
- [x] **Controller Manager Configuration Issues**: `01-controller-manager-configuration-issues.md`
  - Break: Modify kubeconfig path to non-existent file
  - Break: Change service account private key file path
  - Break: Configure invalid cluster signing certificate paths
  - Break: Modify root CA file path incorrectly
  - Symptoms: Controllers not reconciling, certificate signing requests failing, service accounts not working
  - Recovery: Configuration validation and certificate path correction
  - Environment: Killercoda kubeadm cluster
- [x] **Controller Manager Authentication and Authorization**: `02-controller-manager-auth-issues.md`
  - Break: Use expired certificate in controller manager kubeconfig
  - Break: Modify controller manager service account permissions
  - Break: Change cluster role bindings for system:kube-controller-manager
  - Break: Configure invalid authentication credentials
  - Symptoms: RBAC permission errors, controller reconciliation failures, authentication failures
  - Recovery: Certificate renewal and RBAC troubleshooting
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - Scheduler
- [x] **Scheduler Configuration and Policy Issues**: `01-scheduler-configuration-policy-issues.md`
  - Break: Modify scheduler kubeconfig path to invalid location
  - Break: Configure invalid scheduler policy file
  - Break: Change scheduler bind address to unreachable IP
  - Break: Modify leader election configuration incorrectly
  - Symptoms: Pods stuck in Pending state, scheduling decisions not made, multiple scheduler instances
  - Recovery: Scheduler configuration validation and policy troubleshooting
  - Environment: Killercoda kubeadm cluster
- [x] **Scheduler Authentication and Performance Issues**: `02-scheduler-auth-performance-issues.md`
  - Break: Use invalid certificate in scheduler kubeconfig
  - Break: Configure scheduler with insufficient RBAC permissions
  - Break: Modify scheduler resource limits causing OOM
  - Break: Configure invalid metrics bind address
  - Symptoms: Authentication failures, scheduling delays, scheduler crashes, performance degradation
  - Recovery: Authentication troubleshooting and resource optimization
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - kubelet
- [x] **kubelet Service and Configuration Issues**: `01-kubelet-service-configuration-issues.md`
  - Break: Stop kubelet service on worker nodes
  - Break: Modify kubelet kubeconfig to use wrong cluster endpoint
  - Break: Change kubelet configuration file path to non-existent location
  - Break: Configure invalid container runtime endpoint
  - Symptoms: Node NotReady status, pods not starting, container runtime errors
  - Recovery: kubelet service restoration and configuration validation
  - Environment: Killercoda kubeadm cluster
- [x] **kubelet Certificate and Network Issues**: `02-kubelet-certificate-network-issues.md`
  - Break: Use expired certificate in kubelet kubeconfig
  - Break: Modify kubelet client certificate paths
  - Break: Configure wrong cluster DNS in kubelet config
  - Break: Change kubelet network plugin configuration
  - Symptoms: Node authentication failures, DNS resolution issues, network connectivity problems
  - Recovery: Certificate troubleshooting and network configuration validation
  - Environment: Killercoda kubeadm cluster
- [x] **kubelet Resource and Container Runtime Issues**: `03-kubelet-resource-container-runtime-issues.md`
  - Break: Configure invalid container runtime socket path
  - Break: Modify kubelet resource limits causing conflicts
  - Break: Change container log path to read-only location
  - Break: Configure invalid cgroup driver settings
  - Symptoms: Container runtime errors, resource allocation failures, logging issues
  - Recovery: Container runtime troubleshooting and resource configuration
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - kube-proxy
- [ ] **kube-proxy Service and Network Configuration**: `01-kube-proxy-service-network-config.md`
  - Break: Stop kube-proxy DaemonSet or service
  - Break: Modify kube-proxy kubeconfig with wrong cluster endpoint
  - Break: Configure invalid cluster CIDR in kube-proxy config
  - Break: Change kube-proxy mode to unsupported option
  - Symptoms: Service connectivity failures, load balancing issues, network routing problems
  - Recovery: kube-proxy service restoration and network configuration validation
  - Environment: Killercoda kubeadm cluster
- [ ] **kube-proxy iptables and Performance Issues**: `02-kube-proxy-iptables-performance-issues.md`
  - Break: Manually corrupt iptables rules managed by kube-proxy
  - Break: Configure kube-proxy with insufficient system resources
  - Break: Modify kube-proxy authentication credentials
  - Break: Change kube-proxy metrics bind address to conflicting port
  - Symptoms: iptables rule inconsistencies, performance degradation, authentication failures
  - Recovery: iptables troubleshooting and performance optimization
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - Network Components
- [ ] **CNI Plugin Configuration and Installation Issues**: `01-cni-plugin-configuration-issues.md`
  - Break: Remove or corrupt CNI plugin binaries
  - Break: Modify CNI configuration files with invalid JSON
  - Break: Configure conflicting network CIDR ranges
  - Break: Remove CNI configuration directory permissions
  - Symptoms: Pod networking failures, IP allocation issues, container creation errors
  - Recovery: CNI plugin installation and configuration troubleshooting
  - Environment: Killercoda kubeadm cluster
- [ ] **CoreDNS and Service Discovery Issues**: `02-coredns-service-discovery-issues.md`
  - Break: Modify CoreDNS ConfigMap with invalid configuration
  - Break: Change CoreDNS service IP to conflicting address
  - Break: Configure CoreDNS with insufficient resources causing OOM
  - Break: Modify CoreDNS upstream servers to unreachable addresses
  - Symptoms: DNS resolution failures, service discovery issues, DNS query timeouts
  - Recovery: CoreDNS configuration validation and service discovery troubleshooting
  - Environment: Killercoda kubeadm cluster

### Troubleshooting/ClusterComponents - Multi-Component Failures
- [ ] **Cascading Component Failures**: `01-cascading-component-failures.md`
  - Break multiple components simultaneously to simulate real disaster scenarios
  - Break: etcd + API server certificate issues
  - Break: Controller manager + Scheduler authentication problems
  - Break: kubelet + kube-proxy network configuration issues
  - Symptoms: Complete cluster dysfunction, complex interdependent failures
  - Recovery: Systematic troubleshooting methodology and component isolation
  - Environment: Killercoda kubeadm cluster
- [ ] **Resource Exhaustion and Cluster Degradation**: `02-resource-exhaustion-cluster-degradation.md`
  - Break: Simulate disk full on etcd and control plane nodes
  - Break: Memory exhaustion on control plane components
  - Break: Network bandwidth saturation and connectivity issues
  - Break: Certificate expiration across multiple components
  - Symptoms: Cluster performance degradation, partial functionality loss, resource conflicts
  - Recovery: Resource management and cluster health restoration
  - Environment: Killercoda kubeadm cluster

## CKA Domain

### Cluster Architecture, Installation & Configuration (25%)
- [ ] RBAC and security contexts
- [ ] Cluster upgrades
- [ ] Node management
- [x] Helm and Kustomize for deployment management (2 Kustomize scenarios completed)
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
- [ ] StorageClass scenarios (6 scenarios completed)
- [ ] VolumeSnapshots scenarios (2 scenarios completed)
- [ ] Dynamic volume provisioning (enhanced focus in 2025)
- [ ] Volume types, access modes, and reclaim policies

### Troubleshooting (30%)
**Critical Domain: Highest percentage of CKA exam content**


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
