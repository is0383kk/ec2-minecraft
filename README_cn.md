<table>
	<thead>
    	<tr>
      		<th style="text-align:center"><a href="./README.md">English</a></th>
          <th style="text-align:center">中文</th>
      		<th style="text-align:center"><a href="./README_ja.md">日本語</a></th>
    	</tr>
  	</thead>
</table>

# ec2-minecraft-terraform

在 AWS EC2 上构建 PaperMC Minecraft 服务器的 Terraform 配置。

## 配置概览

- 实例: t4g.small（vCPU: 2、内存: 2GB、ARM64）
- 操作系统: Ubuntu 24.04 LTS ARM64
- 存储: gp3 8GB
- 连接方式: AWS Systems Manager Session Manager（无需 SSH 或密钥对）
- 固定 IP: 无（每次启动时公共 IP 会变化）
- 服务器软件: PaperMC

## 前提条件

- Terraform 1.6.0 以上
- AWS CLI
- 具有以下权限的 IAM 用户访问密钥
  - EC2 的创建・删除・启动・停止
  - IAM 角色和实例配置文件的创建・删除
  - 安全组的创建・删除

## 安装配置

### 1. 安装 Terraform

```powershell
winget install HashiCorp.Terraform
```

验证安装：

```powershell
terraform -version
```

### 2. 安装 AWS CLI

```powershell
winget install Amazon.AWSCLI
```

### 3. 配置 AWS 凭证

```powershell
aws configure
```

输入以下内容：

```
AWS Access Key ID     : （IAM 用户的访问密钥 ID）
AWS Secret Access Key : （秘密访问密钥）
Default region name   : ap-northeast-1
Default output format : json
```

## 部署

### 仅首次：初始化

```powershell
cd terraform
terraform init
```

### 确认变更内容

```powershell
terraform plan
```

### 创建资源

```powershell
terraform apply
```

输入 `yes` 后将创建 EC2、IAM 和安全组。

完成后将输出以下内容：

```
instance_id         = "i-xxxxxxxxxxxxxxxxx"
public_ip           = "xxx.xxx.xxx.xxx"
ssm_connect_command = "aws ssm start-session --target i-xxx... --region ap-northeast-1"
```

## 连接方法

直接执行 `ssm_connect_command` 的输出值：

```powershell
aws ssm start-session --target <instance_id> --region ap-northeast-1
```

连接后，切换到 Minecraft 用户：

```bash
sudo su - minecraft
```

## EC2 的启动・停止

为了降低成本，请仅在游戏时启动 EC2。

**停止**（停止期间实例和公共 IP 的费用将停止计费）：

```powershell
aws ec2 stop-instances --instance-ids <instance_id> --region ap-northeast-1
```

**启动**：

```powershell
aws ec2 start-instances --instance-ids <instance_id> --region ap-northeast-1
```

由于不使用固定 IP，每次启动时公共 IP 都会变化。  
请通过 `terraform output public_ip` 或 AWS 控制台确认 Minecraft 客户端的连接地址。

## 白名单设置

### 1. 查找用户 UUID 的方法

访问以下 URL 即可获取 UUID：

```
https://api.mojang.com/users/profiles/minecraft/<用户名>
```

响应示例：

```json
{"id":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","name":"<用户名>"}
```

`id` 的值即为 UUID。如果是不含连字符的 32 位字符，请转换为 8-4-4-4-12 的格式。

### 2. 编辑 config/whitelist.json

在 `config/whitelist.json` 中添加 UUID 和用户名：

```json
[
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<自己的 Minecraft 用户名>"
  },
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<朋友的 Minecraft 用户名>"
  }
]
```

## 删除所有资源

```powershell
terraform destroy
```

输入 `yes` 后将删除 EC2、EBS、IAM 和安全组的所有资源。

## 目录结构

```
.
├── terraform/
│   ├── main.tf                  # Terraform・提供商配置
│   ├── variables.tf             # 变量定义（区域・实例类型）
│   ├── outputs.tf               # 输出值（实例 ID・IP・SSM 连接命令）
│   ├── iam.tf                   # IAM 角色・Session Manager 策略
│   ├── security_group.tf        # 安全组（开放端口 25565）
│   ├── ec2.tf                   # EC2 实例・EBS 卷
│   └── user_data.sh.tftpl       # EC2 首次启动时的自动安装脚本
├── scripts/
│   ├── start.sh                 # Minecraft 服务器启动脚本
│   ├── stop.sh                  # Minecraft 服务器停止・备份脚本
│   └── backup.sh                # 在线备份脚本
└── services/
    ├── minecraft.service        # systemd 服务（服务器启动・停止）
    ├── minecraft-backup.service # systemd 服务（执行备份）
    └── minecraft-backup.timer   # systemd 定时器（每 10 分钟备份一次）
```
