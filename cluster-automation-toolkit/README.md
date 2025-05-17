# Cluster Automation Toolkit

Lightweight scripts for SSH key management, SSH configs, and dynamic Ansible inventory.

## Quick start

```bash
git clone <repo>
cd cluster-automation-toolkit
cp templates/cluster_hosts.example ~/.ssh/cluster_hosts
./cluster_key_sync.sh          # push keys
./inventory.py --list | jq     # test inventory
```
