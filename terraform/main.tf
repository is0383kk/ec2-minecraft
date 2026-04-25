# Terraform 本体と AWS プロバイダのバージョン制約を定義する
terraform {
  # Terraform CLI のバージョンを 1.6.0 以上に制限する
  required_version = ">= 1.6.0"

  required_providers {
    # AWS リソースを管理するための公式プロバイダ（5.x 系を使用）
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS プロバイダの設定（デプロイ先リージョンは variables.tf の aws_region で指定）
provider "aws" {
  region = var.aws_region
}
