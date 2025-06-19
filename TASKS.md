# CKA Learning Scenarios - Task Tracking

## Project Status Overview
This document tracks the progress of creating CKA exam preparation scenarios based on Kubernetes concepts.

## Completed Tasks ✅

### Storage/StorageClass
- [x] **Directory Structure**: Created `Storage/StorageClass/` folder structure
- [x] **Basic StorageClass Creation**: `01-basic-storageclass-creation.md`
  - Covers StorageClass creation, default StorageClass configuration
  - Includes StatefulSet and Deployment consuming different StorageClasses
  - Comprehensive verification commands and expected results

### Project Setup
- [x] **CLAUDE.md**: Created with project purpose and scenario quality standards
- [x] **Scenario Quality Standards**: Defined clear task instructions, practical applications, and verification requirements

## Pending Tasks 📋

### Storage/StorageClass Scenarios
- [ ] **Dynamic Provisioning Scenario**: `02-dynamic-provisioning.md`
  - Focus on automatic PV creation from StorageClass
  - Multiple PVCs with different storage requests
  - Verification of dynamic volume creation

- [ ] **Volume Expansion Scenario**: `03-volume-expansion.md`
  - StorageClass with volume expansion enabled
  - Demonstrate expanding PVC size dynamically
  - Verify application can access expanded storage

- [ ] **Reclaim Policy Scenario**: `04-reclaim-policy.md`
  - Compare Retain vs Delete reclaim policies
  - Delete PVCs and observe PV behavior
  - Manual PV cleanup procedures

- [ ] **Volume Binding Mode Scenario**: `05-volume-binding-mode.md`
  - Compare Immediate vs WaitForFirstConsumer
  - Multi-node scenarios showing topology awareness
  - Understanding when PV creation occurs

- [ ] **Digital Ocean CSI Scenario**: `06-digital-ocean-csi.md`
  - Cloud-specific StorageClass configuration
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