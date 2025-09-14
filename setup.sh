#!/bin/bash
# setup.sh - Install Ansible collections for BitHardened

set -e

echo "Installing required Ansible collections..."

# Install required collections
ansible-galaxy collection install \
    bitwarden.secrets \
    community.general \
    community.docker

echo "Ansible collections installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Configure your inventory file"
echo "  2. Update vars.yml with your settings" 
echo "  3. Run a playbook with: ansible-playbook -i inventory playbooks/<some playbook>.yml"