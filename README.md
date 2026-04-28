<table>
	<thead>
    	<tr>
      		<th style="text-align:center">English</th>
          <th style="text-align:center"><a href="./README_cn.md">Chinese</a></th>
      		<th style="text-align:center"><a href="./README_ja.md">日本語</a></th>
    	</tr>
  	</thead>
</table>

# ec2-minecraft-terraform

Terraform configuration for building a PaperMC Minecraft server on AWS EC2.

## Overview

- Instance: t4g.small (vCPU: 2, Memory: 2GB, ARM64)
- OS: Ubuntu 24.04 LTS ARM64
- Storage: gp3 8GB
- Connection: AWS Systems Manager Session Manager (no SSH or key pair required)
- Fixed IP: None (public IP changes every time the instance starts)
- Server Software: PaperMC

## Prerequisites

- Terraform 1.6.0 or higher
- AWS CLI
- IAM user access key with the following permissions:
  - Create/delete/start/stop EC2
  - Create/delete IAM roles and instance profiles
  - Create/delete security groups

## Setup

### 1. Install Terraform

```powershell
winget install HashiCorp.Terraform
```

Verify installation:

```powershell
terraform -version
```

### 2. Install AWS CLI

```powershell
winget install Amazon.AWSCLI
```

### 3. Configure AWS Credentials

```powershell
aws configure
```

Enter the following:

```
AWS Access Key ID     : (IAM user access key ID)
AWS Secret Access Key : (secret access key)
Default region name   : ap-northeast-1
Default output format : json
```

## Deploy

### First time only: Initialize

```powershell
cd terraform
terraform init
```

### Review changes

```powershell
terraform plan
```

### Create resources

```powershell
terraform apply
```

Enter `yes` to create the EC2 instance, IAM resources, and security group.

When complete, the following will be output:

```
instance_id         = "i-xxxxxxxxxxxxxxxxx"
public_ip           = "xxx.xxx.xxx.xxx"
ssm_connect_command = "aws ssm start-session --target i-xxx... --region ap-northeast-1"
```

## Connecting

Run the `ssm_connect_command` output value directly:

```powershell
aws ssm start-session --target <instance_id> --region ap-northeast-1
```

After connecting, switch to the Minecraft user:

```bash
sudo su - minecraft
```

## Starting and Stopping EC2

To reduce costs, only start the EC2 instance when you want to play.

**Stop** (billing for the instance and public IP stops while stopped):

```powershell
aws ec2 stop-instances --instance-ids <instance_id> --region ap-northeast-1
```

**Start**:

```powershell
aws ec2 start-instances --instance-ids <instance_id> --region ap-northeast-1
```

Since a fixed IP is not used, the public IP changes every time the instance starts.  
Check the Minecraft client connection address with `terraform output public_ip` or via the AWS console.

## Whitelist Configuration

### 1. How to find a user's UUID

Access the following URL to retrieve the UUID:

```
https://api.mojang.com/users/profiles/minecraft/<username>
```

Example response:

```json
{"id":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","name":"<username>"}
```

The `id` value is the UUID. If it is 32 characters without hyphens, convert it to the 8-4-4-4-12 format.

### 2. Edit config/whitelist.json

Add the UUID and username to `config/whitelist.json`:

```json
[
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<your Minecraft username>"
  },
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<friend's Minecraft username>"
  }
]
```

## Delete All Resources

```powershell
terraform destroy
```

Enter `yes` to delete the EC2 instance, EBS volume, IAM resources, and security group.

## Directory Structure

```
.
├── terraform/
│   ├── main.tf                  # Terraform and provider configuration
│   ├── variables.tf             # Variable definitions (region, instance type)
│   ├── outputs.tf               # Output values (instance ID, IP, SSM connect command)
│   ├── iam.tf                   # IAM role and Session Manager policy
│   ├── security_group.tf        # Security group (port 25565 open)
│   ├── ec2.tf                   # EC2 instance and EBS volume
│   └── user_data.sh.tftpl       # Auto-setup script for EC2 first boot
├── scripts/
│   ├── start.sh                 # Minecraft server start script
│   ├── stop.sh                  # Minecraft server stop and backup script
│   └── backup.sh                # Online backup script
└── services/
    ├── minecraft.service        # systemd service (server start/stop)
    ├── minecraft-backup.service # systemd service (backup execution)
    └── minecraft-backup.timer   # systemd timer (backup every 10 minutes)
```
