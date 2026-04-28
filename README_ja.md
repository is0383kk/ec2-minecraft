<table>
	<thead>
    	<tr>
      		<th style="text-align:center"><a href="./README.md">English</a></th>
          <th style="text-align:center"><a href="./README_cn.md">Chinese</a></th>
      		<th style="text-align:center">日本語</th>
    	</tr>
  	</thead>
</table>

# ec2-minecraft-terraform

AWS EC2 上に PaperMC Minecraft サーバーを構築する Terraform 構成です。

## 構成の概要

- インスタンス: t4g.small（vCPU: 2、メモリ: 2GB、ARM64）
- OS: Ubuntu 24.04 LTS ARM64
- ストレージ: gp3 8GB
- 接続方法: AWS Systems Manager Session Manager（SSH・キーペア不要）
- 固定IP: なし（起動のたびにパブリックIPが変わります）
- サーバーソフト: PaperMC

## 前提条件

- Terraform 1.6.0 以上
- AWS CLI
- 以下の権限を持つ IAM ユーザーのアクセスキー
  - EC2 の作成・削除・起動・停止
  - IAM ロール・インスタンスプロファイルの作成・削除
  - セキュリティグループの作成・削除

## セットアップ

### 1. Terraform のインストール

```powershell
winget install HashiCorp.Terraform
```

インストール確認：

```powershell
terraform -version
```

### 2. AWS CLI のインストール

```powershell
winget install Amazon.AWSCLI
```

### 3. AWS 認証情報の設定

```powershell
aws configure
```

以下を入力します：

```
AWS Access Key ID     : （IAMユーザーのアクセスキーID）
AWS Secret Access Key : （シークレットアクセスキー）
Default region name   : ap-northeast-1
Default output format : json
```

## デプロイ

### 初回のみ：初期化

```powershell
cd terraform
terraform init
```

### 変更内容の確認

```powershell
terraform plan
```

### リソースの作成

```powershell
terraform apply
```

`yes` を入力すると EC2・IAM・セキュリティグループが作成されます。

完了すると以下が出力されます：

```
instance_id         = "i-xxxxxxxxxxxxxxxxx"
public_ip           = "xxx.xxx.xxx.xxx"
ssm_connect_command = "aws ssm start-session --target i-xxx... --region ap-northeast-1"
```

## 接続方法

`ssm_connect_command` の出力値をそのまま実行します：

```powershell
aws ssm start-session --target <instance_id> --region ap-northeast-1
```

接続後、Minecraft ユーザーに切り替えます：

```bash
sudo su - minecraft
```

## EC2 の起動・停止

コスト削減のため、遊ぶときだけ EC2 を起動してください。

**停止**（停止中はインスタンスとパブリックIPの課金が止まります）：

```powershell
aws ec2 stop-instances --instance-ids <instance_id> --region ap-northeast-1
```

**起動**：

```powershell
aws ec2 start-instances --instance-ids <instance_id> --region ap-northeast-1
```

固定IPを使わないため、起動のたびにパブリックIPが変わります。  
Minecraft クライアントの接続先は `terraform output public_ip` または AWS コンソールで確認してください。

## ホワイトリストの設定

### 1. ユーザー UUID の調べ方

以下の URL にアクセスすると UUID を取得できます：

```
https://api.mojang.com/users/profiles/minecraft/<ユーザー名>
```

レスポンス例：

```json
{"id":"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","name":"<ユーザー名>"}
```

`id` の値（ハイフンなし32文字の場合は、8-4-4-4-12 の形式に変換してください）が UUID です。

### 2. config/whitelist.json を編集する

`config/whitelist.json` に UUID とユーザー名を追記します：

```json
[
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<自分のMinecraftユーザー名>"
  },
  {
    "uuid": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "name": "<友人のMinecraftユーザー名>"
  }
]
```

## 全リソースの削除

```powershell
terraform destroy
```

`yes` を入力すると EC2・EBS・IAM・セキュリティグループがすべて削除されます。

## ディレクトリ構成

```
.
├── terraform/
│   ├── main.tf                  # Terraform・プロバイダ設定
│   ├── variables.tf             # 変数定義（リージョン・インスタンスタイプ）
│   ├── outputs.tf               # 出力値（インスタンスID・IP・SSM接続コマンド）
│   ├── iam.tf                   # IAMロール・Session Manager ポリシー
│   ├── security_group.tf        # セキュリティグループ（ポート 25565 開放）
│   ├── ec2.tf                   # EC2インスタンス・EBSボリューム
│   └── user_data.sh.tftpl       # EC2 初回起動時の自動セットアップスクリプト
├── scripts/
│   ├── start.sh                 # Minecraft サーバー起動スクリプト
│   ├── stop.sh                  # Minecraft サーバー停止・バックアップスクリプト
│   └── backup.sh                # オンラインバックアップスクリプト
└── services/
    ├── minecraft.service        # systemd サービス（サーバー起動・停止）
    ├── minecraft-backup.service # systemd サービス（バックアップ実行）
    └── minecraft-backup.timer   # systemd タイマー（10分ごとにバックアップ）
```
