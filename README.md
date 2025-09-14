# BitHardened

An Ansible automation suite for deploying `Vaultwarden` password manager on hardened Ubuntu servers with mutual TLS (mTLS) authentication.

## Overview

BitHardened provides a complete infrastructure-as-code solution that transforms a fresh Ubuntu server into a security-hardened `Vaultwarden` instance. The deployment includes system hardening, PKI certificate authority setup, and application deployment with client certificate authentication.

## Features

- **System Hardening**: 
  - SSH configuration: Disables root login, password authentication, changes default port to custom value
  - Firewall: UFW with default deny policies for both incoming and outgoing traffic
    - Incoming: Only custom SSH port, HTTP (80), and HTTPS (443) allowed
    - Outgoing: Only HTTP/HTTPS (80/443), DNS (53), and NTP (123) allowed
  - Kernel hardening: ASLR enabled, IP spoofing protection, SYN flood protection, ICMP redirect blocking
  - User management: Creates non-root sudo user, removes default ubuntu user, implements session timeout
  - Automatic security updates via unattended-upgrades
  - AppArmor mandatory access controls enabled
  - System auditing with auditd monitoring file changes, privilege escalation, and login events

- **Modular Design**: 
  - Three independent playbooks: hardening (security baseline), CA setup (PKI infrastructure), app deployment (Vaultwarden + Caddy)
  - Each playbook validates prerequisites and provides clear error messages

- **mTLS Authentication**: 
  - Client certificate verification required for all HTTPS connections
  - Dual-format P12 certificate generation (legacy RC2-40-CBC + modern AES-256-CBC)
  - Support for cross-platform clients (iOS, Android, Windows, macOS, Linux). The android/ios apps have mTLS implemented already. 
  - Certificate-based user identification eliminates password-based attacks

- **CA Versioning**: 
  - Version-controlled certificate authority storage (v1, v2, v3...)
  - Preserves previous CA versions for certificate validation during rotation
  - User prompt for version selection or automatic increment
  - Combined CA bundle deployment supporting multiple certificate generations

- **Docker Integration**: 
  - Vaultwarden container with hardened security settings (signups disabled, 1M password iterations)
    - Admin panel blocked from external access (localhost only)
  - Caddy reverse proxy with automatic HTTPS
  - Docker daemon bound to localhost only (127.0.0.1) preventing external Docker API access
  - Volume mounts for persistent data and certificate access

> /!\ You still need to setup your backup system for vaultwarden.

## Security Considerations

**Important**: This project provides a hardened setup that significantly improves security posture, but no system is 100% secure. Users are responsible for:

- Proper key management and certificate distribution
- Regular security updates and monitoring
- Backup and disaster recovery procedures
- Network-level security controls
- etc.

The default configuration uses a self-signed root CA. For production environments requiring intermediate CAs or integration with existing PKI infrastructure, modify the `01_setup-ca.yml` playbook accordingly.

In this project, I added mTLS as a final safety layer. You should enforce strong passwords as well as 2FA for all users and only invite people you trust (I disabled the invites).

## Prerequisites

1) Fresh Ubuntu 20.04+ server with SSH access
2) Having installed uv on the control machine
3) Having configured the SSH profile of the server on the control machine (with port + username)
4) SSH key pair for hardened server access (see vars.yaml)
5) Domain name with DNS configured (for Let's Encrypt via the reverse proxy Caddy)

## Installing the repo

```bash
# Clone the repository
git clone https://github.com/EmileDqy/BitHardened.git
cd BitHardened

# Create and activate Python virtual environment
uv sync
source .venv/bin/activate

# Install Ansible Bitwarden collection (optional)
./setup.sh

# Configure your deployment
cp vars.yml.example vars.yml
```

## Configuration

1) Edit `vars.yml` with your specific configuration
2) You also need create the `inventory` file. It should look like this:

```
[server]
vault.somedomain.com
```

> Used for ssh

3) Finally, make sure the server is properly configured in your SSH (with default username and default SSH port) like so:

```bash
Host vault.mydomain.mytld
  HostName vault.mydomain.mytld
  User default
  Port 22
```

Later, if you want to re-run the hardening playbook, you'll need to change the username and port values to the new ones in your ssh config:

```bash
Host vault.mydomain.mytld
  HostName vault.mydomain.mytld
  User <new_user specified in vars.yml>
  Port <ssh_port specified in vars.yml>
```

This is because during the first execution of the playbook, the default user is removed and the ssh port is changed.  
Maybe I should automate this one day.

## Usage

### Complete Deployment

You can then run the playbooks:

```bash
ansible-playbook -i inventory playbooks/00_hardening.yml
ansible-playbook -i inventory playbooks/01_setup-ca.yml
ansible-playbook -i inventory playbooks/02_app-setup.yml
```

### Certificate Management

Generate client certificates for new users:

```bash
sudo ./pki/<version>/generate_user_cert.sh <username>
```

The script generates both legacy (for macos) and modern format P12 certificates for maximum compatibility across different platforms and devices.

## Certificate Authority Versioning

The CA setup includes versioning support for certificate rotation:

- CAs are stored in versioned directories (`v1`, `v2`, etc.)
- Previous CA versions are preserved for rollback scenarios
- Client certificates reference specific CA versions
- The system supports gradual migration between CA versions

## Disclaimer

This software is provided for educational and operational purposes. Users are solely responsible for ensuring compliance with applicable laws, regulations, and security requirements. The authors assume no liability for any damages or security breaches resulting from the use of this software.

## TODOs

- Handle SSH better for ansible