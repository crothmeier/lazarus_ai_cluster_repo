# System Baseline: phx-hypervisor26 (2025-05-18)

## CPU / Memory / NUMA

- **CPU**: Intel(R) Xeon(R) Silver 4210R CPU @ 2.40GHz
  - 2 Sockets, 10 Cores per socket, 2 Threads per core (40 total threads)
  - Architecture: x86_64
- **Memory**: 94GB total, 91GB available
- **NUMA Configuration**:
  - Node 0: 47971 MB, CPUs 0-9, 20-29
  - Node 1: 48330 MB, CPUs 10-19, 30-39

## GPUs

- NVIDIA L4 (24GB)
  - Driver Version: 550.144.03
  - CUDA Version: 12.4
  - Temperature: 35°C
  - Power Usage: 11W / 72W

## Storage & ZFS

- ZFS Pool:
  - bulk: 2.17TB size, 209MB used, ONLINE
- Disks:
  - sda: ZFS member (bulk)
  - sdc: Boot drive (1GB EFI + 845.7GB root)
  - nvme0n1, nvme1n1: ZFS member (tank)

## Network

- eno5np0: 10.0.10.6/24 (Primary)
- eno6np1: 192.168.66.20/24
- docker0: 172.17.0.1/16 (DOWN)

## Sensors / IPMI

- CPU Temperatures:
  - Package 0: 35.0°C (Critical: 98.0°C)
  - Package 1: 39.0°C (Critical: 98.0°C)
- NVMe Temperatures:
  - nvme0: 35.9°C
  - nvme1: 29.9°C
- Power Consumption: 179.00 W

## Services (running / failed)

- Failed Units:
  - systemd-networkd-wait-online.service

## Backup (restic snapshot + restore test)

- RESTIC_REPO environment variable: Not set
- /etc/restic/env: Not found
- ~/.restic_env: Not found
- **Status**: Cannot perform backup/restore tests  

## Observability (Prometheus target state)

- /etc/prometheus/prometheus.yml: Not found
- Example configuration created at: ~/baseline_logs/2025-05-18/prometheus-config.yml
- **Status**: Prometheus not configured  

## Firmware / Drivers

- BIOS Version: U32
  - Newer version available: U33  
  - Downloaded to: ~/baseline_logs/2025-05-18/bios_update.txt
- NVIDIA Driver: 550.144.03
  - Newer version available: 555.52  
  - Downloaded to: ~/baseline_logs/2025-05-18/nvidia_driver_update.txt

## ™ Remediation Log

1. Created example Prometheus configuration for phx-hypervisor26
2. Found newer BIOS available (U33)
3. Found newer NVIDIA driver available (555.52)
4. RESTIC_REPO environment variable not found
5. Found failed systemd unit: systemd-networkd-wait-online.service