# SSH Key-Based Authentication: A Beginner's Guide

This guide demonstrates how to set up SSH key-based authentication between containers using public/private key pairs, based on a practical Docker lab environment.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Generate SSH Key Pair (Client Side)](#step-1-generate-ssh-key-pair-client-side)
4. [Step 2: Configure Server to Accept Key](#step-2-configure-server-to-accept-key)
5. [Step 3: Managing Keys with ssh-agent](#step-3-managing-keys-with-ssh-agent)
6. [Step 4: Connect to Server](#step-4-connect-to-server)
7. [Key Management Operations](#key-management-operations)
8. [Troubleshooting](#troubleshooting)

## Overview

SSH key-based authentication provides a more secure alternative to password authentication. It uses a pair of cryptographic keys:
- **Private Key**: Kept secret on the client machine
- **Public Key**: Shared with servers you want to access

## Prerequisites

- Docker environment with SSH client and server containers
- Basic familiarity with terminal/command line
- Understanding of file permissions in Linux

## Step 1: Generate SSH Key Pair (Client Side)

### 1.1 Access the SSH Client Container
```bash
docker exec -it ssh-client bash
```

### 1.2 Generate ED25519 Key Pair
```bash
ssh-keygen -t ed25519 -C "dev@client:server-1"
```

**Breakdown of the command:**
- `-t ed25519`: Specifies the key type (ED25519 is modern and secure)
- `-C "dev@client:server-1"`: Adds a comment to identify the key

**Interactive prompts:**
1. **File location**: Press Enter to use default (`/root/.ssh/id_ed25519`)
2. **Passphrase**: Press Enter twice for no passphrase (or enter a secure passphrase)

**Expected output:**
```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/root/.ssh/id_ed25519): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_ed25519
Your public key has been saved in /root/.ssh/id_ed25519.pub
```

### 1.3 View Your Public Key
```bash
cat ~/.ssh/id_ed25519.pub
```

**Sample output:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+dw82TYYS3AM6kkyUNDsBfdACjIJPHznCYXaksFj3B dev@client:server-1
```

**Copy this entire line** - you'll need it for server configuration.

## Step 2: Configure Server to Accept Key

### 2.1 Access the SSH Server Container
```bash
docker exec -it ssh-server-1 bash
```

### 2.2 Create SSH Directory for User
```bash
mkdir -p /home/dev/.ssh
```

### 2.3 Set Proper Ownership
```bash
chown dev:dev /home/dev/.ssh
```

### 2.4 Set Secure Permissions
```bash
chmod 700 /home/dev/.ssh
```

**Why these permissions matter:**
- `700`: Only the owner can read, write, and execute
- SSH refuses to work if permissions are too open (security feature)

### 2.5 Add Public Key to Authorized Keys
```bash
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA+dw82TYYS3AM6kkyUNDsBfdACjIJPHznCYXaksFj3B dev@client:server-1" >> /home/dev/.ssh/authorized_keys
```

**Important:** Replace the key string with your actual public key from Step 1.3.

### 2.6 Set Permissions on authorized_keys
```bash
chmod 600 /home/dev/.ssh/authorized_keys
chown dev:dev /home/dev/.ssh/authorized_keys
```

## Step 3: Managing Keys with ssh-agent

### 3.1 Start SSH Agent
```bash
eval "$(ssh-agent -s)"
```

**Expected output:**
```
Agent pid 24
```

### 3.2 Verify Agent is Running
```bash
ssh-add -l
```

**If no keys loaded:**
```
The agent has no identities.
```

### 3.3 Add Private Key to Agent
```bash
ssh-add ~/.ssh/id_ed25519
```

**Expected output:**
```
Identity added: /root/.ssh/id_ed25519 (dev@client:server-1)
```

### 3.4 List Loaded Keys
```bash
ssh-add -l
```

**Expected output:**
```
256 SHA256:QYxdusIHaTHCsMrwLI8G6z+0zlkthbljIgqhtoriJ5k dev@client:server-1 (ED25519)
```

## Step 4: Connect to Server

### 4.1 Test Initial Connection (Will Fail Without Setup)
```bash
ssh dev@ssh-server-1
```

**Before key setup:**
```
dev@ssh-server-1: Permission denied (publickey).
```

### 4.2 Connect After Proper Setup
```bash
ssh dev@ssh-server-1
```

**After key setup:**
```
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 6.10.14-linuxkit aarch64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro
```

### 4.3 Exit the SSH Session
```bash
exit
```

## Key Management Operations

### Loading Keys to ssh-agent
```bash
# Add specific key
ssh-add ~/.ssh/id_ed25519

# Add all keys in ~/.ssh/
ssh-add

# List all loaded keys
ssh-add -l
```

### Offloading Keys from ssh-agent
```bash
# Remove specific key
ssh-add -d ~/.ssh/id_ed25519

# Remove all keys
ssh-add -D

# Verify removal
ssh-add -l
```

**Expected output after removal:**
```
The agent has no identities.
```

### Testing Connection Without ssh-agent
Even after removing keys from ssh-agent, you can still connect if:
1. The public key is properly configured on the server
2. The private key file exists and has correct permissions
3. SSH client automatically finds the key file

## Troubleshooting

### Common Issues and Solutions

#### 1. Permission Denied (publickey)
**Causes:**
- Public key not added to server's `authorized_keys`
- Wrong permissions on SSH directories/files
- Key not loaded in ssh-agent

**Solutions:**
- Verify public key is in `/home/dev/.ssh/authorized_keys`
- Check permissions: `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys`
- Add key to agent: `ssh-add ~/.ssh/id_ed25519`

#### 2. Could not open a connection to your authentication agent
**Cause:** ssh-agent not running

**Solution:**
```bash
eval "$(ssh-agent -s)"
```

#### 3. Host Key Verification
**First connection shows:**
```
The authenticity of host 'ssh-server-1 (172.21.0.3)' can't be established.
ED25519 key fingerprint is SHA256:5vQ2nFancWQLHviqrDgqmBN6lJbcc63bhg2b/noNtvY.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

**Solution:** Type `yes` to accept and permanently add the host key.

### Security Best Practices

1. **Use Strong Key Types**: Prefer ED25519 over older RSA keys
2. **Use Passphrases**: Protect private keys with strong passphrases
3. **Proper Permissions**: Always set correct file permissions
4. **Regular Key Rotation**: Periodically generate new key pairs
5. **Limit Key Access**: Only add public keys to necessary servers

### Key File Locations

#### Client Side (Default locations)
- Private key: `~/.ssh/id_ed25519`
- Public key: `~/.ssh/id_ed25519.pub`
- Known hosts: `~/.ssh/known_hosts`

#### Server Side
- Authorized keys: `/home/username/.ssh/authorized_keys`
- SSH server config: `/etc/ssh/sshd_config`

## Summary

This guide covered the complete process of setting up SSH key-based authentication:

1. ✅ Generated ED25519 key pair on client
2. ✅ Configured server to accept the public key
3. ✅ Managed keys using ssh-agent
4. ✅ Successfully established secure connections
5. ✅ Learned key loading/offloading operations

Key-based authentication is more secure than passwords and enables automated, passwordless connections between systems. 
