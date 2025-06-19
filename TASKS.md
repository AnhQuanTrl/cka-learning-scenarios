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

### Project Setup
- [x] **CLAUDE.md**: Created with project purpose and scenario quality standards
- [x] **Scenario Quality Standards**: Defined clear task instructions, practical applications, and verification requirements

## Pending Tasks 📋

### Storage/StorageClass Scenarios

- [ ] **Volume Binding Mode Scenario**: `04-volume-binding-mode.md`
  - Compare Immediate vs WaitForFirstConsumer
  - Multi-node scenarios showing topology awareness
  - Understanding when PV creation occurs

- [ ] **NFS CSI Driver vs Subdir Provisioner**: `05-nfs-storage-comparison.md`
  - Set up and configure NFS CSI Driver StorageClass
  - Set up and configure NFS Subdir External Provisioner StorageClass
  - Compare volume isolation, security, and features between both approaches
  - Deploy applications using both provisioners to demonstrate differences
  - Environment: k3s bare metal with homelab NFS server

- [ ] **Digital Ocean CSI Scenario**: `06-digital-ocean-csi.md`
  - Cloud-specific StorageClass configuration
  - Volume expansion: StorageClass with expansion enabled, demonstrate expanding PVC size dynamically, verify application can access expanded storage
  - CSI volume snapshots and restore
  - Cost-effective cluster setup and teardown instructions

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
Focus on completing Storage/StorageClass scenarios before moving to other domains, as this provides a solid foundation for understanding Kubernetes storage concepts.